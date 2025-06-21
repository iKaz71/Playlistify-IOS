import SwiftUI
import Kingfisher
import SwiftUIIntrospect
import FirebaseDatabase
import GoogleSignIn

// Enum para controlar la acción en la alerta
enum SalaAction: Identifiable, Equatable {
    case eliminar(pushKey: String, cancion: Cancion)
    case playNext(pushKey: String, cancion: Cancion)

    var id: String {
        switch self {
        case .eliminar(let pushKey, _):
            return "eliminar_\(pushKey)"
        case .playNext(let pushKey, _):
            return "playNext_\(pushKey)"
        }
    }
}
struct SalaScreen: View {
    let sessionId: String
    let onSalirSala: () -> Void
    @ObservedObject var googleSignInManager: GoogleSignInManager

    // --- Estados ---
    
    @State private var mostrarSalirSalaSheet = false
    @State private var mostrarCerrarSesionSheet = false

    @State private var cancionesDict: [String: Cancion] = [:]
    @State private var ordenCanciones: [String] = []
    @State private var cancionActual: Cancion? = nil
    @State private var isLoading = true
    @State private var mostrarBuscador = false
    @State private var salaAction: SalaAction? = nil

    @State private var mostrarScannerQR = false
    @State private var showMenuSheet = false
    @State private var showNombreSheet = false
    @State private var nombreUsuario: String = {
        if let personalizado = UserDefaults.standard.string(forKey: "nombreUsuario"),
           UserDefaults.standard.bool(forKey: "isNombrePersonalizado") {
            return personalizado
        } else if let google = UserDefaults.standard.string(forKey: "nombreGoogle") {
            return google
        } else {
            let nuevo = generarNombreHawaianoUnico()
            UserDefaults.standard.set(nuevo, forKey: "nombreUsuario")
            UserDefaults.standard.set(false, forKey: "isNombrePersonalizado")
            return nuevo
        }
    }()

    @State private var emailUsuario: String = UserDefaults.standard.string(forKey: "emailUsuario") ?? ""
    @State private var rolUsuario: String = UserDefaults.standard.string(forKey: "rolUsuario") ?? "Invitado"

    
    @State private var showSalirSalaAlert = false
    // Buscador
    @State private var query = ""
    @State private var resultados: [YouTubeVideoItem] = []
    @State private var isAdding = false
    @FocusState private var isFocused: Bool
    @State private var codigoSesion: String = ""
    let rojoVivo = Color(red: 1, green: 0.2, blue: 0.3)
    let fondoOscuro = Color(red: 28/255, green: 28/255, blue: 30/255)
    var body: some View {
        ZStack {
            fondoOscuro.ignoresSafeArea()
            VStack(spacing: 16) {
                topBar
                userInfo
                mainContent
                Spacer(minLength: 8)
            }
        }
        .sheet(isPresented: $mostrarBuscador) {
            BusquedaYT(
                query: $query,
                resultados: $resultados,
                isAdding: $isAdding,
                mostrarBuscador: $mostrarBuscador,
                isFocused: _isFocused,
                rojoVivo: rojoVivo,
                fondoOscuro: fondoOscuro,
                sessionId: sessionId,
                agregarCancion: agregarCancion, // asegúrate de que tu función siga este signature
                buscarCanciones: buscarCanciones // igual, recibe (String, ([YouTubeVideoItem]) -> Void)
            )
        }
        .sheet(isPresented: $showMenuSheet) {
            menuSheet
        }
        .sheet(isPresented: $mostrarScannerQR) {
            QRScanSheet { qrText in
                googleSignInManager.procesarCodigoAdmin(qr: qrText, nombreUsuario: nombreUsuario)
                rolUsuario = "Admin"
                UserDefaults.standard.set("Admin", forKey: "rolUsuario")
                mostrarScannerQR = false
            }
        }

        .sheet(isPresented: $showNombreSheet) {
            CambiarNombreDialog(
                isPresented: $showNombreSheet,
                nombreUsuario: $nombreUsuario,
                sessionId: sessionId // pásalo aquí
            )
        }

        .sheet(isPresented: $mostrarSalirSalaSheet) {
            ConfirmarSalirSalaSheet(
                onConfirmar: {
                    mostrarSalirSalaSheet = false
                    onSalirSala()
                },
                onCancelar: {
                    mostrarSalirSalaSheet = false
                }
            )
            .presentationDetents([.fraction(0.22)])
        }
        .sheet(isPresented: $mostrarCerrarSesionSheet) {
            ConfirmarCerrarSesionSheet(
                onConfirmar: {
                    mostrarCerrarSesionSheet = false
                    googleSignInManager.signOut()
                    emailUsuario = ""
                    UserDefaults.standard.set("", forKey: "emailUsuario")
                    // No cambies rolUsuario aquí.
                },
                onCancelar: {
                    mostrarCerrarSesionSheet = false
                }
            )
            .presentationDetents([.fraction(0.22)])
        }

        .alert(item: $salaAction) { action in
            switch action {
            case .eliminar(let pushKey, let cancion):
                return Alert(
                    title: Text("¿Eliminar canción?"),
                    message: Text("¿Estás seguro de eliminar \"\(cancion.titulo)\" de la cola?"),
                    primaryButton: .destructive(Text("Eliminar")) {
                        print("🔴 Eliminando pushKey: \(pushKey), canción: \(cancion.titulo)")
                        PlaylistifyAPI.shared.eliminarCancion(
                            sessionId: sessionId,
                            pushKey: pushKey,
                            userId: "iOS"
                        ) { error in
                            if let error = error {
                                print("❌ Error al eliminar: \(error.localizedDescription)")
                            } else {
                                print("✅ Eliminada correctamente")
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            case .playNext(let pushKey, let cancion):
                return Alert(
                    title: Text("¿Reproducir a continuación?"),
                    message: Text("¿Seguro que quieres que \"\(cancion.titulo)\" sea la siguiente canción en reproducirse?"),
                    primaryButton: .default(Text("Sí, siguiente")) {
                        PlaylistifyAPI.shared.playNext(
                            sessionId: sessionId,
                            pushKey: pushKey
                        ) { error in
                            if let error = error {
                                print("❌ Error al mover a Play Next: \(error.localizedDescription)")
                            } else {
                                print("✅ Canción movida a Play Next")
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .onChange(of: googleSignInManager.user) { user in
            if let googleUser = user as? GIDGoogleUser {
                let isPersonalizado = UserDefaults.standard.bool(forKey: "isNombrePersonalizado")
                UserDefaults.standard.set(googleUser.profile?.name, forKey: "nombreGoogle")
                if !isPersonalizado {
                    nombreUsuario = googleUser.profile?.name ?? nombreUsuario
                    UserDefaults.standard.set(nombreUsuario, forKey: "nombreUsuario")
                }
                emailUsuario = googleUser.profile?.email ?? ""
                UserDefaults.standard.set(emailUsuario, forKey: "emailUsuario") 
            } else {
                emailUsuario = ""
                UserDefaults.standard.set("", forKey: "emailUsuario")
            }
        }



        .onAppear {
            escucharColaYOrden()
            FirebaseQueueManager.shared.escucharPlayback(sessionId: sessionId) { actual in
                DispatchQueue.main.async { self.cancionActual = actual }
            }
            obtenerCodigoDeSesion(sessionId: sessionId) { codigo in
                DispatchQueue.main.async { self.codigoSesion = codigo ?? "----" }
            }
        }
    }

    // --------- Alertas ---------
    var salirSalaAlert: Alert {
        Alert(
            title: Text("Salir de sala"),
            message: Text("¿Seguro que quieres salir de la sala actual?"),
            primaryButton: .destructive(Text("Salir")) {
                onSalirSala()
            },
            secondaryButton: .cancel()
        )
    }

    // --------- Vistas Auxiliares ---------
    var topBar: some View {
        HStack {
            Text("Playlistify")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            HStack(spacing: 20) {
                //Image(systemName: "bell")
                Image(systemName: "magnifyingglass")
                    .onTapGesture { mostrarBuscador = true }
                Image(systemName: "line.3.horizontal")
                    .onTapGesture { showMenuSheet = true }
            }
            .foregroundColor(.white)
            .font(.system(size: 20))
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    var userInfo: some View {
        HStack {
            Text("Código: \(codigoSesion)")
                .foregroundColor(.white)
            Spacer()
            Text("Usuario: \(nombreUsuario)")
                .foregroundColor(.white)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    var mainContent: some View {
        if isLoading {
            Spacer()
            ProgressView().tint(.white)
            Spacer()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Reproduciendo ahora:")
                    .font(.headline)
                    .foregroundColor(.white)
                if let actual = cancionActual {
                    CardCancion(cancion: actual, incluirBoton: true)
                } else {
                    Text("Sin canciones en cola")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal)
            queueSection
        }
    }

    // --- Cola en línea, sin ColaListView ---
    var queueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("En cola:")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            let enCola: [(String, Cancion)] = obtenerEnCola(
                ordenCanciones: ordenCanciones,
                cancionesDict: cancionesDict,
                cancionActual: cancionActual
            )
            List {
                ForEach(enCola.indices, id: \.self) { index in
                    let (pushKey, c) = enCola[index]
                    CardCancionEnCola(cancion: c)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets())
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                salaAction = .eliminar(pushKey: pushKey, cancion: c)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if index > 0 {
                                Button {
                                    salaAction = .playNext(pushKey: pushKey, cancion: c)
                                } label: {
                                    Label("Siguiente", systemImage: "chevron.up.2")
                                }
                                .tint(Color.yellow.opacity(0.85))
                            }
                        }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .frame(maxHeight: 420)
            .background(fondoOscuro)
            .cornerRadius(28)
        }
    }
    var menuSheet: some View {
        MenuBottomSheet(
            nombreUsuario: nombreUsuario,
            rolUsuario: rolUsuario,
            emailUsuario: emailUsuario,
            onCambiarNombre: {
                showMenuSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                    showNombreSheet = true
                }
            },
            onGoogleLogin: {
                if let rootViewController = UIApplication.shared.connectedScenes
                    .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                    .first?.rootViewController {
                    googleSignInManager.signIn()
                }
            },
            onEscanearQR: {
                showMenuSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                    mostrarScannerQR = true
                }
            },
            onSolicitarCerrarSesionGoogle: {
                showMenuSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                    mostrarCerrarSesionSheet = true
                }
            },
            onSolicitarSalirSala: {
                showMenuSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                    mostrarSalirSalaSheet = true
                }
            }
        )

        .presentationDetents([.fraction(0.33)])
        .presentationDragIndicator(.hidden)
    }


    // --------- Funciones privadas ---------
    private func escucharColaYOrden() {
        let refCola = Database.database().reference().child("queues").child(sessionId)
        let refOrden = Database.database().reference().child("queuesOrder").child(sessionId)
        refCola.observe(.value, with: { snapshot in
            let value = snapshot.value as? [String: Any] ?? [:]
            var nuevasCancionesDict: [String: Cancion] = [:]
            for (pushKey, data) in value {
                if let dict = data as? [String: Any],
                   let id = dict["id"] as? String,
                   let titulo = dict["titulo"] as? String,
                   let usuario = dict["usuario"] as? String,
                   let thumbnailUrl = dict["thumbnailUrl"] as? String,
                   let duration = dict["duration"] as? String {
                    let cancion = Cancion(
                        videoId: id,
                        pushKey: pushKey,
                        titulo: titulo,
                        thumbnailUrl: thumbnailUrl,
                        usuario: usuario,
                        duration: duration
                    )
                    nuevasCancionesDict[pushKey] = cancion
                }
            }
            DispatchQueue.main.async {
                self.cancionesDict = nuevasCancionesDict
            }
        })
        refOrden.observe(.value, with: { snapshot in
            let orden = snapshot.value as? [String] ?? []
            DispatchQueue.main.async {
                self.ordenCanciones = orden
                self.isLoading = false
            }
        })
    }
}

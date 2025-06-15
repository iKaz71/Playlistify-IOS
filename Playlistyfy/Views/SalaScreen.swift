import SwiftUI
import Kingfisher
import SwiftUIIntrospect
import FirebaseDatabase

struct SalaScreen: View {
    let sessionId: String

    @State private var cancionesDict: [String: Cancion] = [:]
    @State private var ordenCanciones: [String] = []
    @State private var cancionActual: Cancion? = nil
    @State private var cancionAEliminar: Cancion? = nil
    @State private var pushKeyAEliminar: String? = nil
    @State private var isLoading = true
    @State private var mostrarBuscador = false
    @State private var cancionAPlayNext: Cancion? = nil
    @State private var pushKeyAPlayNext: String? = nil

    @State private var showMenuSheet = false
    @State private var showNombreSheet = false
    @State private var nombreUsuario: String = UserDefaults.standard.string(forKey: "nombreUsuario") ?? "Invitado"
    @State private var emailUsuario: String = ""
    @State private var rolUsuario: String = "Invitado"
    @State private var showQRScanner = false
    @State private var showCerrarSesionAlert = false
    @State private var showSalirSalaAlert = false

    @State private var query = ""
    @State private var resultados: [YouTubeVideoItem] = []
    @State private var isAdding = false
    @FocusState private var isFocused: Bool

    @State private var codigoSesion: String = ""

    let rojoVivo = Color(red: 1, green: 0.2, blue: 0.3)
    let fondoOscuro = Color(red: 28/255, green: 28/255, blue: 30/255)

    // -------------- SUBVIEWS / BLOQUES ------------

    // 1. Barra superior
    var topBar: some View {
        HStack {
            Text("Playlistify")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            HStack(spacing: 20) {
                Image(systemName: "bell")
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

    // 2. Info usuario/código
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

    // 3. Loading o contenido principal
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

            ColaView // la lista de cola
        }
    }

    // 4. Cola (lista)
    var ColaView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("En cola:")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            let enCola: [(String, Cancion)] = obtenerEnCola()
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
                                pushKeyAEliminar = pushKey
                                cancionAEliminar = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    cancionAEliminar = c
                                }
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if index > 0 {
                                Button {
                                    pushKeyAPlayNext = pushKey
                                    cancionAPlayNext = nil
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        cancionAPlayNext = c
                                    }
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
            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 80 : 0)
            .animation(.spring(), value: cancionesDict)
            .alert(item: $cancionAEliminar) { cancion in
                Alert(
                    title: Text("¿Eliminar canción?"),
                    message: Text("¿Estás seguro de eliminar \"\(cancion.titulo)\" de la cola?"),
                    primaryButton: .destructive(Text("Eliminar")) {
                        if let pushKey = pushKeyAEliminar {
                            PlaylistifyAPI.shared.eliminarCancion(
                                sessionId: sessionId,
                                pushKey: pushKey,
                                userId: "iOS"
                            ) { _ in }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(item: $cancionAPlayNext) { cancion in
                Alert(
                    title: Text("¿Reproducir a continuación?"),
                    message: Text("¿Seguro que quieres que \"\(cancion.titulo)\" sea la siguiente canción en reproducirse?"),
                    primaryButton: .default(Text("Sí, siguiente")) {
                        if let pushKey = pushKeyAPlayNext {
                            PlaylistifyAPI.shared.playNext(
                                sessionId: sessionId,
                                pushKey: pushKey
                            ) { _ in }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // 5. Overlay flotante (Cambiar Nombre)
    var cambiarNombreOverlay: some View {
        Group {
            if showNombreSheet {
                CambiarNombreDialog(
                    isPresented: $showNombreSheet,
                    nombreUsuario: $nombreUsuario
                )
            }
        }
    }

    // 6. Menú hamburguesa como variable
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
            onEscanearQR: { showQRScanner = true },
            onCerrarSesion: { showCerrarSesionAlert = true },
            onSalirSala: { showSalirSalaAlert = true }
        )
        .presentationDetents([.fraction(0.33)])
        .presentationDragIndicator(.hidden)
    }

    // ---------------- BODY PRINCIPAL ------------------

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
        .sheet(isPresented: $mostrarBuscador) { buscadorSheet }
        .sheet(isPresented: $showMenuSheet) { menuSheet }
        .overlay(cambiarNombreOverlay)
        .sheet(isPresented: $showQRScanner) { qrSheet }
        .alert(isPresented: $showCerrarSesionAlert) { cerrarSesionAlert }
        .alert(isPresented: $showSalirSalaAlert) { salirSalaAlert }
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

    // ---------------- OTROS SHEETS Y ALERTS --------------

    var buscadorSheet: some View {
        ZStack {
            fondoOscuro.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Buscar en YouTube")
                        .foregroundColor(.white)
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                        .padding(.horizontal)
                    HStack {
                        TextField("", text: $query)
                            .padding(.leading, 12)
                            .padding(.vertical, 10)
                            .foregroundColor(.white)
                            .focused($isFocused)
                            .onSubmit {
                                ocultarTeclado()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    buscarCanciones()
                                }
                            }
                        Button(action: {
                            ocultarTeclado()
                            buscarCanciones()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(rojoVivo)
                                .padding(.trailing, 12)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(rojoVivo, lineWidth: 1.5)
                    )
                    .padding(.horizontal)
                    if resultados.isEmpty {
                        Text("Realiza la búsqueda para ver resultados")
                            .foregroundColor(.white.opacity(0.5))
                            .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(resultados) { cancion in
                                HStack(spacing: 12) {
                                    KFImage(URL(string: cancion.thumbnailUrl))
                                        .resizable()
                                        .frame(width: 80, height: 50)
                                        .cornerRadius(8)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(cancion.titulo.htmlDecoded)
                                            .foregroundColor(.white)
                                            .fontWeight(.semibold)
                                            .lineLimit(2)
                                        Text("Duración: \(formatDuration(cancion.duration))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button(action: {
                                        agregarCancion(cancion)
                                    }) {
                                        Image(systemName: "plus")
                                            .foregroundColor(rojoVivo)
                                            .font(.title2)
                                    }
                                    .disabled(isAdding)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                    Spacer(minLength: 12)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .presentationDetents([.medium, .fraction(0.9)])
        .onDisappear {
            query = ""
            resultados.removeAll()
        }
    }

    var qrSheet: some View {
        Text("Escáner QR (por implementar)")
            .foregroundColor(.white)
            .font(.title2)
            .padding()
    }

    var cerrarSesionAlert: Alert {
        Alert(
            title: Text("Cerrar sesión"),
            message: Text("¿Seguro que quieres cerrar sesión de Google?"),
            primaryButton: .destructive(Text("Cerrar sesión")) {
                nombreUsuario = "Invitado"
                emailUsuario = ""
                rolUsuario = "Invitado"
                UserDefaults.standard.set(nombreUsuario, forKey: "nombreUsuario")
            },
            secondaryButton: .cancel()
        )
    }

    var salirSalaAlert: Alert {
        Alert(
            title: Text("Salir de sala"),
            message: Text("¿Seguro que quieres salir de la sala actual?"),
            primaryButton: .destructive(Text("Salir")) {
                // Implementa navegación o reseteo de sesión si quieres
            },
            secondaryButton: .cancel()
        )
    }

    // ---------------- FUNCIONES PRIVADAS -------------------

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

    private func obtenerEnCola() -> [(String, Cancion)] {
        ordenCanciones.compactMap { pushKey in
            guard let c = cancionesDict[pushKey] else { return nil }
            if cancionActual == nil || c.videoId != cancionActual?.videoId {
                return (pushKey, c)
            } else {
                return nil
            }
        }
    }

    private func ocultarTeclado() {
        isFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func buscarCanciones() {
        let consulta = query.trimmingCharacters(in: .whitespaces)
        guard !consulta.isEmpty else { return }
        YouTubeApi.shared.buscarVideos(query: consulta) { lista in
            DispatchQueue.main.async { self.resultados = lista }
        }
    }

    private func agregarCancion(_ cancion: YouTubeVideoItem) {
        isAdding = true
        let nueva = Cancion(
            videoId: cancion.id,
            pushKey: nil,
            titulo: cancion.titulo.htmlDecoded,
            thumbnailUrl: cancion.thumbnailUrl,
            usuario: "iOS",
            duration: cancion.duration
        )
        PlaylistifyAPI.shared.agregarCancion(sessionId: sessionId, cancion: nueva)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            resultados.removeAll()
            isAdding = false
            mostrarBuscador = false
        }
    }

    private func obtenerCodigoDeSesion(sessionId: String, completion: @escaping (String?) -> Void) {
        let ref = Database.database().reference()
        ref.child("sessions").child(sessionId).child("code").observeSingleEvent(of: .value) { snapshot in
            let codigo = snapshot.value as? String
            completion(codigo)
        }
    }
}


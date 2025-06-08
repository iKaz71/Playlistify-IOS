//
//  SalaScreen.swift
//  Playlistyfy
//

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

    // Búsqueda
    @State private var query = ""
    @State private var resultados: [YouTubeVideoItem] = []
    @State private var isAdding = false
    @FocusState private var isFocused: Bool

    // Código de la sesión
    @State private var codigoSesion: String = ""

    let rojoVivo = Color(red: 1, green: 0.2, blue: 0.3)
    let fondoOscuro = Color(red: 28/255, green: 28/255, blue: 30/255)

    var body: some View {
        ZStack {
            fondoOscuro.ignoresSafeArea()

            VStack(spacing: 16) {
                // Barra superior
                HStack {
                    Text("Playlistify")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    HStack(spacing: 20) {
                        Image(systemName: "bell")
                        Image(systemName: "magnifyingglass")
                            .onTapGesture {
                                mostrarBuscador = true
                            }
                        Image(systemName: "person.circle")
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 10)

                HStack {
                    Text("Código: \(codigoSesion)")
                        .foregroundColor(.white)
                    Spacer()
                    Text("Rol: Anfitrión")
                        .foregroundColor(.white)
                }
                .padding(.horizontal)

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

                    // Sección "En cola"
                    VStack(alignment: .leading, spacing: 12) {
                        Text("En cola:")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        // 💡 Se muestran las canciones en el orden del array de pushKeys
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
                                            cancionAEliminar = c
                                            pushKeyAEliminar = pushKey
                                        } label: {
                                            Label("Eliminar", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        if index > 0 {
                                            Button {
                                                cancionAPlayNext = c
                                                pushKeyAPlayNext = pushKey
                                            } label: {
                                                Label("Siguiente", systemImage: "arrow.down.to.line")
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
                                        FirebaseQueueManager.shared.eliminarCancion(sessionId: sessionId, pushKey: pushKey) { error in
                                            if let error = error {
                                                print("❌ Error al eliminar en Firebase: \(error.localizedDescription)")
                                            } else {
                                                print("✅ Canción eliminada de Firebase")
                                            }
                                        }
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
                                        //PlaylistifyAPI.shared.playNext(sessionId: sessionId, pushKey: pushKey)
                                    }
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                }
                Spacer(minLength: 8)
            }
        }
        .sheet(isPresented: $mostrarBuscador) {
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
        .onAppear {
            escucharColaYOrden()
            FirebaseQueueManager.shared.escucharPlayback(sessionId: sessionId) { actual in
                DispatchQueue.main.async {
                    self.cancionActual = actual
                }
            }
            obtenerCodigoDeSesion(sessionId: sessionId) { codigo in
                DispatchQueue.main.async {
                    self.codigoSesion = codigo ?? "----"
                }
            }
        }
    }

    // -- FUNCIONES PRIVADAS --

    // Leer objeto y array de orden, y sincronizar la lista en la UI
    private func escucharColaYOrden() {
        let refCola = Database.database().reference().child("queues").child(sessionId)
        let refOrden = Database.database().reference().child("queuesOrder").child(sessionId)

        // Escuchar el objeto de canciones
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

        // Escuchar el array de orden
        refOrden.observe(.value, with: { snapshot in
            let orden = snapshot.value as? [String] ?? []
            DispatchQueue.main.async {
                self.ordenCanciones = orden
                self.isLoading = false
            }
        })
    }

    // Devuelve las canciones en cola en el orden correcto y con el pushKey
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
            DispatchQueue.main.async {
                self.resultados = lista
            }
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


import SwiftUI
import Kingfisher
import SwiftUIIntrospect
import FirebaseDatabase

struct SalaScreen: View {
    let sessionId: String
    @State private var canciones: [Cancion] = []
    @State private var isLoading = true
    @State private var mostrarBuscador = false

    // Busqueda
    @State private var query = ""
    @State private var resultados: [YouTubeVideoItem] = []
    @State private var isAdding = false
    @FocusState private var isFocused: Bool

    // Código real de la sesión
    @State private var codigoSesion: String = ""

    let rojoVivo = Color(red: 1, green: 0.2, blue: 0.3)

    var body: some View {
        ZStack {
            Color(red: 28/255, green: 28/255, blue: 30/255)
                .ignoresSafeArea()

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

                        if let actual = canciones.first {
                            CardCancion(cancion: actual, incluirBoton: true)
                        } else {
                            Text("Sin canciones en cola")
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Text("En cola:")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)

                    Group {
                        if canciones.count > 4 {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(Array(canciones.dropFirst())) { c in
                                        CardCancion(cancion: c)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 4)
                            }
                            .introspect(.scrollView, on: .iOS(.v13, .v14, .v15, .v16, .v17)) { scrollView in
                                scrollView.bounces = false
                                scrollView.alwaysBounceVertical = false
                            }
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(canciones.dropFirst())) { c in
                                    CardCancion(cancion: c)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 4)
                        }
                    }
                }

                Spacer(minLength: 8)
            }
        }
        .sheet(isPresented: $mostrarBuscador) {
            ZStack {
                Color(red: 28/255, green: 28/255, blue: 30/255).ignoresSafeArea()

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
            FirebaseQueueManager.shared.escucharCola(sessionId: sessionId) { lista in
                DispatchQueue.main.async {
                    self.canciones = lista
                    self.isLoading = false
                }
            }
            obtenerCodigoDeSesion(sessionId: sessionId) { codigo in
                DispatchQueue.main.async {
                    self.codigoSesion = codigo ?? "----"
                }
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

        print("🎮 Buscando: \(consulta)")
        YouTubeApi.shared.buscarVideos(query: consulta) { lista in
            DispatchQueue.main.async {
                print("📥 Resultados recibidos: \(lista.count)")
                self.resultados = lista
            }
        }
    }

    private func agregarCancion(_ cancion: YouTubeVideoItem) {
        isAdding = true

        let nueva = Cancion(
            id: cancion.id,
            titulo: cancion.titulo.htmlDecoded,
            thumbnailUrl: cancion.thumbnailUrl,
            usuario: "iOS",
            duration: cancion.duration
        )

        PlaylistifyAPI.shared.agregarCancion(sessionId: sessionId, cancion: nueva)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            resultados.removeAll()
            isAdding = false
            mostrarBuscador = false // ✅ Cierra el BottomSheet al terminar
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

private struct CardCancion: View {
    let cancion: Cancion
    var incluirBoton: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                KFImage(URL(string: cancion.thumbnailUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 70, height: 50)
                    .clipped()
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(cancion.titulo)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text("Agregado por: \(cancion.usuario)")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.caption)
                }

                Spacer()

                Text(formatDuration(cancion.duration))
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
            }

            if incluirBoton {
                Button(action: {
                    // Reproducir playlist
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Reproducir Playlist")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}


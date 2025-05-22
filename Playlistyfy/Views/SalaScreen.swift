import SwiftUI
import Kingfisher
import SwiftUIIntrospect

struct SalaScreen: View {
    let sessionId: String
    @State private var canciones: [Cancion] = []
    @State private var isLoading = true
    @State private var mostrarBuscador = false

    var body: some View {
        ZStack {
            Color(red: 28/255, green: 28/255, blue: 30/255)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // 🔝 Barra superior
                HStack {
                    Text("Playlistify")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    HStack(spacing: 20) {
                        Image(systemName: "bell")
                        Image(systemName: "magnifyingglass")
                            .onTapGesture { mostrarBuscador = true }
                        Image(systemName: "person.circle")
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 10)

                if isLoading {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        // 🎶 Reproduciendo ahora
                        Text("Reproduciendo ahora:")
                            .font(.headline)
                            .foregroundColor(.white)

                        if let actual = canciones.first {
                            CardCancion(cancion: actual, incluirBoton: true)
                        } else {
                            Text("Sin canciones en cola")
                                .foregroundColor(.white.opacity(0.7))
                        }

                        // 🎵 Título "En cola"
                        Text("En cola:")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)

                    // 🎚️ Scroll SOLO para la cola
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(canciones.dropFirst())) { c in
                                CardCancion(cancion: c)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                    // 🧠 Desactiva el rebote cuando agregues introspect
                    .introspect(.scrollView, on: .iOS(.v13, .v14, .v15, .v16, .v17)) { scrollView in
                        scrollView.bounces = false
                        scrollView.alwaysBounceVertical = false
                    }
                }

                Spacer(minLength: 8)
            }
        }
        .sheet(isPresented: $mostrarBuscador) {
            BusquedaYTView(sessionId: sessionId)
        }
        .onAppear {
            FirebaseQueueManager.shared.escucharCola(sessionId: sessionId) { lista in
                DispatchQueue.main.async {
                    self.canciones = lista
                    self.isLoading = false
                }
            }
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


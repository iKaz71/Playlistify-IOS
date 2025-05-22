import SwiftUI
import Kingfisher

struct SalaScreen: View {
    let sessionId: String
    @State private var canciones: [Cancion] = []
    @State private var isLoading = true
    @State private var mostrarBuscador = false

    var body: some View {
        ZStack {
            Color(red: 28/255, green: 28/255, blue: 30/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ✅ Barra superior igual que el fondo
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
                .background(Color(red: 28/255, green: 28/255, blue: 30/255)) // mismo fondo

                if isLoading {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Reproduciendo ahora:")
                                .font(.headline)
                                .foregroundColor(.white)

                            if let actual = canciones.first {
                                // ✅ Tarjeta con botón dentro
                                VStack(alignment: .leading, spacing: 10) {
                                    TarjetaCancion(cancion: actual, grande: true, incluirBoton: true)
                                }
                                .padding(8)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                            } else {
                                Text("Sin canciones en cola")
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Divider().background(Color.white.opacity(0.3))

                            Text("En cola:")
                                .font(.headline)
                                .foregroundColor(.white)

                            LazyVStack(spacing: 12) {
                                ForEach(Array(canciones.dropFirst())) { c in
                                    TarjetaCancion(cancion: c)
                                }
                            }
                        }
                        .padding()
                    }
                }
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

// ✅ TarjetaCancion mejorada con botón opcional
private struct TarjetaCancion: View {
    let cancion: Cancion
    var grande: Bool = false
    var incluirBoton: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                KFImage(URL(string: cancion.thumbnailUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: grande ? 90 : 70, height: grande ? 60 : 50)
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

                    Text(formatDuration(cancion.duration))
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption2)
                }

                Spacer()
            }

            // ✅ Botón solo si se requiere
            if incluirBoton {
                Button(action: {
                    // funcionalidad futura
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
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
    }
}


import SwiftUI
import Kingfisher

struct SalaScreen: View {
    let sessionId: String
    @State private var canciones: [Cancion] = []
    @State private var isLoading = true
    @State private var mostrarBuscador = false

    var body: some View {
        let _ = YouTubeApi.shared

        ZStack {
            LinearGradient(colors: [
                Color(red: 28/255, green: 28/255, blue: 30/255),
                Color(red: 142/255, green: 45/255, blue: 226/255)
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.white)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    // --- Barra superior con código y lupa ---
                    HStack {
                        Text("Sala: \(sessionId.prefix(4))")
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .bold()

                        Spacer()

                        Button {
                            mostrarBuscador = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }

                    // --- Actual ---
                    Text("Reproduciendo ahora")
                        .font(.title2).bold().foregroundColor(.white)

                    if let actual = canciones.first {
                        TarjetaCancion(cancion: actual, grande: true)
                    } else {
                        Text("Sin canciones en cola")
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Divider().background(Color.white.opacity(0.4))

                    // --- Cola ---
                    Text("En cola")
                        .font(.headline).foregroundColor(.white)

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(canciones.dropFirst())) { c in
                                TarjetaCancion(cancion: c)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            // 🔁 Escucho en tiempo real los cambios en la cola
            PlaylistifyAPI.shared.escucharCola(sessionId: sessionId) { lista in
                DispatchQueue.main.async {
                    self.canciones = lista
                    self.isLoading = false
                }
            }
        }
        .sheet(isPresented: $mostrarBuscador) {
            // Aquí mostraré el buscador de canciones
            BusquedaYTView(sessionId: sessionId)
        }
    }
}

// --- Sub‑vista reutilizable ---
private struct TarjetaCancion: View {
    let cancion: Cancion
    var grande: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: cancion.thumbnailUrl))
                .resizable()
                .placeholder {
                    ProgressView()
                }
                .frame(width: grande ? 100 : 80,
                       height: grande ? 60 : 50)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(cancion.titulo)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Text("Agregada por: \(cancion.usuario)")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)

                Text(formatDuration(cancion.duration))
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption2)
            }
        }
    }

    // 🧠 Convierto "PT4M13S" a "4:13"
    private func formatDuration(_ iso: String) -> String {
        let pattern = #"PT(?:(\d+)M)?(?:(\d+)S)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: iso, range: NSRange(iso.startIndex..., in: iso)) else {
            return "--:--"
        }

        let minRange = match.range(at: 1)
        let secRange = match.range(at: 2)

        let minutes = minRange.location != NSNotFound ? Int((iso as NSString).substring(with: minRange)) ?? 0 : 0
        let seconds = secRange.location != NSNotFound ? Int((iso as NSString).substring(with: secRange)) ?? 0 : 0

        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview { SalaScreen(sessionId: "debug-id") }


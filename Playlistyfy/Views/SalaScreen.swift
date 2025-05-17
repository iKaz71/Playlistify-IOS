import SwiftUI
import Kingfisher


struct SalaScreen: View {
    let sessionId: String
    @State private var canciones: [Cancion] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color(red: 28/255, green: 28/255, blue: 30/255),
                Color(red: 142/255, green: 45/255, blue: 226/255)],
                startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.white)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    // ---------- ACTUAL -----------
                    Text("Reproduciendo ahora")
                        .font(.title2).bold().foregroundColor(.white)

                    if let actual = canciones.first {
                        TarjetaCancion(cancion: actual, grande: true)
                    } else {
                        Text("Sin canciones en cola")
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Divider().background(Color.white.opacity(0.4))

                    // ---------- COLA -------------
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
            PlaylistifyAPI.shared.escucharCola(sessionId: sessionId) { lista in
                DispatchQueue.main.async {
                    self.canciones = lista
                    self.isLoading = false
                }
            }
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

                // 🧪 Debug: mostrar URL
                Text(cancion.thumbnailUrl)
                    .foregroundColor(.white.opacity(0.5))
                    .font(.caption2)
                    .lineLimit(1)
            }

        }
    }

    // 🧠 Parseo de duración tipo "PT4M13S"
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

#Preview { SalaScreen(sessionId: "debug‑id") }


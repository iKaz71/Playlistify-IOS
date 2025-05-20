import SwiftUI
import Kingfisher

struct BusquedaYTView: View {
    let sessionId: String
    @State private var query = ""
    @State private var resultados: [YouTubeVideoItem] = []
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var isAdding = false
    @State private var showConfirmation = false

    var body: some View {
        NavigationView {
            VStack {
                TextField("Buscar en YouTube", text: $query)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .focused($isFocused)
                    .onSubmit {
                        buscarCanciones()
                    }

                if resultados.isEmpty {
                    Text("Escribe algo para comenzar la búsqueda.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(resultados) { cancion in
                        HStack(spacing: 12) {
                            KFImage(URL(string: cancion.thumbnailUrl))
                                .resizable()
                                .frame(width: 80, height: 50)
                                .cornerRadius(8)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(cancion.titulo)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)

                                Text("Duración: \(formatDuration(cancion.duration))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Button(action: {
                                agregar(cancion: cancion)
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                            .disabled(isAdding)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Spacer()
            }
            .navigationTitle("Buscar canción")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isFocused = true
            }
            .alert(isPresented: $showConfirmation) {
                Alert(title: Text("🎶 Canción agregada"),
                      message: Text("Se agregó correctamente a la cola."),
                      dismissButton: .default(Text("OK")) {
                          dismiss()
                      })
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func buscarCanciones() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        YouTubeApi.shared.buscarVideos(query: query) { lista in
            DispatchQueue.main.async {
                self.resultados = lista
            }
        }
    }

    private func agregar(cancion: YouTubeVideoItem) {
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
            showConfirmation = true
            isAdding = false
        }
    }

}


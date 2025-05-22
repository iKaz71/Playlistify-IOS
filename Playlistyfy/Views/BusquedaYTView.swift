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

    let rojoVivo = Color(red: 1, green: 0.2, blue: 0.3)

    var body: some View {
        ZStack {
            Color(red: 28/255, green: 28/255, blue: 30/255)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // 🔍 Etiqueta y campo de búsqueda
                VStack(alignment: .leading, spacing: 6) {
                    Text("Buscar en YouTube")
                        .foregroundColor(.white)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.top, 12)
                        .padding(.horizontal)

                    HStack {
                        TextField("", text: $query)
                            .padding(.leading, 12)
                            .padding(.vertical, 10)
                            .foregroundColor(.white)
                            .focused($isFocused)
                            .onSubmit {
                                buscarCanciones()
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
                }

                // 🕵️‍♂️ Resultados
                if resultados.isEmpty {
                    Text("Realiza la búsqueda para ver resultados")
                        .foregroundColor(.white.opacity(0.5))
                        .padding()
                } else {
                    ScrollView {
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
                                        agregar(cancion: cancion)
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
                }

                Spacer()
            }
            .alert(isPresented: $showConfirmation) {
                Alert(
                    title: Text("🎶 Canción agregada"),
                    message: Text("Se agregó correctamente a la cola."),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
        }
        .onAppear {
            isFocused = true
        }
        .presentationDetents([.medium, .large])
    }

    private func buscarCanciones() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // 🔐 1. Oculta teclado primero
        ocultarTeclado()

        // ⏳ 2. Espera 0.1 segundos para asegurarte de que el teclado se cerró
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            YouTubeApi.shared.buscarVideos(query: query) { lista in
                DispatchQueue.main.async {
                    withAnimation(.easeIn(duration: 0.15)) {
                        self.resultados = lista
                    }
                }
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

    private func ocultarTeclado() {
        isFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}


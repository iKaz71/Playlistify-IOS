import Foundation

class SalaViewModel: ObservableObject {
    @Published var canciones: [Cancion] = []

    var current: Cancion? {
        canciones.first
    }

    func cargarCola(sessionId: String) {
        PlaylistifyAPI.shared.obtenerCola(sessionId: sessionId) { [weak self] lista in
            DispatchQueue.main.async {
                self?.canciones = lista
            }
        }
    }
}


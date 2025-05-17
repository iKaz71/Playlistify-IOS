import Foundation

class SalaViewModel: ObservableObject {
    @Published var canciones: [Cancion] = []

    var current: Cancion? {
        canciones.first
    }

    func escucharCola(sessionId: String) {
        FirebaseQueueManager.shared.escucharCola(sessionId: sessionId) { [weak self] lista in
            self?.canciones = lista
        }
    }
}



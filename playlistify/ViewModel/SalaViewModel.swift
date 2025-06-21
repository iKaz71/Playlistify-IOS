import Foundation


class SalaViewModel: ObservableObject {
    @Published var canciones: [Cancion] = [] // Usa el modelo Cancion, NO CancionEnCola

    var current: Cancion? {
        canciones.first
    }

    func actualizarCola(sessionId: String) {
        PlaylistifyAPI.shared.obtenerColaOrdenada(sessionId: sessionId) { cancionesOrdenadas in
            DispatchQueue.main.async {
                self.canciones = cancionesOrdenadas
            }
        }
    }
    
    
}


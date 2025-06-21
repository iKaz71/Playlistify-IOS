//
//  FirebaseQueueManager.swift
//  Playlistyfy
//
//  Created by Lex Santos on 17/05/25.
//

import FirebaseDatabase
import Foundation

// Modelo para la lista ordenada
struct CancionEnCola: Identifiable, Equatable {
    let id: String      // pushKey de Firebase
    let cancion: Cancion
}

final class FirebaseQueueManager {
    static let shared = FirebaseQueueManager()
    private let database = Database.database().reference()

    private init() {}

    /// Escuchar la cola ordenada usando queues + queuesOrder
    func escucharCola(sessionId: String, onUpdate: @escaping ([CancionEnCola]) -> Void) {
        let refCola = database.child("queues").child(sessionId)
        let refOrden = database.child("queuesOrder").child(sessionId)
        
        // Leer objeto de canciones
        refCola.observe(.value, with: { snapshot in
            var cancionesDict: [String: Cancion] = [:]
            for child in snapshot.children {
                guard let snap = child as? DataSnapshot else { continue }
                let id = snap.childSnapshot(forPath: "id").value as? String ?? ""
                let titulo = snap.childSnapshot(forPath: "titulo").value as? String ?? ""
                let usuario = snap.childSnapshot(forPath: "usuario").value as? String ?? ""
                let thumbnailUrl = snap.childSnapshot(forPath: "thumbnailUrl").value as? String ?? ""
                let duration = snap.childSnapshot(forPath: "duration").value as? String ?? ""

                let cancion = Cancion(
                    videoId: id,
                    pushKey: snap.key,
                    titulo: titulo,
                    thumbnailUrl: thumbnailUrl,
                    usuario: usuario,
                    duration: duration
                )
                cancionesDict[snap.key] = cancion
            }

            // Ahora escucha el array de orden y mezcla
            refOrden.observeSingleEvent(of: .value, with: { ordenSnap in
                let orden = ordenSnap.value as? [String] ?? []
                var listaOrdenada: [CancionEnCola] = []
                for pushKey in orden {
                    if let c = cancionesDict[pushKey] {
                        listaOrdenada.append(CancionEnCola(id: pushKey, cancion: c))
                    }
                }
                DispatchQueue.main.async {
                    onUpdate(listaOrdenada)
                }
            })
        })
    }
    
    /// Escuchar la cancion en reproducción
    func escucharPlayback(sessionId: String, onUpdate: @escaping (Cancion?) -> Void) {
        let ref = database.child("playbackState").child(sessionId).child("currentVideo")
        ref.observe(.value, with: { snapshot in
            guard let dict = snapshot.value as? [String: Any] else {
                print("📥 Playback vacío")
                onUpdate(nil)
                return
            }
            let id = dict["id"] as? String ?? ""
            let titulo = dict["titulo"] as? String ?? ""
            let usuario = dict["usuario"] as? String ?? ""
            let thumbnailUrl = dict["thumbnailUrl"] as? String ?? ""
            let duration = dict["duration"] as? String ?? ""
            let cancion = Cancion(
                videoId: id,
                pushKey: nil,
                titulo: titulo,
                thumbnailUrl: thumbnailUrl,
                usuario: usuario,
                duration: duration
            )
            print("🎵 Playback actual: \(titulo.prefix(20))")
            onUpdate(cancion)
        })
    }

    /// Eliminar cancion por pushKey
    func eliminarCancion(sessionId: String, pushKey: String, completion: ((Error?) -> Void)? = nil) {
        // Llama al backend: POST /queue/remove
        guard let url = URL(string: "https://playlistify-api-production.up.railway.app/queue/remove") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let params: [String: Any] = [
            "sessionId": sessionId,
            "pushKey": pushKey,
            "userId": "iOS"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { _, _, error in
            DispatchQueue.main.async {
                completion?(error)
            }
        }
        task.resume()
    }
}


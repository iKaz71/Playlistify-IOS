//
//  FirebaseQueueManager.swift
//  Playlistyfy
//
//  Created by Lex Santos on 17/05/25.
//

import FirebaseDatabase
import Foundation

final class FirebaseQueueManager {
    static let shared = FirebaseQueueManager()
    private let database = Database.database().reference()

    private init() {}

    func escucharCola(sessionId: String, onUpdate: @escaping ([Cancion]) -> Void) {
        let ref = database.child("queues").child(sessionId)  // ✅ Nodo correcto usado por Android y TV

        ref.observe(.value) { snapshot in
            print("📥 Snapshot recibido: \(snapshot.value ?? "sin datos")")

            var lista: [Cancion] = []

            for child in snapshot.children {
                guard let snap = child as? DataSnapshot else { continue }

                let id = snap.childSnapshot(forPath: "id").value as? String ?? ""
                let titulo = snap.childSnapshot(forPath: "titulo").value as? String ?? ""
                let usuario = snap.childSnapshot(forPath: "usuario").value as? String ?? ""
                let thumbnailUrl = snap.childSnapshot(forPath: "thumbnailUrl").value as? String ?? ""
                let duration = snap.childSnapshot(forPath: "duration").value as? String ?? ""

                print("🎧 Nodo leído: id=\(id), título=\(titulo.prefix(15)), dur=\(duration.prefix(10))")

                lista.append(Cancion(
                    id: id,
                    titulo: titulo,
                    thumbnailUrl: thumbnailUrl,
                    usuario: usuario,
                    duration: duration
                ))
            }

            DispatchQueue.main.async {
                onUpdate(lista)
            }
        }
    }
    
    func escucharPlayback(sessionId: String, onUpdate: @escaping (Cancion?) -> Void) {
        let ref = database.child("playbackState").child(sessionId).child("currentVideo")

        ref.observe(.value) { snapshot in
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

            let cancion = Cancion(id: id, titulo: titulo, thumbnailUrl: thumbnailUrl, usuario: usuario, duration: duration)
            print("🎵 Playback actual: \(titulo.prefix(20))")
            onUpdate(cancion)
        }
    }

}


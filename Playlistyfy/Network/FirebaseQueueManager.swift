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
        let ref = database.child("sessions").child(sessionId).child("queue")

        ref.observe(.value) { snapshot in
            var lista: [Cancion] = []

            for child in snapshot.children {
                if let snap = child as? DataSnapshot,
                   let value = snap.value as? [String: Any] {
                    let cancion = Cancion(
                        id: value["id"] as? String ?? "",
                        titulo: value["titulo"] as? String ?? "",
                        thumbnailUrl: value["thumbnailUrl"] as? String ?? "",
                        usuario: value["usuario"] as? String ?? "",
                        duration: value["duration"] as? String ?? ""
                    )
                    lista.append(cancion)
                }
            }

            DispatchQueue.main.async {
                onUpdate(lista)
            }
        }
    }
}

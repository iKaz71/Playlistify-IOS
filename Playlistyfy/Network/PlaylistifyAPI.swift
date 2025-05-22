//
//  PlaylistifyAPI.swift
//  Playlistify
//

import Foundation
import Alamofire
import FirebaseDatabase

// MARK: - Cliente API central

final class PlaylistifyAPI {
    static let shared = PlaylistifyAPI()
    private init() {}

    //------------------------------------------------------------------------//
    //  POST /session/verify  →  sessionId
    //------------------------------------------------------------------------//
    func verificarCodigo(codigo: String,
                         completion: @escaping (String?) -> Void)
    {
        let url = "https://playlistify-api-production.up.railway.app/session/verify"

        AF.request(url,
                   method: .post,
                   parameters: ["code": codigo],
                   encoding: JSONEncoding.default)
        .validate()
        .responseDecodable(of: SessionVerifyResponse.self) { resp in
            switch resp.result {
            case .success(let ok):
                completion(ok.sessionId)            // ✅
            case .failure(let err):
                print("❌ verificarCodigo:", err)
                completion(nil)
            }
        }
    }

    //------------------------------------------------------------------------//
    //  GET /session/:id  →  Canciones en la cola
    //------------------------------------------------------------------------//
    func obtenerCola(sessionId: String,
                     completion: @escaping ([Cancion]) -> Void)
    {
        let cleanId = sessionId.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🧪 sessionId recibido:", cleanId)

        let url = "https://playlistify-api-production.up.railway.app/session/\(cleanId)"
        print("➡️  GET \(url)")

        AF.request(url)
            .validate()
            .responseDecodable(of: SessionDetailResponse.self) { resp in
                switch resp.result {
                case .success(let data):
                    let canciones = data.queue?.values.map { $0 } ?? []
                    completion(canciones)
                case .failure(let err):
                    print("❌ obtenerCola:", err)
                    completion([])
                }
            }
    }

    //------------------------------------------------------------------------//
    //  Firebase listener para tiempo real
    //------------------------------------------------------------------------//
    func escucharCola(sessionId: String, onUpdate: @escaping ([Cancion]) -> Void) {
        let ref = Database.database().reference()
            .child("sessions")
            .child(sessionId)
            .child("queue")

        ref.observe(.value) { snapshot in
            var canciones: [Cancion] = []

            for child in snapshot.children {
                if let snap = child as? DataSnapshot,
                   let dict = snap.value as? [String: Any] {
                    let id = dict["id"] as? String ?? ""
                    let titulo = dict["titulo"] as? String ?? ""
                    let usuario = dict["usuario"] as? String ?? ""
                    let thumbnailUrl = dict["thumbnailUrl"] as? String ?? ""
                    let duration = dict["duration"] as? String ?? ""

                    canciones.append(Cancion(
                        id: id,
                        titulo: titulo,
                        thumbnailUrl: thumbnailUrl,
                        usuario: usuario,
                        duration: duration
                    ))
                }
            }

            onUpdate(canciones)
        }
    }

    //------------------------------------------------------------------------//
    //  POST /queue/add  →  Agregar canción a la cola
    //------------------------------------------------------------------------//
    func agregarCancion(sessionId: String, cancion: Cancion) {
        let url = "https://playlistify-api-production.up.railway.app/queue/add"

        // 🔐 Decodifica posibles caracteres HTML (ej: &quot;)
        let tituloLimpio = cancion.titulo.htmlDecoded

        let parametros: [String: String] = [
            "sessionId": sessionId,
            "id": cancion.id,
            "titulo": tituloLimpio,
            "thumbnailUrl": cancion.thumbnailUrl,
            "usuario": cancion.usuario,
            "duration": cancion.duration

        ]
        print("✅ Enviando duración ISO ya calculada:", cancion.duration)

        print("📤 Intentando agregar canción con parámetros:", parametros)

        AF.request(
            url,
            method: .post,
            parameters: parametros,
            encoding: JSONEncoding.default,
            headers: [.contentType("application/json")]
        )
        .validate()
        .response { response in
            if let error = response.error {
                print("❌ Error al agregar canción: \(error)")
            } else {
                print("✅ Canción agregada exitosamente")
            }
        }
    }
}





// MARK: - Extensión para decodificar caracteres HTML como &quot;
extension String {
    var htmlDecoded: String {
        guard let data = self.data(using: .utf8), !data.isEmpty else {
            return self
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        if let decoded = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return decoded.string
        }

        return self
    }

}



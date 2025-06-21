//
//  PlaylistifyAPI.swift
//  Playlistify
//

import Foundation
import Alamofire
import FirebaseDatabase
import UIKit


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
    //  GET /queue/:sessionId  →  Diccionario de canciones
    //------------------------------------------------------------------------//
    func obtenerDiccionarioCola(sessionId: String, completion: @escaping ([String: Cancion]) -> Void) {
        let url = "https://playlistify-api-production.up.railway.app/queue/\(sessionId)"
        AF.request(url)
            .validate()
            .responseJSON { resp in
                switch resp.result {
                case .success(let data):
                    if let dict = data as? [String: [String: Any]] {
                        var cancionesDict: [String: Cancion] = [:]
                        for (key, value) in dict {
                            if let cancion = Cancion.from(dictionary: value, pushKey: key) {
                                cancionesDict[key] = cancion
                            }
                        }
                        completion(cancionesDict)
                    } else {
                        completion([:])
                    }
                case .failure(let error):
                    print("❌ obtenerDiccionarioCola:", error)
                    completion([:])
                }
            }
    }

    //------------------------------------------------------------------------//
    //  GET /queueOrder/:sessionId  →  Array de orden
    //------------------------------------------------------------------------//
    func obtenerOrdenCola(sessionId: String, completion: @escaping ([String]) -> Void) {
        let url = "https://playlistify-api-production.up.railway.app/queueOrder/\(sessionId)"
        AF.request(url)
            .validate()
            .responseJSON { resp in
                switch resp.result {
                case .success(let data):
                    if let arr = data as? [String] {
                        completion(arr)
                    } else {
                        completion([])
                    }
                case .failure(let error):
                    print("❌ obtenerOrdenCola:", error)
                    completion([])
                }
            }
    }

    //------------------------------------------------------------------------//
    //  NUEVO: Obtenemos la cola ordenada para la UI
    //------------------------------------------------------------------------//
    func obtenerColaOrdenada(sessionId: String, completion: @escaping ([Cancion]) -> Void) {
        obtenerDiccionarioCola(sessionId: sessionId) { cancionesDict in
            self.obtenerOrdenCola(sessionId: sessionId) { orden in
                let cancionesOrdenadas = orden.compactMap { cancionesDict[$0] }
                completion(cancionesOrdenadas)
            }
        }
    }

    //------------------------------------------------------------------------//
    //  POST /queue/add  →  Agrega canción a la cola
    //------------------------------------------------------------------------//
    func agregarCancion(sessionId: String, cancion: Cancion, uid: String) {
        let url = "https://playlistify-api-production.up.railway.app/queue/add"

        let parametros: [String: String] = [
            "sessionId": sessionId,
            "id": cancion.id,
            "titulo": cancion.titulo.htmlDecoded,
            "thumbnailUrl": cancion.thumbnailUrl,
            "usuario": cancion.usuario,
            "duration": cancion.duration,
            "uid": uid // 👈 aquí va el uid
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
    
    //------------------------------------------------------------------------//
    //  POST /queue/remove  →  Eliminar canción de la cola
    //------------------------------------------------------------------------//
    func eliminarCancion(sessionId: String, pushKey: String, userId: String = "iOS", completion: @escaping (Error?) -> Void) {
        let url = "https://playlistify-api-production.up.railway.app/queue/remove"
        let parametros: [String: String] = [
            "sessionId": sessionId,
            "pushKey": pushKey,
            "userId": userId
        ]
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
                print("❌ Error al eliminar canción: \(error)")
                completion(error)
            } else {
                print("✅ Canción eliminada exitosamente")
                completion(nil)
            }
        }
    }

    
    
    
    //------------------------------------------------------------------------//
    //  (legacy) Firebase listener en tiempo real
    //------------------------------------------------------------------------//
    func escucharCola(sessionId: String, onUpdate: @escaping ([Cancion]) -> Void) {
        let ref = Database.database().reference()
            .child("queues")
            .child(sessionId)

        ref.observe(.value, with: { snapshot in
            var canciones: [Cancion] = []
            for child in snapshot.children {
                if let snap = child as? DataSnapshot,
                   let dict = snap.value as? [String: Any] {
                    let id = dict["id"] as? String ?? ""
                    let titulo = dict["titulo"] as? String ?? ""
                    let usuario = dict["usuario"] as? String ?? ""
                    let thumbnailUrl = dict["thumbnailUrl"] as? String ?? ""
                    let duration = dict["duration"] as? String ?? ""
                    let pushKey = snap.key
                    canciones.append(Cancion(
                        videoId: id,
                        pushKey: pushKey,
                        titulo: titulo,
                        thumbnailUrl: thumbnailUrl,
                        usuario: usuario,
                        duration: duration
                    ))
                }
            }
            onUpdate(canciones)
        })
    }

    //------------------------------------------------------------------------//
    //  POST /queue/playnext  →  Mover canción como siguiente en la cola
    //------------------------------------------------------------------------//
    func playNext(sessionId: String, pushKey: String, completion: ((Error?) -> Void)? = nil) {
        let url = "https://playlistify-api-production.up.railway.app/queue/playnext"
        let parametros: [String: String] = [
            "sessionId": sessionId,
            "pushKey": pushKey
        ]
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
                print("❌ Error al mover canción a Play Next: \(error)")
                completion?(error)
            } else {
                print("✅ Canción movida a Play Next")
                completion?(nil)
            }
        }
    }
    
    //------------------------------------------------------------------------//
    //    →  Actualizar nombre en la cola
    //------------------------------------------------------------------------//
    
    
    func actualizarNombreEnCola(sessionId: String, uid: String, nuevoNombre: String) {
        let url = "https://playlistify-api-production.up.railway.app/session/\(sessionId)/user/\(uid)/updateName"
        let params: [String: String] = ["nuevoNombre": nuevoNombre]
        AF.request(
            url,
            method: .post,
            parameters: params,
            encoding: JSONEncoding.default,
            headers: [.contentType("application/json")]
        )
        .validate()
        .response { response in
            if let error = response.error {
                print("❌ Error actualizando nombres en cola: \(error)")
            } else {
                print("✅ Nombre actualizado en canciones de la cola")
            }
        }
    }
}

// MARK: - Extensión para decodificar caracteres HTML como &quot;
extension String {
    var htmlDecoded: String {
        if self.contains("<") && self.contains(">") {
            guard let data = self.data(using: .utf8) else { return self }
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
                return attributed.string
            } else {
                print("❌ Error al decodificar HTML en string: \(self)")
                return self
            }
        } else {
            return self
        }
    }
}


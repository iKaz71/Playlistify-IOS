//
//  PlaylistifyAPI.swift
//  Playlistify
//

import Foundation
import Alamofire

// MARK: - Cliente -------------------------------------------------------------

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
        // 🔑 Elimina espacios / saltos de línea que causaban 404
        let cleanId = sessionId.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🧪 sessionId recibido:", sessionId)

        let url     = "https://playlistify-api-production.up.railway.app/session/\(cleanId)"

        print("➡️  GET \(url)")                    // ayuda a depurar

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
}


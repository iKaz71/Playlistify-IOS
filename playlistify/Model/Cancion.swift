//
//  Cancion.swift
//  Playlistyfy
//
//  Created by Lex Santos on 04/05/25.
//

import Foundation

struct Cancion: Codable, Equatable, Identifiable {
    /// El id del video de YouTube (campo "id" en JSON/Firebase)
    let videoId: String
    /// El pushKey de Firebase; nil al crear, obligatorio en la cola
    let pushKey: String?
    let titulo: String
    let thumbnailUrl: String
    let usuario: String
    let duration: String

    /// Para SwiftUI: usa pushKey para listas si existe, o videoId como fallback
    var id: String { pushKey ?? videoId }

    // Mapeo con Firebase/JSON
    enum CodingKeys: String, CodingKey {
        case videoId = "id"
        case pushKey
        case titulo
        case thumbnailUrl
        case usuario
        case duration
    }
}

// MARK: - Inicializador auxiliar para decodificar desde diccionario Firebase
extension Cancion {
    static func from(dictionary: [String: Any], pushKey: String) -> Cancion? {
        guard let id = dictionary["id"] as? String,
              let titulo = dictionary["titulo"] as? String,
              let thumbnailUrl = dictionary["thumbnailUrl"] as? String,
              let usuario = dictionary["usuario"] as? String,
              let duration = dictionary["duration"] as? String
        else {
            print("❌ Error al decodificar canción desde diccionario: \(dictionary)")
            return nil
        }
        return Cancion(
            videoId: id,         
            pushKey: pushKey,
            titulo: titulo,
            thumbnailUrl: thumbnailUrl,
            usuario: usuario,
            duration: duration
        )
    }
}


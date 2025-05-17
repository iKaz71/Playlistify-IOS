//
//  SessionDetailResponse.swift
//  Playlistify
//
//  Model que representa lo que devuelve GET /session/:id
//

import Foundation

struct SessionDetailResponse: Decodable {
    /// La cola viene como diccionario «clave Firebase» → Cancion
    let queue: [String: Cancion]?
}


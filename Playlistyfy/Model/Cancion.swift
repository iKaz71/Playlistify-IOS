//
//  Cancion.swift
//  Playlistyfy
//
//  Created by Lex Santos on 04/05/25.
//
import Foundation

struct Cancion: Codable, Identifiable {
    let id: String
    let titulo: String
    let thumbnailUrl: String
    let usuario: String
    let duration: String

    enum CodingKeys: String, CodingKey {
        case id
        case titulo
        case thumbnailUrl
        case usuario
        case duration
    }
}



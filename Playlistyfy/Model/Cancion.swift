//
//  Cancion.swift
//  Playlistyfy
//
//  Created by Lex Santos on 04/05/25.
//
import Foundation

struct Cancion: Identifiable, Codable {
    var id: String         // ID del video (YouTube)
    var titulo: String
    var thumbnailUrl: String
    var usuario: String
    var duration: String
}


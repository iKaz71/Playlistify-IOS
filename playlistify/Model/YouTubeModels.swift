//
//  YouTubeModels.swift
//  Playlistyfy
//
//  Created by Lex Santos on 17/05/25.
//

import Foundation

// MARK: - Modelo para /search
struct YouTubeSearchResponse: Decodable {
    let items: [YouTubeSearchItem]
}

struct YouTubeSearchItem: Decodable {
    let id: YouTubeVideoId
    let snippet: YouTubeSnippet
}

struct YouTubeVideoId: Decodable {
    let videoId: String?
}

struct YouTubeSnippet: Decodable {
    let title: String
    let thumbnails: YouTubeThumbnails
}

struct YouTubeThumbnails: Decodable {
    let high: YouTubeThumbnail
}

struct YouTubeThumbnail: Decodable {
    let url: String
}

// MARK: - Modelo para /videos (detalles)
struct YouTubeDetailsResponse: Decodable {
    let items: [YouTubeDetailsItem]
}

struct YouTubeDetailsItem: Decodable {
    let id: String                      // <-- 🔧 agregado para evitar el error
    let contentDetails: YouTubeContentDetails
}

struct YouTubeContentDetails: Decodable {
    let duration: String // en formato ISO 8601 (ej: "PT4M13S")
}

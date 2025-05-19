import Foundation
import Alamofire

struct YouTubeVideoItem: Identifiable, Decodable {
    let id: String
    let titulo: String
    let thumbnailUrl: String
    let duration: String
}

final class YouTubeApi {
    static let shared = YouTubeApi()
    
    private init() {
        if apiKey.isEmpty {
            fatalError("❌ La clave API no se cargó desde Info.plist.")
        } else {
            print("🔐 API KEY cargada:", apiKey)
        }
    }

    private let apiKey = Bundle.main.infoDictionary?["YOUTUBE_API_KEY"] as? String ?? ""
    private let maxResults = 5

    func buscarVideos(query: String, completion: @escaping ([YouTubeVideoItem]) -> Void) {
        print("🎮 Iniciando búsqueda con query:", query)

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=\(maxResults)&q=\(encodedQuery)&key=\(apiKey)"

        print("📅 URL de búsqueda:", url)

        AF.request(url).responseDecodable(of: YouTubeSearchResponse.self) { response in
            switch response.result {
            case .success(let searchResponse):
                let videoIds = searchResponse.items.map { $0.id.videoId }

                self.obtenerDetalles(videoIds: videoIds) { duracionesPorId in
                    let videos: [YouTubeVideoItem] = searchResponse.items.compactMap { item in
                        let id = item.id.videoId
                        guard let duracion = duracionesPorId[id] else {
                            print("⚠️ Duración no encontrada para id \(id)")
                            return nil
                        }

                        return YouTubeVideoItem(
                            id: id,
                            titulo: item.snippet.title,
                            thumbnailUrl: item.snippet.thumbnails.high.url,
                            duration: duracion
                        )
                    }

                    completion(videos)
                }

            case .failure(let error):
                print("❌ Error en YouTubeApi:", error)
                completion([])
            }
        }
    }

    private func obtenerDetalles(videoIds: [String], completion: @escaping ([String: String]) -> Void) {
        let ids = videoIds.joined(separator: ",")
        let url = "https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=\(ids)&key=\(apiKey)"

        AF.request(url).responseDecodable(of: YouTubeDetailsResponse.self) { response in
            switch response.result {
            case .success(let details):
                var mapa: [String: String] = [:]
                for item in details.items {
                    mapa[item.id] = item.contentDetails.duration
                }
                completion(mapa)

            case .failure(let error):
                print("❌ Error en detalles de YouTubeApi:", error)
                completion([:])
            }
        }
    }
}


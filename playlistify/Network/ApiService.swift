//
//  ApiService.swift
//  playlistyfy
//
//  Created by Lex Santos on 04/05/25.
//
import Foundation

class APIService {
    static let shared = APIService()
    private init() {}

    private let baseURL = "https://playlistify-api-production.up.railway.app"

    func verifyCode(code: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/session/verify") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["code": code]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let sessionId = json["sessionId"] as? String
            else {
                completion(nil)
                return
            }

            completion(sessionId)
        }.resume()
    }
}



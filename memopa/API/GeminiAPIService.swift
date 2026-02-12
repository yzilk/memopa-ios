//
//  GeminiAPIService.swift
//  memopa
//
import Foundation

enum APIError: Error {
    case invalidKey, networkError, decodingError
}

class GeminiAPIService {
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    func fetchExplation(prompt: String) async throws -> String {
        guard let apiKey = KeychainService.load() else { throw APIError.invalidKey }
        
        let url = URL(string: "\(endpoint)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [[ "parts": [[ "text": prompt ]]]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 💡 簡易的なパース（実際にはCodable推奨）
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            return text
        }
        
        throw APIError.decodingError
    }
}


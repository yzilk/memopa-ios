//
//  GeminiAPIService.swift
//  memopa
//
import Foundation

enum APIError: Error {
    case invalidKey
    case networkError
    case decodingError
    case invalidResponse
    
    var localizedDescription: String {
        switch self {
        case .invalidKey:
            return "APIキーが設定されていません"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .decodingError:
            return "レスポンスの解析に失敗しました"
        case .invalidResponse:
            return "無効なレスポンスです"
        }
    }
}

class GeminiAPIService {
    // 💡 正しいエンドポイント形式
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    
    // 💡 選択されたモデルでAPIを呼び出す
    func fetchExplanation(prompt: String) async throws -> String {
        guard let apiKey = KeychainService.loadAPIKey() else {
            throw APIError.invalidKey
        }
        
        // 💡 保存されたモデルを取得、なければデフォルトを使用
        let modelName = KeychainService.loadModel() ?? GeminiModel.flashLatest.rawValue
        // 💡 正しい形式: /v1beta/models/{model}:generateContent
        let endpoint = "\(baseURL)/models/\(modelName):generateContent"
        
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw APIError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 💡 HTTPレスポンスのステータスコードをチェック
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("API Error: Status code \(httpResponse.statusCode)")
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("Error response: \(errorString)")
                    }
                    throw APIError.networkError
                }
            }
            
            // 💡 レスポンスをパース
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                return text
            }
            
            throw APIError.decodingError
            
        } catch let error as APIError {
            throw error
        } catch {
            print("Network error: \(error.localizedDescription)")
            throw APIError.networkError
        }
    }
    
    // 💡 APIキーの検証
    func validateAPIKey(_ key: String) async -> Bool {
        let testPrompt = "Hello"
        
        // 💡 正しいモデルID: gemini-flash-latest
        let endpoint = "\(baseURL)/models/gemini-flash-latest:generateContent"
        
        guard let url = URL(string: "\(endpoint)?key=\(key)") else {
            print("❌ Invalid URL")
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": testPrompt]
                    ]
                ]
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            print("❌ Failed to serialize body")
            return false
        }
        
        request.httpBody = httpBody
        
        print("🔍 Validating API key...")
        print("URL: \(url.absoluteString.replacingOccurrences(of: key, with: "***"))")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Status code: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response preview: \(responseString.prefix(200))...")
                }
                
                // 💡 200番台のステータスコードなら成功
                let isSuccess = (200...299).contains(httpResponse.statusCode)
                
                if isSuccess {
                    print("✅ API key is valid")
                } else {
                    print("❌ API returned error status: \(httpResponse.statusCode)")
                }
                
                return isSuccess
            }
            
            print("❌ No HTTP response")
            return false
            
        } catch {
            print("❌ Validation error: \(error.localizedDescription)")
            return false
        }
    }
    
    // 💡 利用可能なモデルをリストアップ（デバッグ用）
    private func listAvailableModels(key: String) async {
        let listEndpoint = "\(baseURL)/models"
        
        guard let url = URL(string: "\(listEndpoint)?key=\(key)") else {
            print("❌ Invalid list URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📋 List models status: \(httpResponse.statusCode)")
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let models = json["models"] as? [[String: Any]] {
                    print("📋 Available models:")
                    for model in models {
                        if let name = model["name"] as? String,
                           let supportedMethods = model["supportedGenerationMethods"] as? [String],
                           supportedMethods.contains("generateContent") {
                            // models/gemini-1.5-flash → gemini-1.5-flash
                            let modelId = name.replacingOccurrences(of: "models/", with: "")
                            print("  ✓ \(modelId)")
                        }
                    }
                }
            }
        } catch {
            print("❌ Failed to list models: \(error.localizedDescription)")
        }
    }
}

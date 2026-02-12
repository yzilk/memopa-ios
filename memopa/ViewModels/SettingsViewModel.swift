//
//  SettingsViewModel.swift
//  memopa
//

import Foundation
import Observation

@Observable
class SettingsViewModel {
    var apiKey: String = ""
    var selectedModel: GeminiModel = .flashLatest
    var isValidating: Bool = false
    var validationMessage: String = ""
    var showValidationAlert: Bool = false
    
    private let apiService = GeminiAPIService()
    
    init() {
        loadSettings()
    }
    
    // 💡 保存された設定を読み込む
    func loadSettings() {
        if let savedKey = KeychainService.loadAPIKey() {
            apiKey = savedKey
        }
        
        if let savedModel = KeychainService.loadModel(),
           let model = GeminiModel(rawValue: savedModel) {
            selectedModel = model
        }
    }
    
    // 💡 設定を保存
    func saveSettings() {
        if !apiKey.isEmpty {
            KeychainService.saveAPIKey(apiKey)
        }
        KeychainService.saveModel(selectedModel.rawValue)
    }
    
    // 💡 APIキーを検証
    func validateAPIKey() async {
        guard !apiKey.isEmpty else {
            validationMessage = "APIキーを入力してください"
            showValidationAlert = true
            return
        }
        
        // 💡 APIキーの形式チェック（Gemini APIキーは通常39文字）
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedKey.count < 30 {
            validationMessage = "APIキーの形式が正しくありません。Google AI StudioからコピーしたAPIキーを入力してください。"
            showValidationAlert = true
            return
        }
        
        isValidating = true
        
        print("🔑 Starting validation for API key: \(trimmedKey.prefix(10))...")
        
        let isValid = await apiService.validateAPIKey(trimmedKey)
        
        isValidating = false
        
        print("🔑 Validation result: \(isValid ? "✅ Valid" : "❌ Invalid")")
        
        if isValid {
            validationMessage = "✅ APIキーは有効です！\n\nAI機能が使用できます。"
            apiKey = trimmedKey
            KeychainService.saveAPIKey(trimmedKey)
        } else {
            validationMessage = "❌ 検証に失敗しました\n\nGemini APIの使用状況にアクセスが記録されている場合、以下の可能性があります：\n\n• APIのレスポンス形式が変更された\n• ネットワークタイムアウト\n• APIの制限に達している\n\nXcodeのコンソールログを確認してください。"
        }
        
        showValidationAlert = true
    }
    
    // 💡 APIキーを削除
    func deleteAPIKey() {
        apiKey = ""
        KeychainService.deleteAPIKey()
    }
    
    // 💡 APIキーが設定されているかチェック
    var hasAPIKey: Bool {
        !apiKey.isEmpty
    }
}

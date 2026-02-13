//
//  AIButtonConfig.swift
//  memopa
//
import Foundation

// MARK: - AIボタンの設定
struct AIButtonConfig: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var prompt: String
    var isEnabled: Bool
    
    init(id: UUID = UUID(), name: String, prompt: String, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.isEnabled = isEnabled
    }
}

// MARK: - AIレスポンスのカード構造
struct AIResponseCard: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let body: String
    
    init(id: UUID = UUID(), title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
}

// MARK: - AIレスポンス全体の構造
struct AIResponse: Codable {
    let cardCount: Int
    let cards: [CardData]
    
    enum CodingKeys: String, CodingKey {
        case cardCount = "card_count"
        case cards
    }
    
    struct CardData: Codable {
        let title: String
        let body: String
    }
}

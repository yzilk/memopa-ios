//
//  EditorElement.swift
//  memopa
//
// EditorElement.swift
import Foundation

// MARK: - AIの動作モード
// 💡 PromptFactoryやViewModelで共通利用するため、ここを唯一のソースにします
enum AIMode: String, CaseIterable {
    case definition
    case metaphor
    case essence
}

// MARK: - エディタの構成要素
// 💡 Identifiable & Equatable を継承することで ForEach や Observation との相性を高めます
enum EditorElement: Identifiable, Equatable {
    case text(id: UUID, content: String)
    case aiCard(card: AICard)
    
    var id: UUID {
        switch self {
        case .text(let id, _): return id
        case .aiCard(let card): return card.id
        }
    }
    
    // 💡 Associated Value が Equatable (UUID, String, AICard) なので、
    // 明示的な == の実装は不要になり、コンパイラが自動生成してくれます。
}

// MARK: - AI解説カードのデータ構造
struct AICard: Identifiable, Equatable {
    let id: UUID
    let text: String
    
    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

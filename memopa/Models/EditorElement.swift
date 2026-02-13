//
//  EditorElement.swift
//  memopa
//
// EditorElement.swift
import Foundation

// MARK: - エディタの構成要素
enum EditorElement: Identifiable, Equatable {
    case text(id: UUID, content: String)
    case aiCard(card: AIResponseCard)
    
    var id: UUID {
        switch self {
        case .text(let id, _): return id
        case .aiCard(let card): return card.id
        }
    }
}

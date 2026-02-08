//
//  Note.swift
//  memopa
//

import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var content: String
    var createdAt: Date
    
    init(content: String = "") {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
    }
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
}

//Dev用
extension Note {
    static var mock: Note {
        Note(content: "これはテストメモです。\n2行目のテキスト。")
    }
}

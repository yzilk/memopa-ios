//
//  NoteListViewModel..swift
//  memopa
//


import Foundation
import SwiftData
import Observation
import UIKit

@Observable
class NoteListViewModel {
    var modelContext: ModelContext
    var clipboardText: String = ""
    var hasClipboardContent: Bool = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkClipboard()
    }
    
    // 💡 クリップボードの内容をチェック
    func checkClipboard() {
        if let text = UIPasteboard.general.string, !text.isEmpty {
            clipboardText = text
            hasClipboardContent = true
        } else {
            clipboardText = ""
            hasClipboardContent = false
        }
    }
    
    // 💡 クリップボードの内容で新規ノートを作成
    func createNoteWithClipboard() -> Note {
        let newNote = Note(content: clipboardText)
        modelContext.insert(newNote)
        return newNote
    }
    
    // 💡 空のノートを作成
    func createEmptyNote() -> Note {
        let newNote = Note(content: "")
        modelContext.insert(newNote)
        return newNote
    }
    
    // 💡 リストからの削除ロジックをここに集約
    func deleteNote(_ note: Note) {
        modelContext.delete(note)
        // SwiftDataは自動保存されますが、明示的に行う場合は try? modelContext.save()
    }
}

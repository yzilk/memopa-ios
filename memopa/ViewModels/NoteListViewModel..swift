//
//  NoteListViewModel..swift
//  memopa
//


import Foundation
import SwiftData
import Observation

@Observable
class NoteListViewModel {
    var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // 💡 リストからの削除ロジックをここに集約
    func deleteNote(_ note: Note) {
        modelContext.delete(note)
        // SwiftDataは自動保存されますが、明示的に行う場合は try? modelContext.save()
    }
}

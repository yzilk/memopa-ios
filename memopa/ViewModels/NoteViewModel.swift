//
//  NoteViewModel.swift
//  memopa
//

import Foundation
import SwiftData
import Observation

@Observable
final class NoteViewModel {
    var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func addNote(content: String) {
        let newNote = Note(content: content)
        modelContext.insert(newNote)
    }
    
    func deleteNote(_ note: Note) {
        modelContext.delete(note)
    }
}

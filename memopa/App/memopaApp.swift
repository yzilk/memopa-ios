//
//  memopaApp.swift
//  memopa
//

import SwiftUI
import SwiftData

@main
struct memopaApp: App {
    var body: some Scene {
        WindowGroup {
            NoteListView()
        }
        .modelContainer(for: Note.self)
    }
}

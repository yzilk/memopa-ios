//
//  NoteListView.swift
//  memopa
//

import SwiftUI
import SwiftData

struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @State private var viewModel: NoteViewModel?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(notes) { note in
                    NavigationLink(destination: NoteDetailView(note: note)) {
                        NoteCardView(note: note)
                    }
                }
                .onDelete(perform: deleteNotes)
                .listStyle(.plain)
                .background(Color(.systemBackground))
            }
            .listStyle(.plain) // 余計な余白を消して画面を広く使う
            .navigationTitle("すべてのメモ") // タイトルも純正風に
            .navigationBarTitleDisplayMode(.inline) // ← ここで「デカすぎる題名」を解消！
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Button(action: addNote) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .onAppear {
                if viewModel == nil { viewModel = NoteViewModel(modelContext: modelContext) }
            }
        }
    }
    
    private func addNote() {
        viewModel?.addNote(content: "")
    }
    
    private func deleteNotes(offsets: IndexSet) {
        for index in offsets {
            viewModel?.deleteNote(notes[index])
        }
    }
}


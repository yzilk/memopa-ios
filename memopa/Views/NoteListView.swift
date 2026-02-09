//
//  NoteListView.swift
//  memopa
//

import SwiftUI
import SwiftData

struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    
    @State private var navigationPath = NavigationPath()
    @State private var viewModel: NoteViewModel?
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                LinearGradient(colors: [Color.orange.opacity(0.1), Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                List {
                    ForEach(notes) { note in
                        NavigationLink(value: note) {
                            NoteCardView(note: note)
                        }
                        .listRowBackground(Color.white.opacity(0.5))
                    }
                    .onDelete(perform: deleteNotes)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("すべてのメモ")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Note.self) { note in
                NoteDetailView(note: note)
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Button(action: addAndEditNote) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .onAppear {
                if viewModel == nil { viewModel = NoteViewModel(modelContext: modelContext) }
            }
        }
    }
    
    private func addAndEditNote() {
        let newNote = Note(content: "")
        modelContext.insert(newNote)
        navigationPath.append(newNote)
    }
    
    private func deleteNotes(offsets: IndexSet) {
        for index in offsets {
            viewModel?.deleteNote(notes[index])
        }
    }
}
    

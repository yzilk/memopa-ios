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
    // 💡 リスト管理用の ViewModel に変更
    @State private var listViewModel: NoteListViewModel?
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                LinearGradient(colors: [Color.orange.opacity(0.1), Color(.systemBackground)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                List {
                    ForEach(notes) { note in
                        // 💡 Note オブジェクトを直接渡し、Destination で DetailView が生成される
                        NavigationLink(value: note) {
                            NoteCardView(note: note)
                        }
                        .listRowBackground(Color.white.opacity(0.5))
                    }
                    .onDelete(perform: deleteNotes) // 💡 ここで削除
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("すべてのメモ")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Note.self) { note in
                // 💡 DetailView 側で独自の NoteViewModel が生成される
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
                if listViewModel == nil {
                    listViewModel = NoteListViewModel(modelContext: modelContext)
                }
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
            // 💡 リスト用 ViewModel に削除を依頼
            listViewModel?.deleteNote(notes[index])
        }
    }
}

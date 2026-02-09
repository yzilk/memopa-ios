//
//  NoteDetailView.swift
//  memopa
//

import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @Bindable var note: Note
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused = true
                }
            
            TextEditor(text: $note.content)
                .focused($isFocused)
                .font(.body)
                .lineSpacing(5)
                .padding(.horizontal)
                .scrollContentBackground(.hidden)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isFocused {
                    Button("完了") {
                        isFocused = false 
                    }
                }
            }
        }
        .onAppear {
            // 新規メモの場合は即座にキーボードを出す
            if note.content.isEmpty {
                isFocused = true
            }
        }
    }
}

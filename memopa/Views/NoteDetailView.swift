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
        ScrollView {
            // テキストエディタの枠を消して、画面全体を入力エリアにする
            TextEditor(text: $note.content)
                .focused($isFocused)
                .frame(minHeight: 300) // 少なくとも画面の大部分をタップ可能にする
                .padding()
        }
        .navigationTitle("") // 詳細画面ではタイトルを空にするのが純正流
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isFocused = true // 開いた瞬間にキーボードを出す
        }
    }
}

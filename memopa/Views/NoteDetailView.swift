//
//  NoteDetailView.swift
//  memopa
//
import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @Bindable var note: Note
    @FocusState private var isFocused: Bool
    @State private var showCopiedBadge = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // タップでフォーカスを当てる背景
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { isFocused = true }
            
            InstantCopyEditor(text: $note.content) {
                showCopyFeedback()
            }
            .focused($isFocused)
            .padding(.horizontal)
            
            // コピー通知バッジ
            if showCopiedBadge {
                copyBadge
                    .padding(.top, 10)
                    .padding(.leading, 10)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // --- 右上の完了ボタン ---
            ToolbarItem(placement: .navigationBarTrailing) {
                if isFocused {
                    Button("完了") { isFocused = false }
                        .transition(.opacity)
                }
            }
        }
        .animation(.spring(), value: isFocused)
        .onAppear {
            autoFocusIfNeeded()
        }
    }
    // NoteDetailView の body の外などに定義
    var aiToolbar: some View {
        HStack(spacing: 8) {
            AIActionButton(title: "💡 ってなに？") { print("なに？") }
            AIActionButton(title: "☁️ ゆるふわ") { print("ゆるふわ") }
            AIActionButton(title: "🎯 要すると？") { print("要するに") }
            Spacer()
            Button("完了") { isFocused = false }
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(.ultraThinMaterial)
    }
    // MARK: - Helper Views & Functions
    
    private var copyBadge: some View {
        Text("Copied!")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(Capsule())
            .shadow(radius: 10)
            .transition(.scale.combined(with: .opacity))
            .zIndex(1)
    }
    
    private func showCopyFeedback() {
        withAnimation(.spring()) { showCopiedBadge = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showCopiedBadge = false }
        }
    }
    
    private func autoFocusIfNeeded() {
        if note.content.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isFocused = true
            }
        }
    }
    
    private func processAI(mode: AIMode) {
        // TODO: ここで選択範囲のテキストを取得してAIに投げる
        print("AI実行: \(mode)")
    }
}

// MARK: - Subviews

struct AIActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.05))
                .clipShape(Capsule())
        }
    }
}

enum AIMode {
    case definition, metaphor, essence
}

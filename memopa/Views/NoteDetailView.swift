//
//  NoteDetailView.swift
//  memopa
//
import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @Bindable var note: Note
    @FocusState private var isFocused: Bool
    @State private var showCopiedBadge = false //
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { isFocused = true }
            InstantCopyEditor(text: $note.content) {
                withAnimation(.spring()) {
                    showCopiedBadge = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showCopiedBadge = false
                    }
                }
            }
            .focused($isFocused)
            .padding(.horizontal)
            if showCopiedBadge {
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
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isFocused {
                    Button("完了") {
                        isFocused = false
                    }
                    .transition(.opacity) 
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isFocused {
                HStack(spacing: 12) {
                    MarbleGlassButton(title: "何？") { print("何？") }
                    MarbleGlassButton(title: "どゆこと？") { print("どゆこと？") }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .transition(.move(edge: .bottom))
                .offset(y: isFocused ? 0 : 100)
                .opacity(isFocused ? 1 : 0)
            }
        }
        .animation(.default, value: isFocused)
        .onAppear {
            if note.content.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isFocused = true
                }
            }
        }
    }
}

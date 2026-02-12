//
//  NoteDetailView.swift
//  memopa
//
import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @State private var viewModel: NoteViewModel
    @State private var isFocused: Bool = false
    @State private var showCopiedBadge = false
    
    // 💡 AppStorageを追加して、設定を保存・読み込みできるようにする
    @AppStorage("btn1_name") var btn1Name = AISettings.defaultButtons[0].name
    @AppStorage("btn1_prompt") var btn1Prompt = AISettings.defaultButtons[0].prompt
    
    @AppStorage("btn2_name") var btn2Name = AISettings.defaultButtons[1].name
    @AppStorage("btn2_prompt") var btn2Prompt = AISettings.defaultButtons[1].prompt
    
    @AppStorage("btn3_name") var btn3Name = AISettings.defaultButtons[2].name
    @AppStorage("btn3_prompt") var btn3Prompt = AISettings.defaultButtons[2].prompt
    
    init(note: Note) {
        _viewModel = State(wrappedValue: NoteViewModel(note: note))
    }
    
    var body: some View {
        @Bindable var bViewModel = viewModel
        
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach($bViewModel.elements) { $element in
                        switch element {
                        case .text(let id, _):
                            ZStack(alignment: .topLeading) {
                                InstantCopyEditor(
                                    text: binding(for: id),
                                    selectedRange: $bViewModel.selectedRange,
                                    isFocused: $isFocused,
                                    onCopy: {
                                        withAnimation(.spring()) {
                                            showCopiedBadge = true
                                        }
                                    },
                                    toolbarButtons: InstantCopyEditor.ToolbarButtons(
                                        btn1Name: btn1Name,
                                        btn1Action: { viewModel.processAI(mode: .definition, customPrompt: btn1Prompt) },
                                        btn2Name: btn2Name,
                                        btn2Action: { viewModel.processAI(mode: .metaphor, customPrompt: btn2Prompt) },
                                        btn3Name: btn3Name,
                                        btn3Action: { viewModel.processAI(mode: .essence, customPrompt: btn3Prompt) }
                                    )
                                )
                                
                                // 💡 クリップボードサジェスト（GitHub Copilot風）
                                if viewModel.showClipboardSuggestion, binding(for: id).wrappedValue.isEmpty {
                                    Text(viewModel.clipboardSuggestion)
                                        .font(.body)
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .allowsHitTesting(false)
                                        .transition(.opacity)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // 💡 サジェストが表示されている場合は統合
                                if viewModel.showClipboardSuggestion {
                                    withAnimation {
                                        viewModel.acceptClipboardSuggestion()
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .frame(maxWidth: UIScreen.main.bounds.width)
                            
                        case .aiCard(let card):
                            AICardView(
                                text: card.text,
                                onAdopt: { viewModel.adoptCard(card) },
                                onDiscard: { viewModel.discardCard(card) }
                            )
                            .frame(maxWidth: .infinity)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                    }
                    
                    // 💡 空白エリアをタップしたらサジェストを消す
                    Color.clear
                        .frame(height: 120)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if viewModel.showClipboardSuggestion {
                                withAnimation {
                                    viewModel.dismissClipboardSuggestion()
                                }
                            }
                        }
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
            
            if showCopiedBadge {
                copyBadge
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation { showCopiedBadge = false }
                        }
                    }
                    .padding(.top, 10)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完了") {
                    isFocused = false
                }
                .fontWeight(.bold)
                .foregroundColor(.blue)
            }
        }
        .onAppear {
            // 💡 ビューが表示されたら自動的にキーボードを表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func binding(for id: UUID) -> Binding<String> {
        Binding(
            get: {
                if case .text(_, let content) = viewModel.elements.first(where: { $0.id == id }) {
                    return content
                }
                return ""
            },
            set: { newValue in
                if let index = viewModel.elements.firstIndex(where: { $0.id == id }) {
                    viewModel.elements[index] = .text(id: id, content: newValue)
                    viewModel.syncToNote()
                    
                    // 💡 ユーザーが文字を入力したらサジェストを消す
                    if !newValue.isEmpty && viewModel.showClipboardSuggestion {
                        viewModel.dismissClipboardSuggestion()
                    }
                }
            }
        )
    }
    
    private var copyBadge: some View {
        Text("Copied to Clipboard")
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.7)))
            .shadow(radius: 4)
    }
}
    

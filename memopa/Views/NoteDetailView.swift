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
                    ForEach(Array($bViewModel.elements.enumerated()), id: \.element.id) { idx, $element in
                        switch element {
                        case .text(let id, _):
                            ZStack(alignment: .topLeading) {
                                InstantCopyEditor(
                                    text: binding(for: id),
                                    selectedRange: $bViewModel.selectedRange,
                                    isFocused: Binding(
                                        get: { isFocused && isFirstTextElement(id: id) },
                                        set: { newValue in
                                            if newValue { isFocused = true }
                                            else { isFocused = false }
                                        }
                                    ),
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
                                if viewModel.showClipboardSuggestion {
                                    withAnimation {
                                        viewModel.acceptClipboardSuggestion()
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                        case .aiCard(let card):
                            AICardView(
                                text: card.text,
                                onAdopt: { viewModel.adoptCard(card) },
                                onDiscard: { viewModel.discardCard(card) }
                            )
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                    }
                    
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
            
            if viewModel.isLoadingAI {
                VStack {
                    Spacer()
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("AI解析中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.bottom, 80)
                }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }
    
    private func isFirstTextElement(id: UUID) -> Bool {
        guard let firstTextElement = viewModel.elements.first(where: {
            if case .text = $0 { return true } else { return false }
        }) else { return false }
        return firstTextElement.id == id
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
    

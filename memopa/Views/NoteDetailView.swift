//
//  NoteDetailView.swift
//  memopa
//
import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @State private var viewModel: NoteViewModel
    @State private var showCopiedBadge = false
    @State private var showButtonConfig = false
    
    init(note: Note) {
        _viewModel = State(wrappedValue: NoteViewModel(note: note))
    }
    
    var body: some View {
        @Bindable var bViewModel = viewModel
        
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) { // 💡 spacingを0にして制御をEditor側に持たせる
                    ForEach(Array($bViewModel.elements.enumerated()), id: \.element.id) { idx, $element in
                        switch element {
                        case .text(let id, _):
                            VStack(spacing: 0) {
                                InstantCopyEditor(
                                    text: binding(for: id),
                                    selectedRange: Binding(
                                        get: { viewModel.selectedRanges[id] ?? NSRange(location: 0, length: 0) },
                                        set: { viewModel.selectedRanges[id] = $0 }
                                    ),
                                    isFocused: Binding(
                                        get: { viewModel.focusedTextBoxId == id },
                                        set: { newValue in
                                            if newValue {
                                                viewModel.focusedTextBoxId = id
                                            } else if viewModel.focusedTextBoxId == id {
                                                viewModel.focusedTextBoxId = nil
                                            }
                                        }
                                    ),
                                    onCopy: {
                                        withAnimation(.spring()) {
                                            showCopiedBadge = true
                                        }
                                    },
                                    onLongPress: {
                                        if let clipboardText = UIPasteboard.general.string {
                                            if let index = viewModel.elements.firstIndex(where: { $0.id == id }),
                                               case .text(let textId, let content) = viewModel.elements[index] {
                                                viewModel.elements[index] = .text(id: textId, content: content + clipboardText)
                                                viewModel.syncToNote()
                                            }
                                        }
                                    },
                                    buttonConfigs: viewModel.buttonConfigViewModel.enabledButtons,
                                    onButtonTap: { config in
                                        viewModel.processAI(buttonConfig: config)
                                    }
                                )
                                // 💡 青色背景: UITextViewの描画領域
                                // 💡 InstantCopyEditor内部のInsetで左右16pxを確保している前提です
                                .background(Color.blue.opacity(0.1))
                                .overlay(alignment: .topLeading) {
                                    if viewModel.showClipboardSuggestion && binding(for: id).wrappedValue.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(viewModel.clipboardSuggestion)
                                                .font(.body)
                                                .foregroundColor(.gray.opacity(0.5))
                                                .multilineTextAlignment(.leading)
                                            
                                            Text("タップして貼り付け")
                                                .font(.caption2)
                                                .foregroundColor(.blue.opacity(0.6))
                                        }
                                        .padding(.top, 12) // Insetに合わせる
                                        .padding(.horizontal, 16) // Insetに合わせる
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            withAnimation {
                                                viewModel.acceptClipboardSuggestion()
                                            }
                                        }
                                    }
                                }
                            }
                            // 💡 緑色背景: 外側のフレーム（画面端まで広げる）
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .frame(minHeight: isLastTextBox(id: id) ? 400 : 0) // 💡 最後の箱だけ広く取る
                            .background(Color.green.opacity(0.1))
                            
                        case .aiCard(let card):
                            AICardView(
                                card: card,
                                onAdopt: { viewModel.adoptCard(card) },
                                onDiscard: { viewModel.discardCard(card) }
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                    }
                    
                    // 下部の余白をタップした時の判定
                    Color.clear
                        .frame(height: 150)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.focusedTextBoxId = nil
                            if viewModel.showClipboardSuggestion {
                                withAnimation { viewModel.dismissClipboardSuggestion() }
                            }
                        }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            
            // --- Overlays (Badge / Loading) ---
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
                aiLoadingIndicator
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { showButtonConfig = true } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
            
            if viewModel.focusedTextBoxId != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") { viewModel.focusedTextBoxId = nil }
                        .fontWeight(.bold)
                }
            }
        }
        .sheet(isPresented: $showButtonConfig) {
            NavigationView { AIButtonConfigView() }
                .onDisappear { viewModel.buttonConfigViewModel.loadButtons() }
        }
        .onAppear {
            if let firstTextId = viewModel.elements.first?.id {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.focusedTextBoxId = firstTextId
                }
            }
        }
    }
    
    // MARK: - Components & Helpers
    
    private var aiLoadingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView().scaleEffect(0.8)
            Text("AI解析中...").font(.caption2).foregroundColor(.secondary)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Capsule().fill(.ultraThinMaterial))
        .padding(.top, 10)
    }
    
    private func isLastTextBox(id: UUID) -> Bool {
        viewModel.elements.last(where: { if case .text = $0 { return true }; return false })?.id == id
    }
    
    private func binding(for id: UUID) -> Binding<String> {
        Binding(
            get: {
                if case .text(_, let content) = viewModel.elements.first(where: { $0.id == id }) { return content }
                return ""
            },
            set: { newValue in
                if let index = viewModel.elements.firstIndex(where: { $0.id == id }) {
                    viewModel.elements[index] = .text(id: id, content: newValue)
                    viewModel.syncToNote()
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
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.7)))
            .shadow(radius: 4)
    }
}

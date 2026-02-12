//
//  InstantCopyEditor.swift
//  memopa
//
import SwiftUI
import UIKit

struct InstantCopyEditor: UIViewRepresentable {
    @Binding var text: String
    var onCopy: () -> Void
    
    // --- 💡 1. ツールバーの内容をここに定義 ---
    private var aiToolbar: some View {
        HStack(spacing: 12) {
            AIActionButton(title: "💡 ってなに？") { print("なに？") }
            AIActionButton(title: "☁️ ゆる解説") { print("ゆるふわ") }
            AIActionButton(title: "🎯 要するに？") { print("要するに") }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.secondarySystemBackground)) // ツールバーらしい色
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = CustomTextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = true
        
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        textView.addGestureRecognizer(longPress)
        
        // 💡 修正：非推奨の UIScreen を一切使わない書き方
        let screenWidth = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? 375
        
        let hostingController = UIHostingController(rootView: aiToolbar)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 44)
        textView.inputAccessoryView = hostingController.view
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - CustomTextView (内部クラスとして定義し直し)
    class CustomTextView: UITextView {
        // メニューの制御などは必要に応じて後で追加
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: InstantCopyEditor
        private let feedback = UIImpactFeedbackGenerator(style: .light)
        private var copyWorkItem: DispatchWorkItem?
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            
            if let pasteString = UIPasteboard.general.string {
                // 振動フィードバック
                feedback.prepare()
                feedback.impactOccurred()
                
                // 現在のカーソル位置にペースト
                parent.text += pasteString
                
                print("長押しでペースト完了！")
            }
        }
        
        init(_ parent: InstantCopyEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            copyWorkItem?.cancel()
            
            guard let range = textView.selectedTextRange,
                  let selectedText = textView.text(in: range),
                  !selectedText.isEmpty else { return }
            
            let item = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                UIPasteboard.general.string = selectedText
                self.feedback.prepare()
                self.feedback.impactOccurred()
                
                DispatchQueue.main.async {
                    self.parent.onCopy()
                }
            }
            
            copyWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: item)
        }
    }
}


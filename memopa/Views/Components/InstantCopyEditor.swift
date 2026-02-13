//
//  InstantCopyEditor.swift
//  memopa
//
import SwiftUI
import UIKit

struct InstantCopyEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    @Binding var isFocused: Bool
    var onCopy: () -> Void
    var onLongPress: () -> Void  // 💡 長押しコールバック
    var buttonConfigs: [AIButtonConfig]
    var onButtonTap: (AIButtonConfig) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.keyboardType = .default
        textView.autocorrectionType = .default
        
        // 💡 長押しジェスチャーを追加
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress))
        textView.addGestureRecognizer(longPressGesture)
        
        // 💡 カスタムツールバーを作成
        updateToolbar(textView: textView, context: context)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.selectedRange != selectedRange {
            uiView.selectedRange = selectedRange
        }
        
        // 💡 FocusStateとUITextViewのフォーカス状態を同期
        if isFocused && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
        
        // 💡 ツールバーを更新
        updateToolbar(textView: uiView, context: context)
    }
    
    private func updateToolbar(textView: UITextView, context: Context) {
        let toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        
        var items: [UIBarButtonItem] = []
        
        // 💡 有効なボタンを動的に追加
        for (index, config) in buttonConfigs.enumerated() {
            let button = UIBarButtonItem(
                title: config.name,
                style: .plain,
                target: context.coordinator,
                action: #selector(Coordinator.buttonTapped(_:))
            )
            button.tag = index
            button.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 13, weight: .medium)], for: .normal)
            items.append(button)
        }
        
        // スペーサー
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        items.append(flexSpace)
        
        toolbar.items = items
        toolbar.sizeToFit()
        textView.inputAccessoryView = toolbar
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: InstantCopyEditor
        private let feedback = UIImpactFeedbackGenerator(style: .light)
        
        init(_ parent: InstantCopyEditor) {
            self.parent = parent
        }
        
        @objc func buttonTapped(_ sender: UIBarButtonItem) {
            let index = sender.tag
            if index < parent.buttonConfigs.count {
                parent.onButtonTap(parent.buttonConfigs[index])
            }
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                feedback.impactOccurred()
                parent.onLongPress()
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
            handleAutoCopy(textView)
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused = false
        }
        
        private func handleAutoCopy(_ textView: UITextView) {
            guard let range = textView.selectedTextRange,
                  let selectedText = textView.text(in: range),
                  !selectedText.isEmpty else { return }
            UIPasteboard.general.string = selectedText
            feedback.impactOccurred()
            parent.onCopy()
        }
    }
}

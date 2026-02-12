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
    var toolbarButtons: ToolbarButtons  // 💡 ツールバーボタンの情報を受け取る
    
    struct ToolbarButtons {
        let btn1Name: String
        let btn1Action: () -> Void
        let btn2Name: String
        let btn2Action: () -> Void
        let btn3Name: String
        let btn3Action: () -> Void
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.keyboardType = .default
        textView.autocorrectionType = .default
        
        // 💡 カスタムツールバーを作成
        let toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        
        // ボタン1
        let btn1 = UIBarButtonItem(title: toolbarButtons.btn1Name, style: .plain, target: context.coordinator, action: #selector(Coordinator.btn1Tapped))
        btn1.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 13, weight: .medium)], for: .normal)
        
        // ボタン2
        let btn2 = UIBarButtonItem(title: toolbarButtons.btn2Name, style: .plain, target: context.coordinator, action: #selector(Coordinator.btn2Tapped))
        btn2.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 13, weight: .medium)], for: .normal)
        
        // ボタン3
        let btn3 = UIBarButtonItem(title: toolbarButtons.btn3Name, style: .plain, target: context.coordinator, action: #selector(Coordinator.btn3Tapped))
        btn3.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 13, weight: .medium)], for: .normal)
        
        // スペーサー
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [btn1, btn2, btn3, flexSpace]
        toolbar.sizeToFit()
        textView.inputAccessoryView = toolbar
        
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
        
        // 💡 ツールバーのボタンテキストを更新
        if let toolbar = uiView.inputAccessoryView as? UIToolbar,
           let items = toolbar.items {
            if items.count >= 3 {
                items[0].title = toolbarButtons.btn1Name
                items[0].setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 13, weight: .medium)], for: .normal)
                
                items[1].title = toolbarButtons.btn2Name
                items[1].setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 13, weight: .medium)], for: .normal)
                
                items[2].title = toolbarButtons.btn3Name
                items[2].setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 13, weight: .medium)], for: .normal)
            }
        }
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
        
        @objc func btn1Tapped() {
            parent.toolbarButtons.btn1Action()
        }
        
        @objc func btn2Tapped() {
            parent.toolbarButtons.btn2Action()
        }
        
        @objc func btn3Tapped() {
            parent.toolbarButtons.btn3Action()
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

//
//  InstantCopyEditor.swift
//  memopa
//
import SwiftUI
import UIKit
import SwiftUI
import UIKit

struct InstantCopyEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    var onCopy: () -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = false // ScrollViewと喧嘩しないように
        textView.backgroundColor = .clear
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
        if uiView.selectedRange != selectedRange { uiView.selectedRange = selectedRange }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: InstantCopyEditor
        private let feedback = UIImpactFeedbackGenerator(style: .light)
        init(_ parent: InstantCopyEditor) { self.parent = parent }
        
        func textViewDidChange(_ textView: UITextView) { parent.text = textView.text }
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
            // 自動コピー（0.7秒選択で発火）
            handleAutoCopy(textView)
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

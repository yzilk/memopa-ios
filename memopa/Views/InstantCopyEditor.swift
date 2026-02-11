//
//  InstantCopyEditor.swift
//  memopa
//
import SwiftUI
import UIKit

struct InstantCopyEditor: UIViewRepresentable {
    @Binding var text: String
    var onCopy: () -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
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
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: InstantCopyEditor
        private let feedback = UIImpactFeedbackGenerator(style: .light)
        
        private var copyWorkItem: DispatchWorkItem?
        
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
                print("0.7秒待ってコピー完了: \(selectedText)")
            }
            
            copyWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: item)
        }
    }
}

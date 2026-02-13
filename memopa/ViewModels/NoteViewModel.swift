//
//  NoteViewModel.swift
//  memopa
//
import Foundation
import SwiftData
import Observation
import SwiftUI
import UIKit

@Observable
class NoteViewModel {
    var note: Note
    var elements: [EditorElement] = []
    var selectedRange: NSRange = NSRange(location: 0, length: 0)
    var clipboardSuggestion: String = ""
    var showClipboardSuggestion: Bool = false
    var isLoadingAI: Bool = false
    
    init(note: Note) {
        self.note = note
        let initialContent = note.content.isEmpty ? "" : note.content
        self.elements = [.text(id: UUID(), content: initialContent)]
        
        if note.content.isEmpty {
            checkClipboard()
        }
    }
    
    // 💡 クリップボードの内容をチェック
    func checkClipboard() {
        if let text = UIPasteboard.general.string, !text.isEmpty {
            clipboardSuggestion = text
            showClipboardSuggestion = true
        }
    }
    
    func acceptClipboardSuggestion() {
        guard showClipboardSuggestion else { return }
        
        if let index = elements.firstIndex(where: {
            if case .text = $0 { return true } else { return false }
        }), case .text(let id, _) = elements[index] {
            elements[index] = .text(id: id, content: clipboardSuggestion)
            syncToNote()
            showClipboardSuggestion = false
            clipboardSuggestion = ""
        }
    }
    
    // 💡 クリップボードサジェストを破棄
    func dismissClipboardSuggestion() {
        showClipboardSuggestion = false
        clipboardSuggestion = ""
    }
    
    func processAI(mode: AIMode, customPrompt: String) {
        guard !isLoadingAI else { return }
        
        guard let index = elements.lastIndex(where: {
            if case .text = $0 { return true } else { return false }
        }) else { return }
        
        if case .text(_, let content) = elements[index] {
            let selectedText = getSelectedText(from: content)
            let finalPrompt = "\(customPrompt)\n\n対象のテキスト:\n「\(selectedText)」"
            
            isLoadingAI = true
            
            Task {
                await fetchAIResponse(prompt: finalPrompt)
            }
        }
    }
    
    private func fetchAIResponse(prompt: String) async {
        let apiService = GeminiAPIService()
        
        do {
            let response = try await apiService.fetchExplanation(prompt: prompt)
            
            await MainActor.run {
                isLoadingAI = false
                insertAICards(responses: [response])
            }
            
        } catch let error as APIError {
            await MainActor.run {
                isLoadingAI = false
                let errorMessage = "エラー: \(error.localizedDescription)\n\n設定画面でAPIキーを確認してください。"
                insertAICards(responses: [errorMessage])
            }
        } catch {
            await MainActor.run {
                isLoadingAI = false
                insertAICards(responses: ["エラー: \(error.localizedDescription)"])
            }
        }
    }
    
    private func insertAICards(responses: [String]) {
        guard let index = elements.lastIndex(where: {
            if case .text = $0 { return true } else { return false }
        }) else { return }
        
        if case .text(let id, let content) = elements[index] {
            let cursor = selectedRange.location
            let safeCursor = min(max(0, cursor), content.count)
            
            let prefix = String(content.prefix(safeCursor))
            let suffix = String(content.suffix(content.count - safeCursor))
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                elements.remove(at: index)
                elements.insert(.text(id: id, content: prefix), at: index)
                
                var currentIndex = index + 1
                for response in responses {
                    let newCard = AICard(text: response)
                    elements.insert(.aiCard(card: newCard), at: currentIndex)
                    currentIndex += 1
                }
                
                elements.insert(.text(id: UUID(), content: suffix), at: currentIndex)
            }
        }
    }
    
    // 💡 選択範囲からテキストを抜き出す
    private func getSelectedText(from content: String) -> String {
        if selectedRange.length == 0 {
            return "（選択範囲なし：文脈から判断）"
        }
        
        // 範囲外エラーを防ぐガード
        let safeLocation = max(0, min(selectedRange.location, content.count))
        let safeLength = min(selectedRange.length, content.count - safeLocation)
        
        let start = content.index(content.startIndex, offsetBy: safeLocation)
        let end = content.index(start, offsetBy: safeLength)
        return String(content[start..<end])
    }
    
    // MARK: - カード操作
    func adoptCard(_ card: AICard) {
        withAnimation(.spring()) {
            if let index = elements.firstIndex(where: { $0.id == card.id }) {
                let adoptedText = "\n" + card.text + "\n"
                if index > 0, case .text(let id, let content) = elements[index-1] {
                    elements[index-1] = .text(id: id, content: content + adoptedText)
                    elements.remove(at: index)
                }
                syncToNote()
            }
        }
    }
    
    func discardCard(_ card: AICard) {
        withAnimation(.easeOut(duration: 0.2)) {
            elements.removeAll { $0.id == card.id }
            syncToNote()
        }
    }
    
    func syncToNote() {
        let fullText = elements.compactMap { element -> String? in
            if case .text(_, let content) = element { return content }
            return nil
        }.joined()
        note.content = fullText
    }
}

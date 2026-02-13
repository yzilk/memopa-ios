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
    var buttonConfigViewModel = AIButtonConfigViewModel()
    var focusedTextBoxId: UUID? = nil  // 💡 現在フォーカスされているテキストボックスのID
    
    init(note: Note) {
        self.note = note
        let initialContent = note.content.isEmpty ? "" : note.content
        let initialId = UUID()
        self.elements = [.text(id: initialId, content: initialContent)]
        self.focusedTextBoxId = initialId  // 💡 初期状態で最初のテキストボックスをフォーカス
        
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
    
    func processAI(buttonConfig: AIButtonConfig) {
        guard !isLoadingAI else { return }
        
        guard let index = elements.lastIndex(where: {
            if case .text = $0 { return true } else { return false }
        }) else { return }
        
        if case .text(_, let content) = elements[index] {
            // 💡 選択範囲がなく、かつテキストが空の場合は何もしない
            if selectedRange.length == 0 && content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return
            }
            
            let selectedText = getSelectedText(from: content)
            
            // 💡 選択範囲がない場合は、全文を対象にするか確認
            if selectedRange.length == 0 {
                // 全文を対象にする
                let finalPrompt = "\(buttonConfig.prompt)\n\n対象のテキスト:\n「\(content)」"
                
                isLoadingAI = true
                
                Task {
                    await fetchAIResponse(prompt: finalPrompt)
                }
            } else {
                // 選択範囲がある場合
                let finalPrompt = "\(buttonConfig.prompt)\n\n対象のテキスト:\n「\(selectedText)」"
                
                isLoadingAI = true
                
                Task {
                    await fetchAIResponse(prompt: finalPrompt)
                }
            }
        }
    }
    
    private func fetchAIResponse(prompt: String) async {
        let apiService = GeminiAPIService()
        
        do {
            let response = try await apiService.fetchExplanation(prompt: prompt)
            
            await MainActor.run {
                isLoadingAI = false
                // 💡 複数カードを挿入
                let cards = response.cards.map { cardData in
                    AIResponseCard(title: cardData.title, body: cardData.body)
                }
                insertAICards(cards: cards)
            }
            
        } catch let error as APIError {
            await MainActor.run {
                isLoadingAI = false
                let errorMessage = "エラー: \(error.localizedDescription)\n\n設定画面でAPIキーを確認してください。"
                let errorCard = AIResponseCard(title: "エラー", body: errorMessage)
                insertAICards(cards: [errorCard])
            }
        } catch {
            await MainActor.run {
                isLoadingAI = false
                let errorCard = AIResponseCard(title: "エラー", body: error.localizedDescription)
                insertAICards(cards: [errorCard])
            }
        }
    }
    
    private func insertAICards(cards: [AIResponseCard]) {
        guard let index = elements.lastIndex(where: {
            if case .text = $0 { return true } else { return false }
        }) else { return }
        
        if case .text(let id, let content) = elements[index] {
            let cursor = selectedRange.location
            let safeCursor = min(max(0, cursor), content.count)
            
            // 💡 選択範囲がある場合は、選択範囲の終了位置の後にカードを挿入
            let insertPosition = selectedRange.length > 0 
                ? min(safeCursor + selectedRange.length, content.count)
                : safeCursor
            
            let prefix = String(content.prefix(insertPosition))
            let suffix = String(content.suffix(content.count - insertPosition))
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                elements.remove(at: index)
                elements.insert(.text(id: id, content: prefix), at: index)
                
                var currentIndex = index + 1
                for card in cards {
                    elements.insert(.aiCard(card: card), at: currentIndex)
                    currentIndex += 1
                }
                
                // 💡 カードの後に必ず空のテキストボックスを追加
                let newTextBoxId = UUID()
                elements.insert(.text(id: newTextBoxId, content: suffix), at: currentIndex)
                
                // 💡 最後にテキストボックスがあることを確認
                ensureTrailingTextBox()
            }
        }
    }
    
    // 💡 選択範囲からテキストを抜き出す
    private func getSelectedText(from content: String) -> String {
        if selectedRange.length == 0 {
            // 選択範囲がない場合は全文を返す
            return content
        }
        
        // 範囲外エラーを防ぐガード
        let safeLocation = max(0, min(selectedRange.location, content.count))
        let safeLength = min(selectedRange.length, content.count - safeLocation)
        
        let start = content.index(content.startIndex, offsetBy: safeLocation)
        let end = content.index(start, offsetBy: safeLength)
        return String(content[start..<end])
    }
    
    // MARK: - カード操作
    func adoptCard(_ card: AIResponseCard) {
        withAnimation(.spring()) {
            if let index = elements.firstIndex(where: { $0.id == card.id }) {
                let adoptedText = "\n【\(card.title)】\n\(card.body)\n"
                if index > 0, case .text(let id, let content) = elements[index-1] {
                    elements[index-1] = .text(id: id, content: content + adoptedText)
                    elements.remove(at: index)
                }
                
                // 💡 最後にテキストボックスがあることを確認
                ensureTrailingTextBox()
                syncToNote()
            }
        }
    }
    
    func discardCard(_ card: AIResponseCard) {
        withAnimation(.easeOut(duration: 0.2)) {
            elements.removeAll { $0.id == card.id }
            
            // 💡 最後にテキストボックスがあることを確認
            ensureTrailingTextBox()
            syncToNote()
        }
    }
    
    // 💡 最後の要素が必ずテキストボックスであることを保証
    private func ensureTrailingTextBox() {
        if let lastElement = elements.last {
            switch lastElement {
            case .text:
                // 既にテキストボックスがある
                break
            case .aiCard:
                // カードが最後なので、テキストボックスを追加
                elements.append(.text(id: UUID(), content: ""))
            }
        } else {
            // 要素が空の場合もテキストボックスを追加
            elements.append(.text(id: UUID(), content: ""))
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

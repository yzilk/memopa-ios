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
    var selectedRanges: [UUID: NSRange] = [:]  // 💡 各テキストボックスごとの選択範囲
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
        
        // 💡 現在フォーカスされているテキストボックスを取得
        guard let focusedId = focusedTextBoxId,
              let index = elements.firstIndex(where: { $0.id == focusedId }),
              case .text(_, let content) = elements[index] else { return }
        
        // 💡 このテキストボックスの選択範囲を取得
        let selectedRange = selectedRanges[focusedId] ?? NSRange(location: 0, length: 0)
        
        // 💡 選択範囲がなく、かつテキストが空の場合は何もしない
        if selectedRange.length == 0 && content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }
        
        let selectedText = getSelectedText(from: content, range: selectedRange)
        
        // 💡 選択範囲がない場合は、全文を対象にするか確認
        let finalPrompt: String
        if selectedRange.length == 0 {
            // 全文を対象にする
            finalPrompt = "\(buttonConfig.prompt)\n\n対象のテキスト:\n「\(content)」"
        } else {
            // 選択範囲がある場合
            finalPrompt = "\(buttonConfig.prompt)\n\n対象のテキスト:\n「\(selectedText)」"
        }
        
        isLoadingAI = true
        
        Task {
            await fetchAIResponse(prompt: finalPrompt, targetTextBoxIndex: index, selectedRange: selectedRange)
        }
    }
    
    private func fetchAIResponse(prompt: String, targetTextBoxIndex: Int, selectedRange: NSRange) async {
        let apiService = GeminiAPIService()
        
        do {
            let response = try await apiService.fetchExplanation(prompt: prompt)
            
            await MainActor.run {
                isLoadingAI = false
                // 💡 複数カードを挿入
                let cards = response.cards.map { cardData in
                    AIResponseCard(title: cardData.title, body: cardData.body)
                }
                insertAICards(cards: cards, atTextBoxIndex: targetTextBoxIndex, selectedRange: selectedRange)
            }
            
        } catch let error as APIError {
            await MainActor.run {
                isLoadingAI = false
                let errorMessage = "エラー: \(error.localizedDescription)\n\n設定画面でAPIキーを確認してください。"
                let errorCard = AIResponseCard(title: "エラー", body: errorMessage)
                insertAICards(cards: [errorCard], atTextBoxIndex: targetTextBoxIndex, selectedRange: selectedRange)
            }
        } catch {
            await MainActor.run {
                isLoadingAI = false
                let errorCard = AIResponseCard(title: "エラー", body: error.localizedDescription)
                insertAICards(cards: [errorCard], atTextBoxIndex: targetTextBoxIndex, selectedRange: selectedRange)
            }
        }
    }
    
    private func insertAICards(cards: [AIResponseCard], atTextBoxIndex index: Int, selectedRange: NSRange) {
        guard index < elements.count, case .text(let id, let content) = elements[index] else { return }
        
        let cursor = selectedRange.location
        let safeCursor = min(max(0, cursor), content.count)
        
        // 💡 選択範囲がある場合は、選択範囲の終了位置の後にカードを挿入
        let selectionEnd = selectedRange.length > 0 
            ? min(safeCursor + selectedRange.length, content.count)
            : safeCursor
        
        // 💡 選択範囲の後ろから最初の改行または文末を探す
        let insertPosition: Int
        if selectionEnd < content.count {
            let searchStart = content.index(content.startIndex, offsetBy: selectionEnd)
            if let newlineRange = content[searchStart...].firstIndex(of: "\n") {
                // 改行が見つかった場合は、改行の直後に挿入
                insertPosition = content.distance(from: content.startIndex, to: newlineRange) + 1
            } else {
                // 改行が見つからない場合は、文末に挿入
                insertPosition = content.count
            }
        } else {
            // 選択範囲が文末の場合
            insertPosition = content.count
        }
        
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
            
            // 💡 選択範囲をリセット
            if case .text(let textId, _) = elements[index] {
                selectedRanges[textId] = NSRange(location: 0, length: 0)
            }
            
            // 💡 最後にテキストボックスがあることを確認
            ensureTrailingTextBox()
        }
    }
    
    // 💡 選択範囲からテキストを抜き出す
    private func getSelectedText(from content: String, range: NSRange) -> String {
        if range.length == 0 {
            // 選択範囲がない場合は全文を返す
            return content
        }
        
        // 範囲外エラーを防ぐガード
        let safeLocation = max(0, min(range.location, content.count))
        let safeLength = min(range.length, content.count - safeLocation)
        
        let start = content.index(content.startIndex, offsetBy: safeLocation)
        let end = content.index(start, offsetBy: safeLength)
        return String(content[start..<end])
    }
    
    // MARK: - カード操作
    func adoptCard(_ card: AIResponseCard) {
        withAnimation(.spring()) {
            guard let cardIndex = elements.firstIndex(where: { $0.id == card.id }) else { return }
            
            let adoptedText = "\n【\(card.title)】\n\(card.body)\n"
            
            // 💡 カードの前後にテキストボックスがあるか確認
            let prevIndex = cardIndex - 1
            let nextIndex = cardIndex + 1
            
            let hasPrevText = prevIndex >= 0 && {
                if case .text = elements[prevIndex] { return true }
                return false
            }()
            
            let hasNextText = nextIndex < elements.count && {
                if case .text = elements[nextIndex] { return true }
                return false
            }()
            
            if hasPrevText && hasNextText,
               case .text(let prevId, let prevContent) = elements[prevIndex],
               case .text(_, let nextContent) = elements[nextIndex] {
                // 💡 前後両方にテキストボックスがある場合は統合
                elements[prevIndex] = .text(id: prevId, content: prevContent + adoptedText + nextContent)
                elements.remove(at: nextIndex) // 先に次を削除
                elements.remove(at: cardIndex) // その後カードを削除
            } else if hasNextText, case .text(let id, let content) = elements[nextIndex] {
                // 💡 次にだけテキストボックスがある場合
                elements[nextIndex] = .text(id: id, content: adoptedText + content)
                elements.remove(at: cardIndex)
            } else if hasPrevText, case .text(let id, let content) = elements[prevIndex] {
                // 💡 前にだけテキストボックスがある場合
                elements[prevIndex] = .text(id: id, content: content + adoptedText)
                elements.remove(at: cardIndex)
            } else {
                // 💡 前後にテキストボックスがない場合は、新規作成
                elements.remove(at: cardIndex)
                elements.insert(.text(id: UUID(), content: adoptedText), at: cardIndex)
            }
            
            // 💡 最後にテキストボックスがあることを確認
            ensureTrailingTextBox()
            syncToNote()
        }
    }
    
    func discardCard(_ card: AIResponseCard) {
        withAnimation(.easeOut(duration: 0.2)) {
            guard let cardIndex = elements.firstIndex(where: { $0.id == card.id }) else { return }
            
            // 💡 カードの前後にテキストボックスがあるか確認
            let prevIndex = cardIndex - 1
            let nextIndex = cardIndex + 1
            
            let hasPrevText = prevIndex >= 0 && {
                if case .text = elements[prevIndex] { return true }
                return false
            }()
            
            let hasNextText = nextIndex < elements.count && {
                if case .text = elements[nextIndex] { return true }
                return false
            }()
            
            if hasPrevText && hasNextText,
               case .text(let prevId, let prevContent) = elements[prevIndex],
               case .text(_, let nextContent) = elements[nextIndex] {
                // 💡 前後両方にテキストボックスがある場合は統合
                elements[prevIndex] = .text(id: prevId, content: prevContent + nextContent)
                elements.remove(at: nextIndex) // 先に次を削除
                elements.remove(at: cardIndex) // その後カードを削除
            } else {
                // 💡 片方だけ、または両方ない場合は単純に削除
                elements.remove(at: cardIndex)
            }
            
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

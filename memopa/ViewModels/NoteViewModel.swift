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
    
    // 💡 カードマーカーの定義
    private let cardMarkerPrefix = "[CARD:"
    private let cardMarkerSuffix = "]"
    private let cardSeparator = "|||"
    private let idSeparator = ":::"
    
    init(note: Note) {
        self.note = note
        parseContentToElements()
        
        if note.content.isEmpty {
            checkClipboard()
        }
    }
    
    // 💡 Note.contentをマーカー解析してelementsに変換
    private func parseContentToElements() {
        let content = note.content
        var currentElements: [EditorElement] = []
        var currentText = ""
        var searchStartIndex = content.startIndex
        
        while searchStartIndex < content.endIndex {
            // マーカーを探す
            if let markerStart = content[searchStartIndex...].range(of: cardMarkerPrefix) {
                // マーカーの前のテキストを追加
                let textBeforeMarker = String(content[searchStartIndex..<markerStart.lowerBound])
                currentText += textBeforeMarker
                
                // マーカーの終わりを探す
                if let markerEnd = content[markerStart.upperBound...].range(of: cardMarkerSuffix) {
                    // マーカー内容を抽出
                    let markerContent = String(content[markerStart.upperBound..<markerEnd.lowerBound])
                    let parts = markerContent.components(separatedBy: idSeparator)
                    
                    // フォーマット: id:::title|||body
                    if parts.count == 2 {
                        let cardId = UUID(uuidString: parts[0]) ?? UUID()
                        let contentParts = parts[1].components(separatedBy: cardSeparator)
                        
                        if contentParts.count == 2 {
                            // 現在のテキストを要素として追加
                            if !currentElements.isEmpty || !currentText.isEmpty {
                                currentElements.append(.text(id: UUID(), content: currentText))
                                currentText = ""
                            }
                            
                            // カードを追加（IDを保持）
                            let card = AIResponseCard(id: cardId, title: contentParts[0], body: contentParts[1])
                            currentElements.append(.aiCard(card: card))
                        }
                    }
                    
                    searchStartIndex = markerEnd.upperBound
                } else {
                    // マーカーが閉じていない場合は通常テキストとして扱う
                    currentText += cardMarkerPrefix
                    searchStartIndex = markerStart.upperBound
                }
            } else {
                // マーカーが見つからない場合は残りを全てテキストとして追加
                currentText += String(content[searchStartIndex...])
                break
            }
        }
        
        // 最後のテキストを追加
        if currentElements.isEmpty {
            // 要素が1つもない場合は空のテキストボックスを作成
            let initialId = UUID()
            currentElements.append(.text(id: initialId, content: currentText))
            focusedTextBoxId = initialId
        } else {
            // カードがある場合は最後にテキストボックスを追加
            currentElements.append(.text(id: UUID(), content: currentText))
        }
        
        elements = currentElements
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
        
        // 💡 カードをマーカー形式に変換（IDを含める）
        let cardMarkers = cards.map { card in
            "\n\(cardMarkerPrefix)\(card.id.uuidString)\(idSeparator)\(card.title)\(cardSeparator)\(card.body)\(cardMarkerSuffix)\n"
        }.joined()
        
        let suffix = String(content.suffix(content.count - insertPosition))
        
        // 💡 テキストにマーカーを挿入
        let newContent = prefix + cardMarkers + suffix
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            elements[index] = .text(id: id, content: newContent)
            
            // 💡 選択範囲をリセット
            selectedRanges[id] = NSRange(location: 0, length: 0)
            
            // 💡 contentを再解析してelementsを更新
            syncToNote()
            parseContentToElements()
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
            // 💡 カードIDを使って特定のカードのマーカーだけを通常テキストに置換
            let cardMarker = "\n\(cardMarkerPrefix)\(card.id.uuidString)\(idSeparator)\(card.title)\(cardSeparator)\(card.body)\(cardMarkerSuffix)\n"
            let adoptedText = "\n【\(card.title)】\n\(card.body)\n"
            
            // 💡 IDで特定されるカードを置換
            if let range = note.content.range(of: cardMarker) {
                note.content.replaceSubrange(range, with: adoptedText)
            }
            
            // 💡 再解析
            parseContentToElements()
        }
    }
    
    func discardCard(_ card: AIResponseCard) {
        withAnimation(.easeOut(duration: 0.2)) {
            // 💡 カードIDを使って特定のカードのマーカーだけを削除
            let cardMarker = "\n\(cardMarkerPrefix)\(card.id.uuidString)\(idSeparator)\(card.title)\(cardSeparator)\(card.body)\(cardMarkerSuffix)\n"
            
            // 💡 IDで特定されるカードを削除
            if let range = note.content.range(of: cardMarker) {
                note.content.replaceSubrange(range, with: "\n")
            }
            
            // 💡 再解析
            parseContentToElements()
        }
    }
    
    func syncToNote() {
        // 💡 elementsをマーカー付きテキストに変換
        let fullText = elements.map { element -> String in
            switch element {
            case .text(_, let content):
                return content
            case .aiCard(let card):
                // カードをマーカー形式に変換（IDを含める）
                return "\(cardMarkerPrefix)\(card.id.uuidString)\(idSeparator)\(card.title)\(cardSeparator)\(card.body)\(cardMarkerSuffix)"
            }
        }.joined()
        
        note.content = fullText
    }
}

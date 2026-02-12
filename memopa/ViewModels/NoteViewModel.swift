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
    
    init(note: Note) {
        self.note = note
        let initialContent = note.content.isEmpty ? "" : note.content
        self.elements = [.text(id: UUID(), content: initialContent)]
        
        // 💡 空のノートの場合、クリップボードをチェック
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
    
    // 💡 クリップボードの内容を本文に統合
    func acceptClipboardSuggestion() {
        guard showClipboardSuggestion else { return }
        
        if let index = elements.firstIndex(where: {
            if case .text = $0 { return true } else { return false }
        }), case .text(let id, _) = elements[index] {
            elements[index] = .text(id: id, content: clipboardSuggestion)
            syncToNote()
        }
        
        showClipboardSuggestion = false
        clipboardSuggestion = ""
    }
    
    // 💡 クリップボードサジェストを破棄
    func dismissClipboardSuggestion() {
        showClipboardSuggestion = false
        clipboardSuggestion = ""
    }
    
    // MARK: - 核心ロジック：AIカードの挿入
    func processAI(mode: AIMode, customPrompt: String) {
        // テキスト要素を探す
        guard let index = elements.lastIndex(where: {
            if case .text = $0 { return true } else { return false }
        }) else { return }
        
        if case .text(let id, let content) = elements[index] {
            
            // 💡 ユーザーがなぞったテキストを取得
            let selectedText = getSelectedText(from: content)
            
            // 💡 命令文（customPrompt）と対象テキストを合体
            let finalPrompt = "\(customPrompt)\n\n対象のテキスト:\n「\(selectedText)」"
            
            // カードを挿入するカーソル位置
            let cursor = selectedRange.location
            let safeCursor = min(max(0, cursor), content.count)
            
            let prefix = String(content.prefix(safeCursor))
            let suffix = String(content.suffix(content.count - safeCursor))
            
            // ローディング中のカードを作成
            let loadingMsg = "解析中...\n「\(selectedText)」を\(customPrompt.contains("要約") ? "要約" : "解説")しています。"
            let newCard = AICard(text: loadingMsg)
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                elements.remove(at: index)
                elements.insert(.text(id: id, content: prefix), at: index)
                elements.insert(.aiCard(card: newCard), at: index + 1)
                elements.insert(.text(id: UUID(), content: suffix), at: index + 2)
            }
            
            // 💡 APIを呼び出す
            Task {
                await fetchAIResponse(for: newCard, prompt: finalPrompt)
            }
        }
    }
    
    // 💡 API呼び出しとカードの更新
    private func fetchAIResponse(for card: AICard, prompt: String) async {
        let apiService = GeminiAPIService()
        
        do {
            let response = try await apiService.fetchExplanation(prompt: prompt)
            
            // 💡 メインスレッドでUIを更新
            await MainActor.run {
                if let index = elements.firstIndex(where: { $0.id == card.id }) {
                    withAnimation {
                        elements[index] = .aiCard(card: AICard(id: card.id, text: response))
                    }
                }
            }
            
        } catch let error as APIError {
            await MainActor.run {
                if let index = elements.firstIndex(where: { $0.id == card.id }) {
                    withAnimation {
                        let errorMessage = "エラー: \(error.localizedDescription)\n\n設定画面でAPIキーを確認してください。"
                        elements[index] = .aiCard(card: AICard(id: card.id, text: errorMessage))
                    }
                }
            }
        } catch {
            await MainActor.run {
                if let index = elements.firstIndex(where: { $0.id == card.id }) {
                    withAnimation {
                        elements[index] = .aiCard(card: AICard(id: card.id, text: "エラー: \(error.localizedDescription)"))
                    }
                }
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

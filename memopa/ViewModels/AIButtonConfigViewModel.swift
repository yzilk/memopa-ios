//
//  AIButtonConfigViewModel.swift
//  memopa
//
import Foundation
import SwiftUI

@Observable
class AIButtonConfigViewModel {
    var buttons: [AIButtonConfig] = []
    
    private let userDefaultsKey = "ai_button_configs"
    
    init() {
        loadButtons()
    }
    
    func loadButtons() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([AIButtonConfig].self, from: data) {
            buttons = decoded
        } else {
            // デフォルトボタン（6文字以内）
            buttons = [
                AIButtonConfig(name: "💡なに？", prompt: "以下の単語を定義して、初心者向けに分かりやすく解説してください"),
                AIButtonConfig(name: "☁️ゆるふわ", prompt: "以下の内容を、親しみやすい例え話を使って、ゆるい雰囲気で解説してください"),
                AIButtonConfig(name: "🎯要約", prompt: "以下の内容を、一番大切なポイントが伝わるように要約してください")
            ]
        }
    }
    
    func saveButtons() {
        if let encoded = try? JSONEncoder().encode(buttons) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func addButton() {
        let newButton = AIButtonConfig(name: "新ボタン", prompt: "プロンプトを入力してください", isEnabled: false)
        buttons.append(newButton)
        saveButtons()
    }
    
    func deleteButton(at offsets: IndexSet) {
        buttons.remove(atOffsets: offsets)
        saveButtons()
    }
    
    func moveButton(from source: IndexSet, to destination: Int) {
        buttons.move(fromOffsets: source, toOffset: destination)
        saveButtons()
    }
    
    func updateButton(_ button: AIButtonConfig) {
        if let index = buttons.firstIndex(where: { $0.id == button.id }) {
            buttons[index] = button
            saveButtons()
        }
    }
    
    var enabledButtons: [AIButtonConfig] {
        buttons.filter { $0.isEnabled }
    }
}

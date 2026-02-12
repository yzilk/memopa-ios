//
//  AISettings.swift
//  memopa
//


import SwiftUI

// 設定のデフォルト値を一括管理
enum AISettings {
    static let defaultButtons = [
        (name: "💡 ってなに？", prompt: "以下の単語を定義して、初心者向けに分かりやすく解説してください："),
        (name: "☁️ ゆるふわ", prompt: "以下の内容を、親しみやすい例え話を使って、ゆるい雰囲気で解説してください："),
        (name: "🎯 要すると？", prompt: "以下の内容を、一番大切なポイントが伝わるように30文字以内で1行に要約してください：")
    ]
}

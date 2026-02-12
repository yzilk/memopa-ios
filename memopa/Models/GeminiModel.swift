//
//  GeminiModel.swift
//  memopa
//

import Foundation

enum GeminiModel: String, CaseIterable, Identifiable {
    case flashLatest = "gemini-flash-latest"
    case flash25 = "gemini-2.5-flash"
    case flash20 = "gemini-2.0-flash"
    case proLatest = "gemini-pro-latest"
    case pro25 = "gemini-2.5-pro"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .flashLatest:
            return "Gemini Flash (Latest)"
        case .flash25:
            return "Gemini 2.5 Flash"
        case .flash20:
            return "Gemini 2.0 Flash"
        case .proLatest:
            return "Gemini Pro (Latest)"
        case .pro25:
            return "Gemini 2.5 Pro"
        }
    }
    
    var description: String {
        switch self {
        case .flashLatest:
            return "常に最新のFlashモデル（推奨）"
        case .flash25:
            return "高速で低コスト（2025年6月リリース）"
        case .flash20:
            return "高速で低コスト（2025年1月リリース）"
        case .proLatest:
            return "常に最新のProモデル"
        case .pro25:
            return "高性能で複雑な推論に対応"
        }
    }
}

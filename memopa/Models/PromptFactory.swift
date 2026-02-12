//
//  PromptFactory.swift
//  memopa
//
// PromptFactory.swift
import Foundation

// 💡 AIMode は EditorElement.swift で定義されているものを使用するため、ここでは定義しません。

enum PromptFactory {
    static func build(mode: AIMode, targetText: String) -> String {
        let baseInstruction: String
        
        switch mode {
        case .definition:
            baseInstruction = "対象の概念について、辞書的な意味を超えて、その本質が何であるかを「〜とは、◯◯である」という形で明快に定義してください。"
        case .metaphor:
            baseInstruction = "対象の概念を、誰もが知っている身近なもの（パン作り、スポーツ、自然現象など）に例えて、「ゆるふわ」かつ直感的に理解できるように解説してください。"
        case .essence:
            baseInstruction = "対象の概念の核心（コア）を突き、結局のところ何が最も重要なのかを、一言でズバッと要約してください。"
        }
        
        return """
        あなたは親しみやすく知的な解説助手です。
        以下の「対象テキスト」を読み、【指示】に従って解説を出力してください。
        
        【指示】
        \(baseInstruction)
        
        【制約事項】
        ・余計な前置き（「はい、解説します」など）は一切不要です。
        ・回答の本体のみを出力してください。
        ・等幅フォントで表示するため、改行や箇条書きを適切に使って構造化してください。
        ・最後は、理解を促す優しい口調（〜だよ、〜だね）で締めてください。
        
        対象テキスト：
        \(targetText)
        """
    }
}

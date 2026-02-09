//
//  NoteCardView.swift
//  memopa
//
import SwiftUI

struct NoteCardView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.content.isEmpty ? "新規メモ" : note.content.components(separatedBy: .newlines).first ?? "")
                .font(.body)
                .lineLimit(1)
            
            HStack {
                Text(note.dateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(previewText)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var previewText: String {
        let lines = note.content.components(separatedBy: .newlines)
        return lines.count > 1 ? lines[1] : "追加テキストなし"
    }
}

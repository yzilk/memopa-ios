//
//  Untitled.swift
//  memopa
//

import SwiftUI

extension Color {
    static let memoBackground = Color(UIColor.systemGroupedBackground)
    static let memoCardBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let memoAccent = Color.orange 
}

struct MemoCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.memoCardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}



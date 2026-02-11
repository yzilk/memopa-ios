//
//  NoteDetailView.swift
//  memopa
//

import SwiftUI

import SwiftUI

struct MarbleGlassButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 36)
                
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary.opacity(0.8))
            }
        }
        .buttonStyle(.plain)
        .frame(width: 100, height: 36)
    }
}

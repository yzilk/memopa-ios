//
//  AICardView.swift
//  memopa
//
import SwiftUI

struct AICardView: View {
    let text: String
    var onAdopt: () -> Void
    var onDiscard: () -> Void
    
    @State private var offset: CGFloat = 0
    
    var body: some View {
        // 💡 明示的に SwiftUI.Text のイニシャライザであることを明確にする
        Text(text)
        // 💡 font の指定を以下のように修正（.system の戻り値を明示）
            .font(Font.system(.subheadline, design: .monospaced))
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5)
            )
            .padding(.horizontal)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation.width
                    }
                    .onEnded { value in
                        if offset > 100 {
                            withAnimation(.spring()) { onAdopt() }
                        } else if offset < -100 {
                            withAnimation(.spring()) { onDiscard() }
                        } else {
                            withAnimation(.spring()) { offset = 0 }
                        }
                    }
            )
            .overlay(alignment: .trailing) {
                if offset > 20 {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .padding(.trailing, 30)
                        .opacity(Double(offset / 100))
                }
            }
            .overlay(alignment: .leading) {
                if offset < -20 {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                        .padding(.leading, 30)
                        .opacity(Double(-offset / 100))
                }
            }
    }
}

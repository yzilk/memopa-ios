//
//  AIButtonConfigView.swift
//  memopa
//
import SwiftUI

struct AIButtonConfigView: View {
    @State private var viewModel = AIButtonConfigViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach($viewModel.buttons) { $button in
                    NavigationLink {
                        AIButtonEditView(button: $button, onSave: {
                            viewModel.saveButtons()
                        })
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(button.name)
                                    .font(.headline)
                                Text(button.prompt)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Toggle("", isOn: $button.isEnabled)
                                .labelsHidden()
                                .onChange(of: button.isEnabled) { _, _ in
                                    viewModel.saveButtons()
                                }
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteButton)
                .onMove(perform: viewModel.moveButton)
            }
            .navigationTitle("AIボタン設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.addButton()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AIButtonEditView: View {
    @Binding var button: AIButtonConfig
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section {
                TextField("ボタン名", text: $button.name)
            } header: {
                Text("ボタン名")
            } footer: {
                Text("キーボード上に表示される名前です")
            }
            
            Section {
                TextEditor(text: $button.prompt)
                    .frame(minHeight: 150)
            } header: {
                Text("プロンプト")
            } footer: {
                Text("選択したテキストがこのプロンプトの後に追加されます")
            }
            
            Section {
                Toggle("有効", isOn: $button.isEnabled)
            }
        }
        .navigationTitle("ボタン編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    onSave()
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    AIButtonConfigView()
}

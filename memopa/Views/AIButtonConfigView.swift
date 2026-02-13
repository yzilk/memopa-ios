//
//  AIButtonConfigView.swift
//  memopa
//
import SwiftUI

struct AIButtonConfigView: View {
    @State private var viewModel = AIButtonConfigViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showMaxEnabledAlert = false
    
    var body: some View {
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
                            .onChange(of: button.isEnabled) { oldValue, newValue in
                                // 💡 ONにしようとした時に、既に3つONになっていたら拒否
                                if newValue && viewModel.enabledButtons.count > 3 {
                                    button.isEnabled = false
                                    showMaxEnabledAlert = true
                                } else {
                                    viewModel.saveButtons()
                                }
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
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        viewModel.addButton()
                    } label: {
                        Image(systemName: "plus")
                    }
                    
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .alert("制限に達しました", isPresented: $showMaxEnabledAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("同時に有効にできるAIボタンは3つまでです")
        }
    }
}

struct AIButtonEditView: View {
    @Binding var button: AIButtonConfig
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showCharacterLimitAlert = false
    
    var body: some View {
        Form {
            Section {
                TextField("ボタン名", text: $button.name)
                    .onChange(of: button.name) { oldValue, newValue in
                        // 💡 6文字制限
                        if newValue.count > 6 {
                            button.name = String(newValue.prefix(6))
                            showCharacterLimitAlert = true
                        }
                    }
            } header: {
                Text("ボタン名")
            } footer: {
                Text("キーボード上に表示される名前です（最大6文字）")
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
        .alert("文字数制限", isPresented: $showCharacterLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("ボタン名は6文字までです")
        }
    }
}

#Preview {
    AIButtonConfigView()
}

//
//  SettingsView.swift
//  memopa
//

import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - APIキー設定
                Section {
                    SecureField("APIキーを入力", text: $viewModel.apiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    if viewModel.hasAPIKey {
                        Button(role: .destructive, action: {
                            viewModel.deleteAPIKey()
                        }) {
                            Label("APIキーを削除", systemImage: "trash")
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.validateAPIKey()
                        }
                    }) {
                        HStack {
                            Text("APIキーを検証")
                            Spacer()
                            if viewModel.isValidating {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.isValidating || viewModel.apiKey.isEmpty)
                    
                } header: {
                    Text("Gemini API設定")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Google AI StudioでAPIキーを取得してください")
                        Link("APIキーを取得 →", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                            .font(.caption)
                    }
                }
                
                // MARK: - モデル選択
                Section {
                    Picker("モデル", selection: $viewModel.selectedModel) {
                        ForEach(GeminiModel.allCases) { model in
                            VStack(alignment: .leading) {
                                Text(model.displayName)
                                Text(model.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(model)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                } header: {
                    Text("AIモデル")
                } footer: {
                    Text("選択したモデルがAI機能で使用されます")
                }
                
                // MARK: - 情報
                Section {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("アプリ情報")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                }
            }
            .alert("検証結果", isPresented: $viewModel.showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.validationMessage)
            }
        }
    }
}

#Preview {
    SettingsView()
}

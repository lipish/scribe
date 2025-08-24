//
//  AISettingsView.swift
//  Scribe
//
//  Created by AI Assistant on 2024.
//

import SwiftUI

struct AISettingsView: View {
    @StateObject private var aiManager = AIServiceManager()
    @State private var apiKey = ""
    @State private var isShowingAPIKey = false
    @State private var testResult: String?
    @State private var isTesting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("AI 服务配置")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Divider()
            
            // API 密钥配置
            VStack(alignment: .leading, spacing: 12) {
                Text("OpenAI API 密钥")
                    .font(.headline)
                
                Text("请输入您的 OpenAI API 密钥以启用 AI 功能。密钥将安全存储在本地。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Group {
                        if isShowingAPIKey {
                            TextField("sk-...", text: $apiKey)
                        } else {
                            SecureField("sk-...", text: $apiKey)
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                    
                    Button(action: {
                        isShowingAPIKey.toggle()
                    }) {
                        Image(systemName: isShowingAPIKey ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                HStack {
                    Button("保存") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.isEmpty)
                    
                    Button("测试连接") {
                        testConnection()
                    }
                    .disabled(apiKey.isEmpty || isTesting)
                    
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Spacer()
                    
                    if aiManager.isConfigured {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("已配置")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // 测试结果
            if let testResult = testResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text("测试结果")
                        .font(.headline)
                    
                    Text(testResult)
                        .font(.caption)
                        .foregroundColor(testResult.contains("成功") ? .green : .red)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
            }
            
            // 使用说明
            VStack(alignment: .leading, spacing: 8) {
                Text("使用说明")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• 访问 https://platform.openai.com/api-keys 获取 API 密钥")
                    Text("• API 密钥格式通常以 'sk-' 开头")
                    Text("• 确保您的账户有足够的余额")
                    Text("• API 密钥将安全存储在本地，不会上传到服务器")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // 高级设置
            VStack(alignment: .leading, spacing: 8) {
                Text("高级设置")
                    .font(.headline)
                
                HStack {
                    Button("清除配置") {
                        clearConfiguration()
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            loadCurrentAPIKey()
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Private Methods
    private func loadCurrentAPIKey() {
        if let savedKey = UserDefaults.standard.string(forKey: "OpenAI_API_Key") {
            apiKey = savedKey
        }
    }
    
    private func saveAPIKey() {
        guard !apiKey.isEmpty else { return }
        
        aiManager.configure(with: apiKey)
        alertMessage = "API 密钥已保存"
        showingAlert = true
        testResult = nil
    }
    
    private func testConnection() {
        guard !apiKey.isEmpty else { return }
        
        isTesting = true
        testResult = nil
        
        Task {
            do {
                let service = OpenAIService(apiKey: apiKey)
                let response = try await service.generateResponse(for: "Hello, this is a test message. Please respond with 'Test successful'.")
                
                await MainActor.run {
                    testResult = "连接测试成功！响应: \(response.content.prefix(100))..."
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = "连接测试失败: \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
    
    private func clearConfiguration() {
        apiKey = ""
        aiManager.clearAPIKey()
        testResult = nil
        alertMessage = "配置已清除"
        showingAlert = true
    }
}

// MARK: - Preview
struct AISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AISettingsView()
            .frame(width: 600, height: 500)
    }
}
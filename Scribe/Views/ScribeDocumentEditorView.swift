//
//  ScribeDocumentEditorView.swift
//  Scribe
//
//  Created by AI Assistant
//

import SwiftUI
import CoreData

struct ScribeDocumentEditorView: View {
    let document: Document
    @ObservedObject var documentViewModel: DocumentViewModel
    @State private var showingExportSheet = false
    @State private var showingInfoSheet = false
    @State private var editableTitle: String = ""
    @State private var editableContent: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            ScribeEditorToolbar(
                document: document,
                editableTitle: $editableTitle,
                showingExportSheet: $showingExportSheet,
                showingInfoSheet: $showingInfoSheet,
                documentViewModel: documentViewModel
            )
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 编辑器内容
            if document.mode == "jupyter" {
                ScribeJupyterEditorView(
                    document: document,
                    editableContent: $editableContent,
                    documentViewModel: documentViewModel
                )
            } else {
                ScribeNormalEditorView(
                    document: document,
                    editableContent: $editableContent,
                    documentViewModel: documentViewModel
                )
            }
        }
        .onAppear {
            editableTitle = document.title ?? ""
            editableContent = document.content ?? ""
        }
        .sheet(isPresented: $showingExportSheet) {
            ScribeDocumentExportView(document: document, documentViewModel: documentViewModel)
        }
        .sheet(isPresented: $showingInfoSheet) {
            ScribeDocumentInfoSheet(
                document: document,
                documentViewModel: documentViewModel
            )
        }
    }
}

struct ScribeEditorToolbar: View {
    let document: Document
    @Binding var editableTitle: String
    @Binding var showingExportSheet: Bool
    @Binding var showingInfoSheet: Bool
    @ObservedObject var documentViewModel: DocumentViewModel
    
    var body: some View {
        HStack {
            // 标题编辑
            TextField("文档标题", text: $editableTitle)
                .textFieldStyle(.plain)
                .font(.title2)
                .fontWeight(.semibold)
                .onChange(of: editableTitle) { newValue in
                    documentViewModel.updateDocumentContent(document, title: newValue, content: document.content ?? "")
                }
            
            Spacer()
            
            // 收藏按钮
            Button {
                documentViewModel.toggleFavorite(document)
            } label: {
                Image(systemName: document.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(document.isFavorite ? .red : .gray)
            }
            .buttonStyle(.plain)
            
            // 信息按钮
            Button {
                showingInfoSheet = true
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.plain)
            
            // 导出按钮
            Button {
                showingExportSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
        }
    }
}

struct ScribeNormalEditorView: View {
    let document: Document
    @Binding var editableContent: String
    @ObservedObject var documentViewModel: DocumentViewModel
    @State private var showingPreview = false
    
    var body: some View {
        HSplitView {
            // 编辑器
            VStack {
                HStack {
                    Text("编辑")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        showingPreview.toggle()
                    } label: {
                        Image(systemName: showingPreview ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.top)
                
                Divider()
                
                TextEditor(text: $editableContent)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .onChange(of: editableContent) { newValue in
                        documentViewModel.updateDocumentContent(document, title: document.title ?? "", content: newValue)
                    }
            }
            
            // 预览（如果启用）
            if showingPreview {
                VStack {
                    HStack {
                        Text("预览")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Divider()
                    
                    ScrollView {
                        Text(editableContent.isEmpty ? "开始编写您的笔记..." : editableContent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            }
        }
    }
}

struct ScribeJupyterEditorView: View {
    let document: Document
    @Binding var editableContent: String
    @ObservedObject var documentViewModel: DocumentViewModel
    @State private var showingAIAssistant = false
    
    var body: some View {
        HSplitView {
            // 主编辑器
            VStack {
                HStack {
                    Text("Jupyter 编辑器")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        showingAIAssistant.toggle()
                    } label: {
                        Image(systemName: "brain.head.profile")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.top)
                
                TextEditor(text: $editableContent)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .onChange(of: editableContent) { newValue in
                        documentViewModel.updateDocumentContent(document, title: document.title ?? "", content: newValue)
                    }
            }
            
            // AI 助手面板
            if showingAIAssistant {
                ScribeAIAssistantPanel(
                    document: document,
                    editableContent: $editableContent,
                    documentViewModel: documentViewModel
                )
                .frame(minWidth: 300, maxWidth: 400)
            }
        }
    }
}

struct ScribeAIAssistantPanel: View {
    let document: Document
    @Binding var editableContent: String
    @ObservedObject var documentViewModel: DocumentViewModel
    @State private var prompt = ""
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("AI 助手")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                
                TextField("输入您的问题或需求...", text: $prompt)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Button("生成内容") {
                    generateContent()
                }
                .buttonStyle(.borderedProminent)
                .disabled(prompt.isEmpty || isGenerating)
                
                if isGenerating {
                    ProgressView("正在生成...")
                        .padding()
                }
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("完成") {
                        // 关闭面板的逻辑
                    }
                }
            }
        }
    }
    
    private func generateContent() {
        isGenerating = true
        
        // 模拟AI生成内容
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let response = "根据您的需求：\"\(prompt)\"，这里是生成的内容。"
            editableContent += "\n\n" + response
            
            documentViewModel.updateDocumentContent(document, title: document.title ?? "", content: editableContent)
            
            isGenerating = false
            prompt = ""
        }
    }
}

struct ScribeDocumentInfoSheet: View {
    let document: Document
    @ObservedObject var documentViewModel: DocumentViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    LabeledContent("标题", value: document.title ?? "未命名")
                    LabeledContent("类型", value: document.mode == "jupyter" ? "Jupyter" : "Normal")
                    LabeledContent("收藏", value: document.isFavorite ? "是" : "否")
                }
                
                Section("时间信息") {
                    LabeledContent("创建时间", value: (document.createdAt ?? Date()).formatted())
                    LabeledContent("修改时间", value: (document.updatedAt ?? Date()).formatted())
                }
                
                Section("统计信息") {
                    LabeledContent("字符数", value: "\((document.content ?? "").count)")
                    LabeledContent("行数", value: "\((document.content ?? "").components(separatedBy: .newlines).count)")
                }
            }
            .navigationTitle("文档信息")
        }
    }
}

struct ScribeDocumentExportView: View {
    let document: Document
    @ObservedObject var documentViewModel: DocumentViewModel
    @State private var selectedFormat: ExportFormat = .txt
    @State private var isExporting = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("导出文档")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                
                Picker("导出格式", selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue.uppercased())
                            .tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                Button("导出") {
                    exportDocument()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExporting)
                
                if isExporting {
                    ProgressView("正在导出...")
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("导出")
        }
    }
    
    private func exportDocument() {
        isExporting = true
        
        // 模拟导出过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // 这里应该调用实际的导出逻辑
            print("导出文档: \(document.title ?? "未命名") 为 \(selectedFormat.rawValue) 格式")
            isExporting = false
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(context: context)
    document.id = UUID()
    document.title = "示例文档"
    document.content = "这是一个示例文档的内容。"
    document.mode = "normal"
    document.createdAt = Date()
    document.updatedAt = Date()
    document.isFavorite = false
    
    return ScribeDocumentEditorView(
        document: document,
        documentViewModel: DocumentViewModel()
    )
}
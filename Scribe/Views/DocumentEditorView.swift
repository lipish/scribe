//
//  DocumentEditorView.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import SwiftUI
import CoreData
import Foundation

struct DocumentEditorView: View {
    @ObservedObject var document: Document
    @ObservedObject var documentViewModel: DocumentViewModel
    @State private var isEditing = false
    @State private var showingExportSheet = false
    @State private var showingDocumentInfo = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 编辑器工具栏
            EditorToolbar(
                document: document,
                isEditing: $isEditing,
                showingExportSheet: $showingExportSheet,
                showingDocumentInfo: $showingDocumentInfo,
                documentViewModel: documentViewModel
            )
            
            Divider()
            
            // 主编辑区域
            if document.mode == "jupyter" {
                JupyterEditorView(document: document, documentViewModel: documentViewModel)
            } else {
                NormalEditorView(
                    document: document,
                    isEditing: $isEditing,
                    isTextFieldFocused: _isTextFieldFocused,
                    documentViewModel: documentViewModel
                )
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            DocumentExportView(document: document)
        }
        .sheet(isPresented: $showingDocumentInfo) {
            DocumentInfoSheet(document: document, documentViewModel: documentViewModel)
        }
        .onAppear {
            // 自动进入编辑模式
            if !isEditing {
                isEditing = true
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - 编辑器工具栏
struct EditorToolbar: View {
    @ObservedObject var document: Document
    @Binding var isEditing: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingDocumentInfo: Bool
    @ObservedObject var documentViewModel: DocumentViewModel
    
    var body: some View {
        HStack {
            // 文档标题
            if isEditing {
                TextField("文档标题", text: Binding(
                    get: { document.title ?? "" },
                    set: { newValue in
                        document.title = newValue
                        documentViewModel.saveContext()
                    }
                ))
                .textFieldStyle(.plain)
                .font(.title2)
                .fontWeight(.semibold)
            } else {
                Text(document.title ?? "无标题")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .onTapGesture {
                        isEditing = true
                    }
            }
            
            Spacer()
            
            // 文档模式标识
            Text(document.mode?.capitalized ?? "Normal")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(document.mode == "jupyter" ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                .foregroundColor(document.mode == "jupyter" ? .orange : .blue)
                .cornerRadius(6)
            
            // 收藏按钮
            Button(action: {
                documentViewModel.toggleFavorite(document)
            }) {
                Image(systemName: document.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(document.isFavorite ? .red : .secondary)
            }
            .buttonStyle(.plain)
            
            // 更多操作菜单
            Menu {
                Button("文档信息") {
                    showingDocumentInfo = true
                }
                
                Button("导出文档") {
                    showingExportSheet = true
                }
                
                Divider()
                
                Button("复制链接") {
                    // TODO: 实现复制链接功能
                }
                
                Button("分享") {
                    // TODO: 实现分享功能
                }
                
                Divider()
                
                Button("删除文档", role: .destructive) {
                    documentViewModel.deleteDocument(document)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - 普通编辑器视图
struct NormalEditorView: View {
    @ObservedObject var document: Document
    @Binding var isEditing: Bool
    @FocusState var isTextFieldFocused: Bool
    @ObservedObject var documentViewModel: DocumentViewModel
    @State private var showMarkdownPreview = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 编辑器工具栏
            if isEditing {
                HStack {
                    Button(action: {
                        showMarkdownPreview.toggle()
                    }) {
                        HStack {
                            Image(systemName: showMarkdownPreview ? "doc.text" : "eye")
                            Text(showMarkdownPreview ? "编辑" : "预览")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("完成") {
                        isEditing = false
                        isTextFieldFocused = false
                        showMarkdownPreview = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
            }
            
            // 编辑器内容
            if isEditing {
                if showMarkdownPreview {
                    MarkdownPreviewView(content: document.content ?? "")
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            TextEditor(text: Binding(
                                get: { document.content ?? "" },
                                set: { newValue in
                                    document.content = newValue
                                    document.updatedAt = Date()
                                    documentViewModel.saveContext()
                                }
                            ))
                            .focused($isTextFieldFocused)
                            .font(.body)
                            .lineSpacing(4)
                            .frame(minHeight: 400)
                            
                            Spacer(minLength: 100)
                        }
                        .padding()
                    }
                    .background(Color(NSColor.textBackgroundColor))
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(document.content ?? "开始编写您的笔记...")
                            .font(.body)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isEditing = true
                                isTextFieldFocused = true
                            }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                .background(Color(NSColor.textBackgroundColor))
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if !isEditing {
                    Button("编辑") {
                        isEditing = true
                        isTextFieldFocused = true
                    }
                }
            }
        }
    }
}

// MARK: - Markdown 预览视图已在 RichTextEditor.swift 中定义

// MARK: - Jupyter 编辑器视图
struct JupyterEditorView: View {
    let document: Document
    @ObservedObject var documentViewModel: DocumentViewModel
    @State private var showingAIAssistant = false
    @State private var cells: [Cell] = []
    
    var body: some View {
        VStack(spacing: 0) {
            JupyterToolbar(document: document, showingAIAssistant: $showingAIAssistant, documentViewModel: documentViewModel)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(cells, id: \.id) { cell in
                        JupyterCellView(
                            cell: cell,
                            documentViewModel: documentViewModel
                        )
                    }
                }
                .padding()
            }
        }
        .onAppear {
            loadCells()
        }
        .onChange(of: document) { _ in
            loadCells()
        }
        .sheet(isPresented: $showingAIAssistant) {
            AIAssistantPanel(document: document)
        }
    }
    
    private func loadCells() {
        cells = documentViewModel.getCells(for: document)
        // 如果没有单元格，创建一个默认的
        if cells.isEmpty {
            documentViewModel.addCell(to: document, type: "code")
            cells = documentViewModel.getCells(for: document)
        }
    }
    

}

// MARK: - Jupyter 工具栏
struct JupyterToolbar: View {
    let document: Document
    @Binding var showingAIAssistant: Bool
    @ObservedObject var documentViewModel: DocumentViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                documentViewModel.addCell(to: document, type: "code")
            }) {
                Label("添加代码", systemImage: "plus.circle")
            }
            
            Button(action: {
                documentViewModel.addCell(to: document, type: "markdown")
            }) {
                Label("添加文本", systemImage: "text.alignleft")
            }
            
            Spacer()
            
            Button(action: {
                showingAIAssistant = true
            }) {
                Label("AI 助手", systemImage: "brain.head.profile")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Jupyter 单元格视图已在 JupyterCellView.swift 中定义

// MARK: - AI 助手面板
struct AIAssistantPanel: View {
    @ObservedObject var document: Document
    @Environment(\.dismiss) private var dismiss
    @State private var prompt = ""
    @State private var isProcessing = false
    @State private var response = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // AI 助手介绍
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)
                    
                    Text("AI 助手")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("描述您的需求，AI 将为您生成代码或提供建议")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 输入区域
                VStack(alignment: .leading, spacing: 8) {
                    Text("您的需求:")
                        .font(.headline)
                    
                    TextEditor(text: $prompt)
                        .frame(minHeight: 100)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
                
                // 生成按钮
                Button(action: generateResponse) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isProcessing ? "生成中..." : "生成")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(prompt.isEmpty || isProcessing)
                
                // 响应区域
                if !response.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI 响应:")
                            .font(.headline)
                        
                        ScrollView {
                            Text(response)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        
                        Button("插入到文档") {
                            insertResponseToDocument()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("AI 助手")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateResponse() {
        isProcessing = true
        
        // 模拟 AI 响应
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            response = "这是 AI 生成的响应内容，基于您的需求: \"\(prompt)\"\n\n```python\nprint('Hello, World!')\n```\n\n这段代码演示了基本的输出功能。"
            isProcessing = false
        }
    }
    
    private func insertResponseToDocument() {
        let currentContent = document.content ?? ""
        document.content = currentContent + "\n\n" + response
        dismiss()
    }
}

// MARK: - 文档信息表单
struct DocumentInfoSheet: View {
    @ObservedObject var document: Document
    @ObservedObject var documentViewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    HStack {
                        Text("标题")
                        Spacer()
                        Text(document.title ?? "无标题")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("模式")
                        Spacer()
                        Text(document.mode?.capitalized ?? "Normal")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("收藏")
                        Spacer()
                        Text(document.isFavorite ? "是" : "否")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("时间信息") {
                    HStack {
                        Text("创建时间")
                        Spacer()
                        Text(document.createdAt?.formatted() ?? "未知")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("修改时间")
                        Spacer()
                        Text(document.updatedAt?.formatted() ?? "未知")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("统计信息") {
                    HStack {
                        Text("字符数")
                        Spacer()
                        Text("\(document.content?.count ?? 0)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("行数")
                        Spacer()
                        Text("\(document.content?.components(separatedBy: .newlines).count ?? 0)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("文档信息")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}
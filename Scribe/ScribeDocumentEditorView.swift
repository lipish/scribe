//
//  ScribeDocumentEditorView.swift
//  Scribe
//
//  Created by AI Assistant on 2024.
//

import SwiftUI

struct ScribeDocumentEditorView: View {
    let document: Document
    let documentViewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editedTitle: String = ""
    @State private var editedContent: String = ""
    @State private var editedMode: String = "markdown"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标题编辑区
                VStack(alignment: .leading, spacing: 8) {
                    Text("标题")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("输入文档标题...", text: $editedTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title2)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                
                Divider()
                
                // 模式选择
                HStack {
                    Text("模式:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("模式", selection: $editedMode) {
                        Text("Markdown").tag("markdown")
                        Text("富文本").tag("richtext")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 200)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
                
                // 内容编辑区
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("内容")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if editedMode == "markdown" {
                            Text("支持 Markdown 语法")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if #available(macOS 12.0, *) {
                        TextEditor(text: $editedContent)
                            .font(.system(.body, design: editedMode == "markdown" ? .monospaced : .default))
                            .scrollContentBackground(.hidden)
                            .background(Color(.textBackgroundColor))
                    } else {
                        TextEditor(text: $editedContent)
                            .font(.system(.body, design: editedMode == "markdown" ? .monospaced : .default))
                    }
                }
                .padding()
            }
            .navigationTitle("编辑文档")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveDocument()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            loadDocumentData()
        }
    }
    
    private func loadDocumentData() {
        editedTitle = document.title ?? ""
        editedContent = document.content ?? ""
        editedMode = document.mode ?? "markdown"
    }
    
    private func saveDocument() {
        documentViewModel.updateDocumentWithDetails(
            document,
            title: editedTitle.isEmpty ? "无标题" : editedTitle,
            content: editedContent,
            mode: editedMode
        )
    }
}

#Preview {
    ScribeDocumentEditorView(
        document: Document(),
        documentViewModel: DocumentViewModel()
    )
}
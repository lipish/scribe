//
//  DocumentManagementView.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import SwiftUI
import CoreData

struct DocumentManagementView: View {
    @ObservedObject var documentViewModel: DocumentViewModel
    @State private var showingNewDocumentSheet = false
    @State private var showingImportSheet = false
    @State private var selectedDocuments = Set<Document>()
    @State private var showingDeleteAlert = false
    @State private var sortOption: SortOption = .dateModified
    @State private var viewMode: ViewMode = .list
    
    enum SortOption: String, CaseIterable {
        case dateModified = "修改日期"
        case dateCreated = "创建日期"
        case title = "标题"
        case mode = "模式"
        
        var keyPath: KeyPath<Document, Date?> {
            switch self {
            case .dateModified:
                return \.updatedAt
            case .dateCreated:
                return \.createdAt
            default:
                return \.updatedAt
            }
        }
    }
    
    enum ViewMode: String, CaseIterable {
        case list = "列表"
        case grid = "网格"
        
        var icon: String {
            switch self {
            case .list:
                return "list.bullet"
            case .grid:
                return "square.grid.2x2"
            }
        }
    }
    
    var sortedDocuments: [Document] {
        switch sortOption {
        case .title:
            return documentViewModel.documents.sorted { ($0.title ?? "") < ($1.title ?? "") }
        case .mode:
            return documentViewModel.documents.sorted { ($0.mode ?? "") < ($1.mode ?? "") }
        default:
            return documentViewModel.documents.sorted {
                ($0[keyPath: sortOption.keyPath] ?? Date.distantPast) > ($1[keyPath: sortOption.keyPath] ?? Date.distantPast)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            DocumentToolbar(
                sortOption: $sortOption,
                viewMode: $viewMode,
                selectedCount: selectedDocuments.count,
                onNewDocument: { showingNewDocumentSheet = true },
                onImport: { showingImportSheet = true },
                onDeleteSelected: { showingDeleteAlert = true }
            )
            
            Divider()
            
            // 文档视图
            if viewMode == .list {
                DocumentListContentView(
                    documents: sortedDocuments,
                    selectedDocuments: $selectedDocuments,
                    documentViewModel: documentViewModel
                )
            } else {
                DocumentGridView(
                    documents: sortedDocuments,
                    selectedDocuments: $selectedDocuments,
                    documentViewModel: documentViewModel
                )
            }
        }
        .sheet(isPresented: $showingNewDocumentSheet) {
            NewDocumentSheet(documentViewModel: documentViewModel)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportDocumentSheet(documentViewModel: documentViewModel)
        }
        .alert("删除文档", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteSelectedDocuments()
            }
        } message: {
            Text("确定要删除选中的 \(selectedDocuments.count) 个文档吗？此操作无法撤销。")
        }
    }
    
    private func deleteSelectedDocuments() {
        for document in selectedDocuments {
            documentViewModel.deleteDocument(document)
        }
        selectedDocuments.removeAll()
    }
}

// MARK: - 文档工具栏
struct DocumentToolbar: View {
    @Binding var sortOption: DocumentManagementView.SortOption
    @Binding var viewMode: DocumentManagementView.ViewMode
    let selectedCount: Int
    let onNewDocument: () -> Void
    let onImport: () -> Void
    let onDeleteSelected: () -> Void
    
    var body: some View {
        HStack {
            // 新建按钮
            Menu {
                Button("普通笔记", action: onNewDocument)
                Button("Jupyter 笔记", action: onNewDocument)
                Divider()
                Button("导入文档", action: onImport)
            } label: {
                Label("新建", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            // 选中状态信息
            if selectedCount > 0 {
                Text("已选中 \(selectedCount) 个文档")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("删除", action: onDeleteSelected)
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            // 排序选项
            Menu {
                ForEach(DocumentManagementView.SortOption.allCases, id: \.rawValue) { option in
                    Button(option.rawValue) {
                        sortOption = option
                    }
                }
            } label: {
                Label("排序", systemImage: "arrow.up.arrow.down")
            }
            .buttonStyle(.bordered)
            
            // 视图模式切换
            Picker("视图模式", selection: $viewMode) {
                ForEach(DocumentManagementView.ViewMode.allCases, id: \.rawValue) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - 列表视图内容
struct DocumentListContentView: View {
    let documents: [Document]
    @Binding var selectedDocuments: Set<Document>
    @ObservedObject var documentViewModel: DocumentViewModel
    
    var body: some View {
        List(documents, id: \.objectID) { document in
            DocumentListRow(
                document: document,
                isSelected: selectedDocuments.contains(document),
                onToggleSelection: {
                    if selectedDocuments.contains(document) {
                        selectedDocuments.remove(document)
                    } else {
                        selectedDocuments.insert(document)
                    }
                },
                onSelect: {
                    documentViewModel.selectDocument(document)
                }
            )
        }
        .listStyle(.plain)
    }
}

// MARK: - 网格视图
struct DocumentGridView: View {
    let documents: [Document]
    @Binding var selectedDocuments: Set<Document>
    @ObservedObject var documentViewModel: DocumentViewModel
    
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(documents, id: \.self) { document in
                    DocumentGridCard(
                        document: document,
                        isSelected: selectedDocuments.contains(document),
                        onToggleSelection: {
                            if selectedDocuments.contains(document) {
                                selectedDocuments.remove(document)
                            } else {
                                selectedDocuments.insert(document)
                            }
                        },
                        onSelect: {
                            documentViewModel.selectDocument(document)
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - 列表行
struct DocumentListRow: View {
    let document: Document
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            // 选择框
            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            
            // 文档图标
            Image(systemName: document.mode == "jupyter" ? "terminal.fill" : "doc.text.fill")
                .foregroundColor(document.mode == "jupyter" ? .orange : .blue)
                .frame(width: 20)
            
            // 文档信息
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(document.title ?? "无标题")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if document.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Text(document.content?.prefix(100) ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(document.mode?.capitalized ?? "Normal")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(document.updatedAt?.formatted(date: .abbreviated, time: .shortened) ?? "")
                        .font(.caption2)
                        .foregroundColor(Color.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}

// MARK: - 网格卡片
struct DocumentGridCard: View {
    let document: Document
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 头部
            HStack {
                Image(systemName: document.mode == "jupyter" ? "terminal.fill" : "doc.text.fill")
                    .foregroundColor(document.mode == "jupyter" ? .orange : .blue)
                
                Spacer()
                
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
            }
            
            // 标题
            Text(document.title ?? "无标题")
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // 内容预览
            Text(String((document.content ?? "").prefix(150)))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // 底部信息
            HStack {
                Text(document.mode?.capitalized ?? "Normal")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                if document.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Text(document.updatedAt?.formatted(date: .abbreviated, time: .shortened) ?? "")
                .font(.caption2)
                .foregroundColor(Color.secondary)
        }
        .padding()
        .frame(height: 200)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}

// MARK: - 新建文档表单
struct NewDocumentSheet: View {
    @ObservedObject var documentViewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedMode: String = "normal"
    
    var body: some View {
        NavigationView {
            Form {
                Section("文档信息") {
                    TextField("标题", text: $title)
                    
                    Picker("模式", selection: $selectedMode) {
                        Text("普通文档").tag("normal")
                        Text("Jupyter 笔记").tag("jupyter")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("新建文档")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        let documentTitle = title.isEmpty ? "新建文档" : title
                        documentViewModel.createDocument(title: documentTitle, mode: selectedMode)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 导入文档表单
struct ImportDocumentSheet: View {
    @ObservedObject var documentViewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)
                
                Text("导入文档")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("支持导入 Markdown、文本文件等格式")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    Button("选择文件") {
                        // TODO: 实现文件选择逻辑
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("从剪贴板导入") {
                        // TODO: 实现剪贴板导入逻辑
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("导入文档")
            // .navigationBarTitleDisplayMode(.inline) // macOS 不支持
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}
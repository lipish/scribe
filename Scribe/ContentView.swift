//
//  ContentView.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var documentViewModel = DocumentViewModel()
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                SidebarView(
                    documentViewModel: documentViewModel
                )
                .frame(minWidth: 180, idealWidth: 200, maxWidth: 240)
                
                DocumentWaterfallView(
                    documents: documentViewModel.documents,
                    selectedDocument: $documentViewModel.selectedDocument,
                    searchText: $documentViewModel.searchText,
                    documentViewModel: documentViewModel
                )
                .frame(minWidth: 400)
            }
        }
        .onAppear {
            documentViewModel.setViewContext(viewContext)
            documentViewModel.loadDocuments()
        }
    }
}

// MARK: - 侧边栏
struct SidebarView: View {
    let documentViewModel: DocumentViewModel
    @State private var showingNewDocumentSheet = false
    @State private var showingImportSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 标题区域
                HStack {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    Text("Scribe")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // 新建文档按钮
                Button(action: {
                    showingNewDocumentSheet = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("新建文档")
                            .font(.headline)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
                
                // Folders 分组
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Folders")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 4) {
                        SidebarMenuItem(
                            icon: "folder",
                            title: "所有文档",
                            action: {}
                        )
                        
                        SidebarMenuItem(
                            icon: "folder.badge.plus",
                            title: "导入文件",
                            action: { showingImportSheet = true }
                        )
                        
                        SidebarMenuItem(
                            icon: "doc.on.clipboard",
                            title: "从剪贴板导入",
                            action: { importFromClipboard() }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
                
                // Starred 分组
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Starred")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 4) {
                        SidebarMenuItem(
                            icon: "star",
                            title: "收藏夹",
                            action: {}
                        )
                        
                        SidebarMenuItem(
                            icon: "clock",
                            title: "最近使用",
                            action: {}
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
                
                // Tags 分组
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Tags")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 4) {
                        SidebarMenuItem(
                            icon: "tag",
                            title: "标签管理",
                            action: {}
                        )
                        
                        SidebarMenuItem(
                            icon: "number",
                            title: "未分类",
                            action: {}
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
                
                Spacer(minLength: 20)
                
                // 设置区域
                VStack(spacing: 4) {
                    SidebarMenuItem(
                        icon: "gearshape",
                        title: "设置",
                        action: {}
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.controlBackgroundColor))
        .sheet(isPresented: $showingNewDocumentSheet) {
            NewDocumentSheetView(documentViewModel: documentViewModel)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportDocumentSheetView(documentViewModel: documentViewModel)
        }
    }
    
    private func importFromClipboard() {
        documentViewModel.importFromClipboard()
    }
}

// MARK: - 侧边栏菜单项
struct SidebarMenuItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isHovered ? .accentColor : .secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isHovered ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - 瀑布式文档视图
struct DocumentWaterfallView: View {
    let documents: [Document]
    @Binding var selectedDocument: Document?
    @Binding var searchText: String
    let documentViewModel: DocumentViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索文档...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Spacer()
                
                // 视图切换按钮
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "square.grid.2x2")
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {}) {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            
            // 文档卡片瀑布流
            if documents.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    StaggeredGrid(documents: documents, documentViewModel: documentViewModel, selectedDocument: $selectedDocument)
                        .padding()
                }
            }
        }
        .navigationTitle("所有文档")
    }
}

// MARK: - 瀑布流网格
struct StaggeredGrid: View {
    let documents: [Document]
    let documentViewModel: DocumentViewModel
    @Binding var selectedDocument: Document?
    
    private let columnCount = 3
    private let spacing: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            let columnWidth = (geometry.size.width - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount)
            
            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<columnCount, id: \.self) { columnIndex in
                    LazyVStack(spacing: spacing) {
                        ForEach(documentsForColumn(columnIndex)) { document in
                            DocumentCardView(
                                document: document,
                                documentViewModel: documentViewModel,
                                selectedDocument: $selectedDocument
                            )
                            .frame(width: columnWidth)
                        }
                    }
                }
            }
        }
        .frame(height: calculateTotalHeight())
    }
    
    private func documentsForColumn(_ columnIndex: Int) -> [Document] {
        return documents.enumerated().compactMap { index, document in
            index % columnCount == columnIndex ? document : nil
        }
    }
    
    private func calculateTotalHeight() -> CGFloat {
        let maxItemsInColumn = ceil(Double(documents.count) / Double(columnCount))
        return CGFloat(maxItemsInColumn) * 250 + CGFloat(maxItemsInColumn - 1) * spacing
    }
}

// MARK: - 文档卡片视图
struct DocumentCardView: View {
    let document: Document
    let documentViewModel: DocumentViewModel
    @Binding var selectedDocument: Document?
    
    var body: some View {
        NavigationLink(destination: DetailView(selectedDocument: document, documentViewModel: documentViewModel)) {
            VStack(alignment: .leading, spacing: 12) {
                // 卡片头部
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(document.title ?? "无标题")
                            .font(.headline)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.primary)
                        
                        if let updatedAt = document.updatedAt {
                            Text(updatedAt, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 收藏按钮
                    Button(action: {
                        documentViewModel.toggleFavorite(document)
                    }) {
                        Image(systemName: document.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(document.isFavorite ? .red : .secondary)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 文档信息显示
                HStack {
                    Text("文档")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(document.mode == "markdown" ? "Markdown" : "富文本")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 卡片底部
                HStack {
                    // 模式指示器
                    HStack(spacing: 4) {
                        Image(systemName: document.mode == "markdown" ? "doc.text" : "doc.richtext")
                            .font(.caption)
                        Text(document.mode == "markdown" ? "Markdown" : "富文本")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 删除按钮
                    Button(action: {
                        documentViewModel.deleteDocument(document)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
            .frame(minHeight: 180, maxHeight: 300)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separatorColor), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("还没有文档")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("创建您的第一个文档开始使用 Scribe")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.controlBackgroundColor).opacity(0.3))
    }
}

// MARK: - 详情视图
struct DetailView: View {
    let selectedDocument: Document?
    let documentViewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if let document = selectedDocument {
            // 使用实际的文档编辑器视图
            ScribeDocumentEditorView(
                document: document,
                documentViewModel: documentViewModel
            )
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    HStack(spacing: 8) {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                Text("返回")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        } else {
            WelcomeView()
                .navigationTitle("Scribe")
        }
    }
}

// MARK: - 欢迎视图
struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "doc.text")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                VStack(spacing: 8) {
                    Text("欢迎使用 Scribe")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("强大的文档编辑和管理工具")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 16) {
                FeatureCard(
                    icon: "doc.text",
                    title: "智能编辑",
                    description: "支持 Markdown 和富文本编辑",
                    color: .blue
                )
                
                FeatureCard(
                    icon: "brain.head.profile",
                    title: "AI 助手",
                    description: "集成 AI 功能，提升写作效率",
                    color: .purple
                )
                
                FeatureCard(
                    icon: "square.grid.3x3",
                    title: "多格式支持",
                    description: "支持多种文档格式和导入导出",
                    color: .orange
                )
            }
            .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.controlBackgroundColor).opacity(0.3))
    }
}

// MARK: - 功能卡片
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}







#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
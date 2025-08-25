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
    @StateObject private var documentViewModel = DocumentViewModel()
    @State private var selectedDocument: Document?
    @State private var showingNewDocumentSheet = false
    @State private var showingImportSheet = false
    @State private var searchText = ""
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var filteredDocuments: [Document] {
        documentViewModel.searchText = searchText
        return documentViewModel.filteredDocuments
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 侧边栏
            SidebarView(
                showingNewDocumentSheet: $showingNewDocumentSheet,
                showingImportSheet: $showingImportSheet
            )
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } content: {
            // 文档列表
            DocumentListView(
                documents: filteredDocuments,
                selectedDocument: $selectedDocument,
                searchText: $searchText,
                documentViewModel: documentViewModel
            )
            .navigationSplitViewColumnWidth(min: 400, ideal: 500, max: 600)
        } detail: {
            // 详情视图
            DetailView(selectedDocument: selectedDocument, documentViewModel: documentViewModel)
                .navigationSplitViewColumnWidth(min: 600, ideal: 800, max: 1200)
        }
        .sheet(isPresented: $showingNewDocumentSheet) {
            NewDocumentSheetView(documentViewModel: documentViewModel)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportDocumentSheetView(documentViewModel: documentViewModel)
        }
        .onAppear {
            documentViewModel.loadDocuments()
        }
    }
}

// MARK: - 侧边栏
struct SidebarView: View {
    @Binding var showingNewDocumentSheet: Bool
    @Binding var showingImportSheet: Bool
    
    var body: some View {
        VStack(spacing: 0) {
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
            .padding(.vertical, 16)
            
            Divider()
            
            // 操作按钮区域
            VStack(spacing: 16) {
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
                
                // 导入按钮组
                VStack(spacing: 8) {
                    Button(action: {
                        showingImportSheet = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title3)
                            Text("导入文件")
                                .font(.subheadline)
                            Spacer()
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.controlBackgroundColor))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        importFromClipboard()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.title3)
                            Text("从剪贴板导入")
                                .font(.subheadline)
                            Spacer()
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.controlBackgroundColor))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            
            Divider()
            
            // 导航区域
            VStack(alignment: .leading, spacing: 8) {
                NavigationLink(destination: EmptyView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.title3)
                        Text("所有文档")
                            .font(.subheadline)
                        Spacer()
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: EmptyView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "heart")
                            .font(.title3)
                        Text("收藏夹")
                            .font(.subheadline)
                        Spacer()
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: EmptyView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.title3)
                        Text("最近使用")
                            .font(.subheadline)
                        Spacer()
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 16)
            
            Spacer()
            
            Divider()
            
            // 设置区域
            VStack(spacing: 8) {
                NavigationLink(destination: EmptyView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                        Text("设置")
                            .font(.subheadline)
                        Spacer()
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 16)
        }
        .background(Color(.controlBackgroundColor))
    }
    
    private func importFromClipboard() {
        // TODO: 实现剪贴板导入逻辑
        print("从剪贴板导入功能待实现")
    }
}

// MARK: - 文档列表
struct DocumentListView: View {
    let documents: [Document]
    @Binding var selectedDocument: Document?
    @Binding var searchText: String
    let documentViewModel: DocumentViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索文档...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            // 文档列表
            if documents.isEmpty {
                EmptyStateView()
            } else {
                List(documents, id: \.id, selection: $selectedDocument) { document in
                    DocumentRowView(document: document, documentViewModel: documentViewModel)
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                        .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("文档")
    }
}

// MARK: - 文档行视图
struct DocumentRowView: View {
    let document: Document
    let documentViewModel: DocumentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text((document.title?.isEmpty ?? true) ? "无标题" : (document.title ?? ""))
                        .font(.headline)
                        .lineLimit(1)
                    
                    if !(document.content?.isEmpty ?? true) {
                        Text(document.content ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        Text(document.updatedAt ?? Date(), style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if document.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Text(document.mode == "jupyter" ? "Jupyter" : "普通")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(document.mode == "jupyter" ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                            )
                            .foregroundColor(document.mode == "jupyter" ? .orange : .blue)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    toggleFavorite()
                }) {
                    Image(systemName: document.isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(document.isFavorite ? .red : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
        .contextMenu {
            Button(action: {
                toggleFavorite()
            }) {
                Label(document.isFavorite ? "取消收藏" : "添加到收藏", systemImage: document.isFavorite ? "heart.slash" : "heart")
            }
            
            Button(action: {
                deleteDocument()
            }) {
                Label("删除", systemImage: "trash")
            }
        }
    }
    
    private func toggleFavorite() {
        documentViewModel.toggleFavorite(document)
    }
    
    private func deleteDocument() {
        documentViewModel.deleteDocument(document)
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
    
    var body: some View {
        if let document = selectedDocument {
            ScribeDocumentEditorView(document: document, documentViewModel: documentViewModel)
                .navigationTitle((document.title?.isEmpty ?? true) ? "无标题" : (document.title ?? ""))
        } else {
            WelcomeView()
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
                    title: "Jupyter 支持",
                    description: "支持 Jupyter 笔记本格式",
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
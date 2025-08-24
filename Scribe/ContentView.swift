//
//  ContentView.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var documentViewModel = DocumentViewModel()
    @State private var selectedSidebarItem: SidebarItem? = .allDocuments
    
    enum SidebarItem: String, CaseIterable, Identifiable {
        case allDocuments = "所有文档"
        case favorites = "收藏夹"
        case recent = "最近使用"
        case normal = "普通模式"
        case jupyter = "Jupyter 模式"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .allDocuments:
                return "doc.text.fill"
            case .favorites:
                return "heart.fill"
            case .recent:
                return "clock.fill"
            case .normal:
                return "doc.text"
            case .jupyter:
                return "terminal.fill"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // 侧边栏
            SidebarView(selectedItem: $selectedSidebarItem, documentViewModel: documentViewModel)
        } content: {
            // 文档列表
            DocumentListView(selectedSidebarItem: selectedSidebarItem, documentViewModel: documentViewModel)
        } detail: {
            // 主编辑区域
            if let selectedDocument = documentViewModel.selectedDocument {
                DocumentEditorView(document: selectedDocument, documentViewModel: documentViewModel)
            } else {
                WelcomeView(documentViewModel: documentViewModel)
            }
        }
        .environmentObject(documentViewModel)
        .onAppear {
            documentViewModel.fetchDocuments()
        }
    }
}

// MARK: - 侧边栏视图
struct SidebarView: View {
    @Binding var selectedItem: ContentView.SidebarItem?
    @ObservedObject var documentViewModel: DocumentViewModel
    @State private var showingAISettings = false
    
    var body: some View {
        List(selection: $selectedItem) {
            Section("文档") {
                ForEach(ContentView.SidebarItem.allCases.prefix(3), id: \.id) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .tag(item)
                }
            }
            
            Section("模式") {
                ForEach(ContentView.SidebarItem.allCases.suffix(2), id: \.id) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .tag(item)
                }
            }
            
            Section("设置") {
                Button(action: {
                    showingAISettings = true
                }) {
                    Label("AI 设置", systemImage: "brain")
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Scribe")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    documentViewModel.createNewDocument()
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAISettings) {
            AISettingsView()
        }
    }
}

// MARK: - 文档列表视图
struct DocumentListView: View {
    let selectedSidebarItem: ContentView.SidebarItem?
    @ObservedObject var documentViewModel: DocumentViewModel
    
    var body: some View {
        DocumentManagementView(documentViewModel: documentViewModel)
            .navigationTitle(selectedSidebarItem?.rawValue ?? "文档")
    }
}

// MARK: - 文档行视图
struct DocumentRowView: View {
    let document: Document
    @ObservedObject var documentViewModel: DocumentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
                
                Image(systemName: document.mode == "jupyter" ? "terminal" : "doc.text")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            Text(document.content?.prefix(100) ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(document.updatedAt?.formatted(date: .abbreviated, time: .shortened) ?? "")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            documentViewModel.selectDocument(document)
        }
        .contextMenu {
            Button(document.isFavorite ? "取消收藏" : "添加收藏") {
                documentViewModel.toggleFavorite(document)
            }
            
            Divider()
            
            Button("删除", role: .destructive) {
                documentViewModel.deleteDocument(document)
            }
        }
    }
}

// MARK: - 欢迎视图
struct WelcomeView: View {
    @ObservedObject var documentViewModel: DocumentViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("欢迎使用 Scribe")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("智能笔记应用，支持普通模式和 Jupyter AI 模式")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("创建普通笔记") {
                    documentViewModel.createNewDocument(mode: DocumentViewModel.DocumentMode.normal)
                }
                .buttonStyle(.borderedProminent)
                
                Button("创建 Jupyter 笔记") {
                    documentViewModel.createNewDocument(mode: DocumentViewModel.DocumentMode.jupyter)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

// DocumentEditorView 已移动到单独的文件

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
//
//  DocumentViewModel.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import Foundation
import SwiftUI
import AppKit
import CoreData

// 文档视图模型
class DocumentViewModel: ObservableObject {
    @Published var documents: [Document] = []
    @Published var selectedDocument: Document?
    @Published var searchText: String = ""
    @Published var sortOrder: SortOrder = .dateModified
    @Published var viewMode: ViewMode = .list
    
    private var viewContext: NSManagedObjectContext?
    
    enum SortOrder {
        case dateModified
        case dateCreated
        case title
        case mode
    }
    
    enum ViewMode {
        case list
        case grid
    }
    
    init(context: NSManagedObjectContext? = nil) {
        self.viewContext = context
        if context != nil {
            loadDocuments()
        }
    }
    
    func setViewContext(_ context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    func loadDocuments() {
        guard let context = viewContext else { return }
        
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)]
        
        do {
            documents = try context.fetch(request)
        } catch {
            print("加载文档失败: \(error)")
            documents = []
        }
    }
    
    func createDocument() {
        guard let context = viewContext else { return }
        
        let newDocument = Document(context: context)
        newDocument.id = UUID()
        newDocument.title = "新建文档"
        newDocument.content = ""
        newDocument.mode = "normal"
        newDocument.createdAt = Date()
        newDocument.updatedAt = Date()
        newDocument.isFavorite = false
        
        do {
            try context.save()
            loadDocuments()
            selectedDocument = newDocument
        } catch {
            print("创建文档失败: \(error)")
        }
    }
    
    func createDocument(title: String) {
        guard let context = viewContext else { return }
        
        let newDocument = Document(context: context)
        newDocument.id = UUID()
        newDocument.title = title
        newDocument.content = ""
        newDocument.mode = "normal"
        newDocument.createdAt = Date()
        newDocument.updatedAt = Date()
        newDocument.isFavorite = false
        
        do {
            try context.save()
            loadDocuments()
            selectedDocument = newDocument
        } catch {
            print("创建文档失败: \(error)")
        }
    }
    
    func importFromClipboard() {
        guard let context = viewContext else { return }
        
        let pasteboard = NSPasteboard.general
        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            let newDocument = Document(context: context)
            newDocument.id = UUID()
            newDocument.title = "从剪贴板导入"
            newDocument.content = content
            newDocument.mode = "normal"
            newDocument.createdAt = Date()
            newDocument.updatedAt = Date()
            newDocument.isFavorite = false
            
            do {
                try context.save()
                loadDocuments()
                selectedDocument = newDocument
            } catch {
                print("导入剪贴板内容失败: \(error)")
            }
        }
    }
    
    func importFromFile(url: URL) {
        guard let context = viewContext else { return }
        
        do {
            let content = try String(contentsOf: url)
            let title = url.deletingPathExtension().lastPathComponent
            
            let newDocument = Document(context: context)
            newDocument.id = UUID()
            newDocument.title = title
            newDocument.content = content
            newDocument.mode = "normal"
            newDocument.createdAt = Date()
            newDocument.updatedAt = Date()
            newDocument.isFavorite = false
            
            try context.save()
            loadDocuments()
            selectedDocument = newDocument
        } catch {
            print("导入文件失败: \(error)")
        }
    }
    
    func deleteDocument(_ document: Document) {
        guard let context = viewContext else { return }
        
        context.delete(document)
        
        do {
            try context.save()
            loadDocuments()
            if selectedDocument?.objectID == document.objectID {
                selectedDocument = documents.first
            }
        } catch {
            print("删除文档失败: \(error)")
        }
    }
    
    func toggleFavorite(_ document: Document) {
        guard let context = viewContext else { return }
        
        document.isFavorite.toggle()
        document.updatedAt = Date()
        
        do {
            try context.save()
            loadDocuments()
        } catch {
            print("更新收藏状态失败: \(error)")
        }
    }
    
    func updateDocument(_ document: Document) {
        guard let context = viewContext else { return }
        
        document.updatedAt = Date()
        
        do {
            try context.save()
            loadDocuments()
        } catch {
            print("更新文档失败: \(error)")
        }
    }
    
    func selectDocument(_ document: Document) {
        selectedDocument = document
    }
    

    
    func saveContext() {
        guard let context = viewContext else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    func updateDocumentContent(_ document: Document, title: String, content: String) {
        guard let context = viewContext else { return }
        
        document.title = title
        document.content = content
        document.updatedAt = Date()
        
        do {
            try context.save()
            loadDocuments()
        } catch {
            print("更新文档失败: \(error)")
        }
    }
    
    // 支持富文本格式保存的方法
    func updateDocumentWithRichText(_ document: Document, title: String, content: String, rtfData: Data? = nil) {
        guard let context = viewContext else { return }
        
        document.title = title
        document.content = content
        // 如果有RTF数据，可以保存到额外的字段中
        // document.richTextData = rtfData
        document.updatedAt = Date()
        
        do {
            try context.save()
            loadDocuments()
        } catch {
            print("更新富文档失败: \(error)")
        }
    }
    
    func updateDocumentWithDetails(_ document: Document, title: String, content: String) {
        guard let context = viewContext else { return }
        
        document.title = title
        document.content = content
        document.mode = "normal"
        document.updatedAt = Date()
        
        do {
            try context.save()
            loadDocuments()
        } catch {
            print("更新文档失败: \(error)")
        }
    }
    
    var filteredDocuments: [Document] {
        let filtered = searchText.isEmpty ? documents : documents.filter {
            $0.title?.localizedCaseInsensitiveContains(searchText) == true ||
            $0.content?.localizedCaseInsensitiveContains(searchText) == true
        }
        
        return filtered.sorted { doc1, doc2 in
            switch sortOrder {
            case .dateModified:
                return (doc1.updatedAt ?? Date.distantPast) > (doc2.updatedAt ?? Date.distantPast)
            case .dateCreated:
                return (doc1.createdAt ?? Date.distantPast) > (doc2.createdAt ?? Date.distantPast)
            case .title:
                return (doc1.title ?? "") < (doc2.title ?? "")
            case .mode:
                return (doc1.mode ?? "normal") < (doc2.mode ?? "normal")
            }
        }
    }
}
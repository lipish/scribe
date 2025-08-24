//
//  Persistence.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // 创建示例数据
        let sampleDocument = Document(context: viewContext)
        sampleDocument.id = UUID()
        sampleDocument.title = "欢迎使用 Scribe"
        sampleDocument.content = "这是您的第一个笔记文档。您可以在普通模式下编写文字，或切换到 Jupyter 模式体验 AI 助手功能。"
        sampleDocument.mode = "normal"
        sampleDocument.createdAt = Date()
        sampleDocument.updatedAt = Date()
        sampleDocument.isFavorite = false
        
        let sampleCell = Cell(context: viewContext)
        sampleCell.id = UUID()
        sampleCell.input = "什么是人工智能？\n\n人工智能（AI）是计算机科学的一个分支，致力于创建能够执行通常需要人类智能的任务的系统。"
        sampleCell.cellType = "text"
        sampleCell.orderIndex = 0
        sampleCell.createdAt = Date()
        sampleCell.updatedAt = Date()
        sampleCell.document = sampleDocument
        
        do {
            try viewContext.save()
        } catch {
            // 在预览环境中，错误处理可以简化
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Scribe")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // 在生产环境中，应该有更好的错误处理
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// MARK: - Core Data 扩展
extension PersistenceController {
    
    /// 保存上下文
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("保存失败: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    /// 创建新文档
    func createDocument(title: String, content: String = "", mode: String = "normal") -> Document {
        let context = container.viewContext
        let document = Document(context: context)
        
        document.id = UUID()
        document.title = title
        document.content = content
        document.mode = mode
        document.createdAt = Date()
        document.updatedAt = Date()
        document.isFavorite = false
        
        save()
        return document
    }
    
    /// 删除文档
    func deleteDocument(_ document: Document) {
        let context = container.viewContext
        context.delete(document)
        save()
    }
}
//
//  DocumentViewModel.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import Foundation
import CoreData
import Combine
import SwiftUI

class DocumentViewModel: ObservableObject {
    @Published var documents: [Document] = []
    @Published var selectedDocument: Document?
    @Published var searchText = ""
    @Published var selectedMode: DocumentMode = .normal
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let persistenceController: PersistenceController
    private var cancellables = Set<AnyCancellable>()
    
    enum DocumentMode: String, CaseIterable {
        case normal = "normal"
        case jupyter = "jupyter"
        
        var displayName: String {
            switch self {
            case .normal:
                return "普通模式"
            case .jupyter:
                return "Jupyter 模式"
            }
        }
        
        var icon: String {
            switch self {
            case .normal:
                return "doc.text"
            case .jupyter:
                return "terminal"
            }
        }
    }
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        setupSearchSubscription()
        fetchDocuments()
    }
    
    // MARK: - 文档管理
    
    func fetchDocuments() {
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)]
        
        do {
            documents = try persistenceController.container.viewContext.fetch(request)
        } catch {
            errorMessage = "获取文档失败: \(error.localizedDescription)"
        }
    }
    
    func createNewDocument(title: String = "新建文档", mode: DocumentMode = .normal) {
        let document = persistenceController.createDocument(title: title, mode: mode.rawValue)
        documents.insert(document, at: 0)
        selectedDocument = document
        
        // 如果是 Jupyter 模式，创建一个默认的单元格
        if mode == .jupyter {
            createDefaultCell(for: document)
        }
    }
    
    private func createDefaultCell(for document: Document) {
        let context = persistenceController.container.viewContext
        let cell = Cell(context: context)
        cell.id = UUID()
        cell.cellType = "code"
        cell.input = ""
        cell.output = ""
        cell.orderIndex = 0
        cell.createdAt = Date()
        cell.updatedAt = Date()
        cell.document = document
        persistenceController.save()
    }
    
    func deleteDocument(_ document: Document) {
        persistenceController.deleteDocument(document)
        documents.removeAll { $0.id == document.id }
        
        if selectedDocument?.id == document.id {
            selectedDocument = documents.first
        }
    }
    
    func updateDocument(_ document: Document, title: String? = nil, content: String? = nil) {
        if let title = title {
            document.title = title
        }
        if let content = content {
            document.content = content
        }
        document.updatedAt = Date()
        persistenceController.save()
    }
    
    func toggleFavorite(_ document: Document) {
        document.isFavorite.toggle()
        document.updatedAt = Date()
        persistenceController.save()
    }
    
    func switchDocumentMode(_ document: Document, to mode: DocumentMode) {
        document.mode = mode.rawValue
        document.updatedAt = Date()
        persistenceController.save()
        selectedMode = mode
    }
    
    // MARK: - 搜索功能
    
    private func setupSearchSubscription() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.performSearch(searchText)
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(_ searchText: String) {
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        
        if searchText.isEmpty {
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)]
        } else {
            request.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", searchText, searchText)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)]
        }
        
        do {
            documents = try persistenceController.container.viewContext.fetch(request)
        } catch {
            errorMessage = "搜索失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 文档选择
    
    func selectDocument(_ document: Document) {
        selectedDocument = document
        selectedMode = DocumentMode(rawValue: document.mode ?? "normal") ?? .normal
    }
    
    // MARK: - 过滤功能
    
    var filteredDocuments: [Document] {
        if searchText.isEmpty {
            return documents
        } else {
            return documents.filter { document in
                document.title?.localizedCaseInsensitiveContains(searchText) == true ||
                document.content?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var favoriteDocuments: [Document] {
        return documents.filter { $0.isFavorite }
    }
    
    var recentDocuments: [Document] {
        return Array(documents.prefix(5))
    }
}

// MARK: - 文档统计
extension DocumentViewModel {
    var totalDocuments: Int {
        documents.count
    }
    
    var favoriteCount: Int {
        favoriteDocuments.count
    }
    
    var normalModeCount: Int {
        documents.filter { $0.mode == "normal" }.count
    }
    
    var jupyterModeCount: Int {
        documents.filter { $0.mode == "jupyter" }.count
    }
}

// MARK: - Jupyter 单元格管理
extension DocumentViewModel {
    
    func getCells(for document: Document) -> [Cell] {
        let request: NSFetchRequest<Cell> = Cell.fetchRequest()
        request.predicate = NSPredicate(format: "document == %@", document)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Cell.orderIndex, ascending: true)]
        
        do {
            return try persistenceController.container.viewContext.fetch(request)
        } catch {
            errorMessage = "获取单元格失败: \(error.localizedDescription)"
            return []
        }
    }
    
    func addCell(to document: Document, type: String = "code", at index: Int? = nil) {
        let context = persistenceController.container.viewContext
        let cell = Cell(context: context)
        cell.id = UUID()
        cell.cellType = type
        cell.input = ""
        cell.output = ""
        cell.createdAt = Date()
        cell.updatedAt = Date()
        cell.document = document
        
        let cells = getCells(for: document)
        if let index = index {
            cell.orderIndex = Int32(index)
            // 更新后续单元格的顺序
            for (i, existingCell) in cells.enumerated() {
                if i >= index {
                    existingCell.orderIndex = Int32(i + 1)
                }
            }
        } else {
            cell.orderIndex = Int32(cells.count)
        }
        
        persistenceController.save()
    }
    
    func deleteCell(_ cell: Cell) {
        guard let document = cell.document else { return }
        let context = persistenceController.container.viewContext
        
        // 获取要删除的单元格的顺序
        let deletedOrder = cell.orderIndex
        
        // 删除单元格
        context.delete(cell)
        
        // 更新后续单元格的顺序
        let cells = getCells(for: document)
        for existingCell in cells {
            if existingCell.orderIndex > deletedOrder {
                existingCell.orderIndex -= 1
            }
        }
        
        persistenceController.save()
    }
    
    func moveCellUp(_ cell: Cell) {
        guard let document = cell.document, cell.orderIndex > 0 else { return }
        
        let cells = getCells(for: document)
        if let previousCell = cells.first(where: { $0.orderIndex == cell.orderIndex - 1 }) {
            let tempOrder = cell.orderIndex
            cell.orderIndex = previousCell.orderIndex
            previousCell.orderIndex = tempOrder
            persistenceController.save()
        }
    }
    
    func moveCellDown(_ cell: Cell) {
        guard let document = cell.document else { return }
        
        let cells = getCells(for: document)
        if let nextCell = cells.first(where: { $0.orderIndex == cell.orderIndex + 1 }) {
            let tempOrder = cell.orderIndex
            cell.orderIndex = nextCell.orderIndex
            nextCell.orderIndex = tempOrder
            persistenceController.save()
        }
    }
    
    func duplicateCell(_ cell: Cell) {
        guard let document = cell.document else { return }
        
        let context = persistenceController.container.viewContext
        let newCell = Cell(context: context)
        newCell.id = UUID()
        newCell.cellType = cell.cellType
        newCell.input = cell.input
        newCell.output = ""
        newCell.createdAt = Date()
        newCell.updatedAt = Date()
        newCell.document = document
        
        // 在原单元格后面插入
        let cells = getCells(for: document)
        newCell.orderIndex = cell.orderIndex + 1
        
        // 更新后续单元格的顺序
        for existingCell in cells {
            if existingCell.orderIndex > cell.orderIndex {
                existingCell.orderIndex += 1
            }
        }
        
        persistenceController.save()
    }
    
    func insertCellAbove(_ cell: Cell) {
        guard let document = cell.document else { return }
        addCell(to: document, type: "code", at: Int(cell.orderIndex))
    }
    
    func insertCellBelow(_ cell: Cell) {
        guard let document = cell.document else { return }
        addCell(to: document, type: "code", at: Int(cell.orderIndex + 1))
    }
    
    func updateCellContent(_ cell: Cell, content: String) {
        cell.input = content
        cell.updatedAt = Date()
        persistenceController.save()
    }
    
    func updateCellOutput(_ cell: Cell, output: String) {
        cell.output = output
        cell.updatedAt = Date()
        persistenceController.save()
    }
    
    func saveContext() {
        persistenceController.save()
    }
}
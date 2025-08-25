//
//  NewDocumentSheetView.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import SwiftUI
import CoreData

struct NewDocumentSheetView: View {
    @ObservedObject var documentViewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var title = ""
    @State private var selectedMode = "normal"
    
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
                        createDocument()
                    }
                }
            }
        }
    }
    
    private func createDocument() {
        let newDocument = Document(context: viewContext)
        newDocument.id = UUID()
        newDocument.title = title.isEmpty ? "新建文档" : title
        newDocument.content = ""
        newDocument.mode = selectedMode
        newDocument.createdAt = Date()
        newDocument.updatedAt = Date()
        newDocument.isFavorite = false
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("创建文档失败: \(error)")
        }
    }
}

#Preview {
    NewDocumentSheetView(documentViewModel: DocumentViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
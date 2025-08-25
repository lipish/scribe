//
//  ImportDocumentSheetView.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import SwiftUI
import CoreData
import AppKit

struct ImportDocumentSheetView: View {
    @ObservedObject var documentViewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                VStack(spacing: 8) {
                    Text("导入文档")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("支持导入 Markdown、文本文件等格式")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    Button(action: {
                        showingFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("选择文件")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        importFromClipboard()
                    }) {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                            Text("从剪贴板导入")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .navigationTitle("导入文档")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.plainText, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importFromFile(url: url)
                }
            case .failure(let error):
                print("文件选择失败: \(error)")
            }
        }
    }
    
    private func importFromFile(url: URL) {
        do {
            let content = try String(contentsOf: url)
            let title = url.deletingPathExtension().lastPathComponent
            let mode = url.pathExtension.lowercased() == "ipynb" ? "jupyter" : "normal"
            
            let newDocument = Document(context: viewContext)
            newDocument.id = UUID()
            newDocument.title = title
            newDocument.content = content
            newDocument.mode = mode
            newDocument.createdAt = Date()
            newDocument.updatedAt = Date()
            newDocument.isFavorite = false
            
            try viewContext.save()
            dismiss()
        } catch {
            print("导入文件失败: \(error)")
        }
    }
    
    private func importFromClipboard() {
        let pasteboard = NSPasteboard.general
        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            let newDocument = Document(context: viewContext)
            newDocument.id = UUID()
            newDocument.title = "从剪贴板导入"
            newDocument.content = content
            newDocument.mode = "normal"
            newDocument.createdAt = Date()
            newDocument.updatedAt = Date()
            newDocument.isFavorite = false
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                print("从剪贴板导入失败: \(error)")
            }
        }
    }
}

#Preview {
    ImportDocumentSheetView(documentViewModel: DocumentViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
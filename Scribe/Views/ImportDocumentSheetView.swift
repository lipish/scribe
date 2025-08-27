//
//  ImportDocumentSheetView.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import SwiftUI
import CoreData
import AppKit
import UniformTypeIdentifiers

struct ImportDocumentSheetView: View {
    @ObservedObject var documentViewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingFilePicker = false
    @State private var showingDirectoryPicker = false
    @State private var importType: ImportType = .file
    
    enum ImportType {
        case file
        case directory
    }
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.97),
                    Color(red: 0.92, green: 0.92, blue: 0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 60)
                
                // 主要内容区域
                VStack(spacing: 32) {
                    
                    // 图标和标题
                    VStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.accentColor)
                        
                        Text("导入文档")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    // 操作按钮区域
                    VStack(spacing: 16) {
                        // 导入单个 Markdown 文件
                        Button(action: {
                            importType = .file
                            showingFilePicker = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 32, height: 32)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("导入文件")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text("选择单个文件进行导入")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 导入 Markdown 文件目录
                        Button(action: {
                            importType = .directory
                            showingDirectoryPicker = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "folder")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 32, height: 32)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("导入目录")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text("批量导入目录中的所有文件")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 40)
                    
                    // 按钮区域
                    HStack {
                        Spacer()
                        // 取消按钮
                        Button(action: {
                            dismiss()
                        }) {
                            Text("取消")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    
                }
                
                Spacer()
            }
        }
        .frame(width: 480, height: 520)
        .background(Color.clear)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "md") ?? .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importFromFile(url: url)
                }
            case .failure(let error):
                print("Markdown文件选择失败: \(error)")
            }
        }
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importFromDirectory(url: url)
                }
            case .failure(let error):
                print("目录选择失败: \(error)")
            }
        }
    }
    
    private func importFromFile(url: URL) {
        documentViewModel.importFromFile(url: url)
        dismiss()
    }
    
    private func importFromDirectory(url: URL) {
        // 扫描目录中的所有.md文件
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            print("无法访问目录: \(url)")
            return
        }
        
        var importedCount = 0
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension.lowercased() == "md" {
                documentViewModel.importFromFile(url: fileURL)
                importedCount += 1
            }
        }
        
        print("成功导入 \(importedCount) 个Markdown文件")
        dismiss()
    }
}

#Preview {
    ImportDocumentSheetView(documentViewModel: DocumentViewModel())
}
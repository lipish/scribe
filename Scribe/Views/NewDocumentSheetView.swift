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
    @State private var selectedMode: DocumentMode = .normal
    
    enum DocumentMode: String, CaseIterable {
        case normal = "普通文档"
        case jupyter = "Jupyter 笔记"
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
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.accentColor)
                        
                        Text("新建文档")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    // 表单区域
                    VStack(spacing: 24) {
                        // 标题输入框
                        VStack(alignment: .leading, spacing: 8) {
                            Text("文档标题")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextField("请输入文档标题", text: $title)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        
                        // 模式选择
                        VStack(alignment: .leading, spacing: 8) {
                            Text("文档模式")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                // 普通文档按钮
                                Button(action: {
                                    selectedMode = .normal
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "doc.text")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("普通文档")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(selectedMode == .normal ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedMode == .normal ? Color.accentColor : Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedMode == .normal ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .shadow(color: .black.opacity(selectedMode == .normal ? 0.1 : 0.05), radius: 2, x: 0, y: 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Jupyter笔记按钮
                                Button(action: {
                                    selectedMode = .jupyter
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "book")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Jupyter 笔记")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(selectedMode == .jupyter ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedMode == .jupyter ? Color.orange : Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedMode == .jupyter ? Color.orange : Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .shadow(color: .black.opacity(selectedMode == .jupyter ? 0.1 : 0.05), radius: 2, x: 0, y: 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // 按钮区域
                    HStack(spacing: 16) {
                        // 取消按钮
                        Button(action: {
                            dismiss()
                        }) {
                            Text("取消")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 创建按钮
                        Button(action: {
                            createDocument()
                        }) {
                            Text("创建")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            title.isEmpty ? Color.gray.opacity(0.6) : Color.accentColor,
                                            title.isEmpty ? Color.gray.opacity(0.4) : Color.accentColor.opacity(0.8)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: title.isEmpty ? .clear : .accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(title.isEmpty)
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
            }
        }
        .frame(width: 480, height: 520)
    }
    
    private func createDocument() {
        let newDocument = Document(context: viewContext)
        newDocument.id = UUID()
        newDocument.title = title.isEmpty ? "新建文档" : title
        newDocument.content = ""
        newDocument.mode = selectedMode == .normal ? "normal" : "jupyter"
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
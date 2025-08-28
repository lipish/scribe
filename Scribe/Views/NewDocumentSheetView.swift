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
        .frame(width: 480, height: 400)
    }
    
    private func createDocument() {
        let documentTitle = title.isEmpty ? "新建文档" : title
        documentViewModel.createDocument(title: documentTitle)
        dismiss()
    }
}

#Preview {
    NewDocumentSheetView(documentViewModel: DocumentViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
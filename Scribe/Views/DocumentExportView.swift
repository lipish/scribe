//
//  DocumentExportView.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import SwiftUI
import UniformTypeIdentifiers

// 导出格式枚举
enum ExportFormat: String, CaseIterable {
    case pdf = "PDF"
    case markdown = "Markdown"
    case txt = "文本"
    case html = "HTML"
    
    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .markdown: return "md"
        case .txt: return "txt"
        case .html: return "html"
        }
    }
    
    var utType: UTType {
        switch self {
        case .pdf: return .pdf
        case .markdown: return UTType("net.daringfireball.markdown") ?? .plainText
        case .txt: return .plainText
        case .html: return .html
        }
    }
    
    var icon: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .markdown: return "doc.text"
        case .txt: return "doc.plaintext"
        case .html: return "globe"
        }
    }
}

struct DocumentExportView: View {
    let document: Document
    @Environment(\.dismiss) private var dismiss
    @StateObject private var exportService = DocumentExportService.shared
    
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var isExporting = false
    @State private var showingFilePicker = false
    @State private var exportError: Error?
    @State private var showingErrorAlert = false
    @State private var exportSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 文档信息
                documentInfoSection
                
                // 导出格式选择
                formatSelectionSection
                
                // 导出按钮
                exportButtonSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("导出文档")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .fileExporter(
            isPresented: $showingFilePicker,
            document: ExportDocument(content: "", format: selectedFormat),
            contentType: selectedFormat.utType,
            defaultFilename: generateFilename()
        ) { result in
            handleExportResult(result)
        }
        .alert("导出错误", isPresented: $showingErrorAlert) {
            Button("确定") { }
        } message: {
            Text(exportError?.localizedDescription ?? "未知错误")
        }
        .alert("导出成功", isPresented: $exportSuccess) {
            Button("确定") {
                dismiss()
            }
        } message: {
            Text("文档已成功导出")
        }
    }
    
    // MARK: - 文档信息区域
    private var documentInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: document.mode == "jupyter" ? "terminal.fill" : "doc.text.fill")
                    .foregroundColor(.accentColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title ?? "无标题")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(document.mode == "jupyter" ? "Jupyter 模式" : "普通模式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if let updatedAt = document.updatedAt {
                Text("最后修改：\(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 内容预览
            if let content = document.content, !content.isEmpty {
                Text("内容预览")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(content.prefix(200) + (content.count > 200 ? "..." : ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .lineLimit(4)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 格式选择区域
    private var formatSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("选择导出格式")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    FormatOptionView(
                        format: format,
                        isSelected: selectedFormat == format
                    ) {
                        selectedFormat = format
                    }
                }
            }
        }
    }
    
    // MARK: - 导出按钮区域
    private var exportButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                startExport()
            }) {
                HStack {
                    if isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Text(isExporting ? "导出中..." : "导出为 \(selectedFormat.rawValue)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isExporting ? Color.gray : Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isExporting)
            
            Text("选择保存位置并开始导出")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 辅助方法
    private func generateFilename() -> String {
        let title = (document.title ?? "").isEmpty ? "无标题" : (document.title ?? "")
        let cleanTitle = title.replacingOccurrences(of: "[^a-zA-Z0-9\\u4e00-\\u9fa5]", with: "_", options: NSString.CompareOptions.regularExpression)
        return "\(cleanTitle).\(selectedFormat.fileExtension)"
    }
    
    private func startExport() {
        showingFilePicker = true
    }
    
    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            performExport(to: url)
        case .failure(let error):
            exportError = error
            showingErrorAlert = true
        }
    }
    
    private func performExport(to url: URL) {
        isExporting = true
        
        Task {
            do {
                try await exportService.exportDocument(document, format: selectedFormat, to: url)
                
                await MainActor.run {
                    isExporting = false
                    exportSuccess = true
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error
                    showingErrorAlert = true
                }
            }
        }
    }
}

// MARK: - 格式选项视图
struct FormatOptionView: View {
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: formatIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accentColor)
                
                Text(format.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(format.fileExtension.uppercased())
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var formatIcon: String {
        switch format {
        case .pdf:
            return "doc.fill"
        case .html:
            return "globe"
        case .markdown:
            return "text.alignleft"
        case .txt:
            return "doc.plaintext"
        }
    }
}

// MARK: - 导出文档包装器
struct ExportDocument: FileDocument {
    let content: String
    let format: ExportFormat
    
    static var readableContentTypes: [UTType] {
        [.plainText, .html, .pdf]
    }
    
    init(content: String, format: ExportFormat) {
        self.content = content
        self.format = format
    }
    
    init(configuration: ReadConfiguration) throws {
        self.content = ""
        self.format = .txt
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = content.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - 预览
#Preview {
    DocumentExportView(document: Document())
}
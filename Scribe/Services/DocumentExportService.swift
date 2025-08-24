//
//  DocumentExportService.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import Foundation
import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import AppKit
import CoreData

// MARK: - 导出格式枚举
enum ExportFormat: String, CaseIterable {
    case pdf = "PDF"
    case html = "HTML"
    case markdown = "Markdown"
    case plainText = "纯文本"
    
    var fileExtension: String {
        switch self {
        case .pdf:
            return "pdf"
        case .html:
            return "html"
        case .markdown:
            return "md"
        case .plainText:
            return "txt"
        }
    }
    
    var utType: UTType {
        switch self {
        case .pdf:
            return .pdf
        case .html:
            return .html
        case .markdown:
            return UTType("net.daringfireball.markdown") ?? .plainText
        case .plainText:
            return .plainText
        }
    }
}

// MARK: - 导出服务
class DocumentExportService: ObservableObject {
    static let shared = DocumentExportService()
    
    private init() {}
    
    // MARK: - 主导出方法
    func exportDocument(_ document: Document, format: ExportFormat, to url: URL) throws {
        switch format {
        case .pdf:
            try exportToPDF(document, to: url)
        case .html:
            try exportToHTML(document, to: url)
        case .markdown:
            try exportToMarkdown(document, to: url)
        case .plainText:
            try exportToPlainText(document, to: url)
        }
    }
    
    // MARK: - PDF 导出
    private func exportToPDF(_ document: Document, to url: URL) throws {
        let content = document.content ?? ""
        let title = document.title ?? "无标题"
        
        // 创建 HTML 内容用于 PDF 生成
        let htmlContent = generateHTMLContent(title: title, content: content, isJupyter: document.mode == "jupyter")
        
        // 创建 NSAttributedString
        guard let data = htmlContent.data(using: String.Encoding.utf8),
              let attributedString = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                         .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
              ) else {
            throw ExportError.failedToCreateAttributedString
        }
        
        // 创建 PDF
        let pdfDocument = PDFDocument()
        let pageSize = CGSize(width: 612, height: 792) // A4 大小
        
        // 计算文本布局
        let textContainer = NSTextContainer(size: CGSize(width: pageSize.width - 80, height: pageSize.height - 120))
        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage(attributedString: attributedString)
        
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        
        // 生成页面
        var pageIndex = 0
        var glyphRange = NSRange(location: 0, length: 0)
        
        while glyphRange.location < layoutManager.numberOfGlyphs {
            var pageRect = CGRect(origin: .zero, size: pageSize)
            let textRect = CGRect(x: 40, y: 60, width: pageSize.width - 80, height: pageSize.height - 120)
            
            glyphRange = layoutManager.glyphRange(for: textContainer)
            
            // 创建页面
            let page = PDFPage()
            let pageData = NSMutableData()
            let consumer = CGDataConsumer(data: pageData)!
            let context = CGContext(consumer: consumer, mediaBox: &pageRect, nil)!
            
            context.beginPage(mediaBox: &pageRect)
            
            // 绘制文本
            let drawingRect = CGRect(x: textRect.origin.x, y: pageSize.height - textRect.origin.y - textRect.height, 
                                   width: textRect.width, height: textRect.height)
            
            layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: drawingRect.origin)
            
            context.endPage()
            context.flush()
            
            if let pageFromData = PDFPage(image: NSImage(data: pageData as Data)!) {
                pdfDocument.insert(pageFromData, at: pageIndex)
                pageIndex += 1
            }
            
            // 移动到下一页
            if glyphRange.location + glyphRange.length >= layoutManager.numberOfGlyphs {
                break
            }
        }
        
        // 保存 PDF
        guard pdfDocument.write(to: url) else {
            throw ExportError.failedToWriteFile
        }
    }
    
    // MARK: - HTML 导出
    private func exportToHTML(_ document: Document, to url: URL) throws {
        let content = document.content ?? ""
        let title = document.title ?? "无标题"
        
        let htmlContent = generateHTMLContent(title: title, content: content, isJupyter: document.mode == "jupyter")
        
        try htmlContent.write(to: url, atomically: true, encoding: String.Encoding.utf8)
    }
    
    // MARK: - Markdown 导出
    private func exportToMarkdown(_ document: Document, to url: URL) throws {
        let content = document.content ?? ""
        let title = document.title ?? "无标题"
        
        var markdownContent = "# \(title)\n\n"
        
        if document.mode == "jupyter" {
            // 处理 Jupyter 模式的单元格
            markdownContent += processJupyterCellsToMarkdown(document)
        } else {
            // 普通模式直接添加内容
            markdownContent += content
        }
        
        try markdownContent.write(to: url, atomically: true, encoding: String.Encoding.utf8)
    }
    
    // MARK: - 纯文本导出
    private func exportToPlainText(_ document: Document, to url: URL) throws {
        let content = document.content ?? ""
        let title = document.title ?? "无标题"
        
        var textContent = "\(title)\n\n"
        
        if document.mode == "jupyter" {
            // 处理 Jupyter 模式的单元格
            textContent += processJupyterCellsToPlainText(document)
        } else {
            // 普通模式直接添加内容
            textContent += content
        }
        
        try textContent.write(to: url, atomically: true, encoding: String.Encoding.utf8)
    }
    
    // MARK: - HTML 内容生成
    private func generateHTMLContent(title: String, content: String, isJupyter: Bool) -> String {
        let css = """
        <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3, h4, h5, h6 {
            color: #2c3e50;
            margin-top: 24px;
            margin-bottom: 16px;
        }
        h1 {
            border-bottom: 2px solid #eee;
            padding-bottom: 10px;
        }
        code {
            background-color: #f8f9fa;
            padding: 2px 4px;
            border-radius: 3px;
            font-family: 'SF Mono', Monaco, 'Cascadia Code', monospace;
        }
        pre {
            background-color: #f8f9fa;
            padding: 16px;
            border-radius: 6px;
            overflow-x: auto;
            border-left: 4px solid #007aff;
        }
        .jupyter-cell {
            margin: 16px 0;
            border: 1px solid #e1e4e8;
            border-radius: 6px;
            overflow: hidden;
        }
        .cell-input {
            background-color: #f6f8fa;
            padding: 12px;
            border-bottom: 1px solid #e1e4e8;
        }
        .cell-output {
            padding: 12px;
            background-color: white;
        }
        </style>
        """
        
        let htmlContent = """
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(title)</title>
            \(css)
        </head>
        <body>
            <h1>\(title)</h1>
            \(isJupyter ? processContentAsJupyterHTML(content) : processContentAsHTML(content))
        </body>
        </html>
        """
        
        return htmlContent
    }
    
    // MARK: - 内容处理方法
    private func processContentAsHTML(_ content: String) -> String {
        // 简单的 Markdown 到 HTML 转换
        var html = content
        
        // 处理标题
        html = html.replacingOccurrences(of: "^# (.+)$", with: "<h1>$1</h1>", options: .regularExpression)
        html = html.replacingOccurrences(of: "^## (.+)$", with: "<h2>$1</h2>", options: .regularExpression)
        html = html.replacingOccurrences(of: "^### (.+)$", with: "<h3>$1</h3>", options: .regularExpression)
        
        // 处理代码块
        html = html.replacingOccurrences(of: "```([\\s\\S]*?)```", with: "<pre><code>$1</code></pre>", options: .regularExpression)
        
        // 处理行内代码
        html = html.replacingOccurrences(of: "`([^`]+)`", with: "<code>$1</code>", options: .regularExpression)
        
        // 处理换行
        html = html.replacingOccurrences(of: "\n", with: "<br>")
        
        return html
    }
    
    private func processContentAsJupyterHTML(_ content: String) -> String {
        // 这里应该处理 Jupyter 单元格的 HTML 渲染
        // 简化实现，实际应该解析单元格数据
        return "<div class='jupyter-cell'><div class='cell-input'><pre><code>\(content)</code></pre></div></div>"
    }
    
    private func processJupyterCellsToMarkdown(_ document: Document) -> String {
        // 这里应该处理 Jupyter 单元格到 Markdown 的转换
        // 简化实现
        return document.content ?? ""
    }
    
    private func processJupyterCellsToPlainText(_ document: Document) -> String {
        // 这里应该处理 Jupyter 单元格到纯文本的转换
        // 简化实现
        return document.content ?? ""
    }
}

// MARK: - 导出错误
enum ExportError: LocalizedError {
    case failedToCreateAttributedString
    case failedToWriteFile
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .failedToCreateAttributedString:
            return "无法创建富文本内容"
        case .failedToWriteFile:
            return "无法写入文件"
        case .unsupportedFormat:
            return "不支持的导出格式"
        }
    }
}
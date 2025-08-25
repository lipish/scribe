//
//  DocumentExportService.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// 文档导出服务
class DocumentExportService: ObservableObject {
    static let shared = DocumentExportService()
    
    private init() {}
    
    // 导出文档方法
    func exportDocument(_ document: Document, format: ExportFormat, to url: URL) async throws {
        let content = document.content ?? ""
        
        switch format {
        case .txt:
            try content.write(to: url, atomically: true, encoding: .utf8)
        case .markdown:
            try content.write(to: url, atomically: true, encoding: .utf8)
        case .html:
            let htmlContent = convertToHTML(content)
            try htmlContent.write(to: url, atomically: true, encoding: .utf8)
        case .pdf:
            try await exportToPDF(content: content, to: url)
        }
    }
    
    private func convertToHTML(_ content: String) -> String {
        let htmlTemplate = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>导出文档</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.6; margin: 40px; }
                pre { background: #f5f5f5; padding: 10px; border-radius: 5px; }
            </style>
        </head>
        <body>
            <pre>\(content.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))</pre>
        </body>
        </html>
        """
        return htmlTemplate
    }
    
    private func exportToPDF(content: String, to url: URL) async throws {
        // 简化的PDF导出，实际项目中可以使用更复杂的PDF生成库
        let htmlContent = convertToHTML(content)
        try htmlContent.write(to: url.appendingPathExtension("html"), atomically: true, encoding: .utf8)
    }
}
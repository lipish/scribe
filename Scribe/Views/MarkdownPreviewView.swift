//
//  MarkdownPreviewView.swift
//  Scribe
//
//  Created by Assistant on 2024.
//

import SwiftUI
import AppKit
import Foundation

// MARK: - Markdown 预览视图
struct MarkdownPreviewView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 简单的 Markdown 渲染
                ForEach(parseMarkdown(content), id: \.id) { element in
                    renderMarkdownElement(element)
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(Color(NSColor.textBackgroundColor))
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        let lines = text.components(separatedBy: .newlines)
        var elements: [MarkdownElement] = []
        
        for line in lines {
            if line.hasPrefix("# ") {
                elements.append(MarkdownElement(type: .heading1, content: String(line.dropFirst(2))))
            } else if line.hasPrefix("## ") {
                elements.append(MarkdownElement(type: .heading2, content: String(line.dropFirst(3))))
            } else if line.hasPrefix("### ") {
                elements.append(MarkdownElement(type: .heading3, content: String(line.dropFirst(4))))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                elements.append(MarkdownElement(type: .bulletPoint, content: String(line.dropFirst(2))))
            } else if line.hasPrefix("```") {
                elements.append(MarkdownElement(type: .codeBlock, content: line))
            } else {
                elements.append(MarkdownElement(type: .paragraph, content: line))
            }
        }
        
        return elements
    }
    
    @ViewBuilder
    private func renderMarkdownElement(_ element: MarkdownElement) -> some View {
        switch element.type {
        case .heading1:
            Text(element.content)
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .heading2:
            Text(element.content)
                .font(.title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .heading3:
            Text(element.content)
                .font(.title2)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .bulletPoint:
            HStack(alignment: .top) {
                Text("•")
                    .font(.body)
                Text(element.content)
                    .font(.body)
                Spacer()
            }
        case .codeBlock:
            Text(element.content)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .paragraph:
            if !element.content.isEmpty {
                Text(element.content)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
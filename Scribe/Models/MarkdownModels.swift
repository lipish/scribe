//
//  MarkdownModels.swift
//  Scribe
//
//  Created by Assistant on 2024.
//

import Foundation

// MARK: - Markdown Element
struct MarkdownElement: Identifiable {
    let id = UUID()
    let type: MarkdownElementType
    let content: String
}

enum MarkdownElementType {
    case heading1
    case heading2
    case heading3
    case bulletPoint
    case codeBlock
    case paragraph
}
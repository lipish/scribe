//
//  RichTextEditor.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import SwiftUI
import AppKit
import CoreData

// MARK: - 富文本编辑器
struct RichTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var isEditing: Bool
    var font: NSFont = NSFont.systemFont(ofSize: 16)
    var textColor: NSColor = NSColor.textColor
    var backgroundColor: NSColor = NSColor.textBackgroundColor
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        // 配置滚动视图
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.documentView = textView
        
        // 配置文本视图
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = true
        textView.importsGraphics = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = true
        textView.smartInsertDeleteEnabled = true
        textView.isAutomaticLinkDetectionEnabled = true
        
        // 设置字体和颜色
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = backgroundColor
        
        // 设置文本容器
        textView.textContainer?.containerSize = CGSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        
        // 设置代理
        textView.delegate = context.coordinator
        
        // 设置初始文本
        textView.string = text
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // 更新文本（如果需要）
        if textView.string != text {
            textView.string = text
        }
        
        // 更新编辑状态
        textView.isEditable = isEditing
        
        // 更新外观
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = backgroundColor
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            DispatchQueue.main.async {
                self.parent.text = textView.string
            }
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // 处理特殊键盘命令
            switch commandSelector {
            case #selector(NSTextView.insertTab(_:)):
                // 处理 Tab 键
                textView.replaceCharacters(in: textView.selectedRange(), with: "    ") // 插入4个空格
                return true
            default:
                return false
            }
        }
    }
}

// MARK: - 富文本工具栏
struct RichTextToolbar: View {
    @Binding var selectedTextView: NSTextView?
    @State private var isBold = false
    @State private var isItalic = false
    @State private var isUnderlined = false
    @State private var fontSize: Double = 16
    @State private var textAlignment: NSTextAlignment = .left
    
    var body: some View {
        HStack(spacing: 12) {
            // 字体样式按钮
            Group {
                Button(action: toggleBold) {
                    Image(systemName: "bold")
                        .foregroundColor(isBold ? .accentColor : .secondary)
                }
                .help("粗体")
                
                Button(action: toggleItalic) {
                    Image(systemName: "italic")
                        .foregroundColor(isItalic ? .accentColor : .secondary)
                }
                .help("斜体")
                
                Button(action: toggleUnderline) {
                    Image(systemName: "underline")
                        .foregroundColor(isUnderlined ? .accentColor : .secondary)
                }
                .help("下划线")
            }
            .buttonStyle(.plain)
            
            Divider()
                .frame(height: 20)
            
            // 字体大小
            HStack {
                Text("字号:")
                    .font(.caption)
                
                Slider(value: $fontSize, in: 10...24, step: 1) {
                    Text("字号")
                } minimumValueLabel: {
                    Text("10")
                        .font(.caption2)
                } maximumValueLabel: {
                    Text("24")
                        .font(.caption2)
                }
                .frame(width: 80)
                .onChange(of: fontSize) { _ in
                    changeFontSize()
                }
                
                Text("\(Int(fontSize))")
                    .font(.caption)
                    .frame(width: 20)
            }
            
            Divider()
                .frame(height: 20)
            
            // 对齐方式
            HStack(spacing: 4) {
                Button(action: { setAlignment(.left) }) {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(textAlignment == .left ? .accentColor : .secondary)
                }
                .help("左对齐")
                
                Button(action: { setAlignment(.center) }) {
                    Image(systemName: "text.aligncenter")
                        .foregroundColor(textAlignment == .center ? .accentColor : .secondary)
                }
                .help("居中对齐")
                
                Button(action: { setAlignment(.right) }) {
                    Image(systemName: "text.alignright")
                        .foregroundColor(textAlignment == .right ? .accentColor : .secondary)
                }
                .help("右对齐")
            }
            .buttonStyle(.plain)
            
            Divider()
                .frame(height: 20)
            
            // 列表和格式
            HStack(spacing: 4) {
                Button(action: insertBulletList) {
                    Image(systemName: "list.bullet")
                }
                .help("项目符号列表")
                
                Button(action: insertNumberedList) {
                    Image(systemName: "list.number")
                }
                .help("编号列表")
                
                Button(action: insertLink) {
                    Image(systemName: "link")
                }
                .help("插入链接")
                
                Button(action: insertCodeBlock) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                }
                .help("代码块")
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // 撤销重做
            HStack(spacing: 4) {
                Button(action: undo) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .help("撤销")
                
                Button(action: redo) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .help("重做")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)) { notification in
            if let textView = notification.object as? NSTextView {
                updateToolbarState(for: textView)
            }
        }
    }
    
    // MARK: - 工具栏操作
    
    private func toggleBold() {
        guard let textView = selectedTextView else { return }
        
        let range = textView.selectedRange()
        let currentAttributes = textView.typingAttributes
        
        if let font = currentAttributes[.font] as? NSFont {
            let newFont: NSFont
            if font.fontDescriptor.symbolicTraits.contains(.bold) {
                newFont = NSFont(descriptor: font.fontDescriptor.withSymbolicTraits(font.fontDescriptor.symbolicTraits.subtracting(.bold)), size: font.pointSize) ?? font
            } else {
                newFont = NSFont(descriptor: font.fontDescriptor.withSymbolicTraits(font.fontDescriptor.symbolicTraits.union(.bold)), size: font.pointSize) ?? font
            }
            
            textView.textStorage?.addAttribute(.font, value: newFont, range: range)
            textView.typingAttributes[.font] = newFont
        }
    }
    
    private func toggleItalic() {
        guard let textView = selectedTextView else { return }
        
        let range = textView.selectedRange()
        let currentAttributes = textView.typingAttributes
        
        if let font = currentAttributes[.font] as? NSFont {
            let newFont: NSFont
            if font.fontDescriptor.symbolicTraits.contains(.italic) {
                newFont = NSFont(descriptor: font.fontDescriptor.withSymbolicTraits(font.fontDescriptor.symbolicTraits.subtracting(.italic)), size: font.pointSize) ?? font
            } else {
                newFont = NSFont(descriptor: font.fontDescriptor.withSymbolicTraits(font.fontDescriptor.symbolicTraits.union(.italic)), size: font.pointSize) ?? font
            }
            
            textView.textStorage?.addAttribute(.font, value: newFont, range: range)
            textView.typingAttributes[.font] = newFont
        }
    }
    
    private func toggleUnderline() {
        guard let textView = selectedTextView else { return }
        
        let range = textView.selectedRange()
        let currentAttributes = textView.typingAttributes
        
        let underlineStyle = currentAttributes[.underlineStyle] as? Int ?? 0
        let newUnderlineStyle = underlineStyle == 0 ? NSUnderlineStyle.single.rawValue : 0
        
        textView.textStorage?.addAttribute(.underlineStyle, value: newUnderlineStyle, range: range)
        textView.typingAttributes[.underlineStyle] = newUnderlineStyle
    }
    
    private func changeFontSize() {
        guard let textView = selectedTextView else { return }
        
        let range = textView.selectedRange()
        let currentAttributes = textView.typingAttributes
        
        if let font = currentAttributes[.font] as? NSFont {
            let newFont = NSFont(descriptor: font.fontDescriptor, size: CGFloat(fontSize)) ?? font
            textView.textStorage?.addAttribute(.font, value: newFont, range: range)
            textView.typingAttributes[.font] = newFont
        }
    }
    
    private func setAlignment(_ alignment: NSTextAlignment) {
        guard let textView = selectedTextView else { return }
        
        let range = textView.selectedRange()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        
        textView.textStorage?.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        textView.typingAttributes[.paragraphStyle] = paragraphStyle
        
        textAlignment = alignment
    }
    
    private func insertBulletList() {
        guard let textView = selectedTextView else { return }
        
        let bulletText = "• "
        textView.replaceCharacters(in: textView.selectedRange(), with: bulletText)
    }
    
    private func insertNumberedList() {
        guard let textView = selectedTextView else { return }
        
        let numberedText = "1. "
        textView.replaceCharacters(in: textView.selectedRange(), with: numberedText)
    }
    
    private func insertLink() {
        guard let textView = selectedTextView else { return }
        
        let linkText = "[链接文本](https://example.com)"
        textView.replaceCharacters(in: textView.selectedRange(), with: linkText)
    }
    
    private func insertCodeBlock() {
        guard let textView = selectedTextView else { return }
        
        let codeText = "```\n代码\n```"
        textView.replaceCharacters(in: textView.selectedRange(), with: codeText)
    }
    
    private func undo() {
        guard let textView = selectedTextView else { return }
        textView.undoManager?.undo()
    }
    
    private func redo() {
        guard let textView = selectedTextView else { return }
        textView.undoManager?.redo()
    }
    
    private func updateToolbarState(for textView: NSTextView) {
        selectedTextView = textView
        
        let attributes = textView.typingAttributes
        
        // 更新字体样式状态
        if let font = attributes[.font] as? NSFont {
            isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
            isItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
            fontSize = Double(font.pointSize)
        }
        
        // 更新下划线状态
        let underlineStyle = attributes[.underlineStyle] as? Int ?? 0
        isUnderlined = underlineStyle != 0
        
        // 更新对齐方式
        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            textAlignment = paragraphStyle.alignment
        }
    }
}



// MarkdownPreviewView 现在在单独的 MarkdownPreviewView.swift 文件中定义
// MarkdownElement 现在在 MarkdownModels.swift 中定义
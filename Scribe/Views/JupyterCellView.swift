//
//  JupyterCellView.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import SwiftUI
import CoreData



// MARK: - 单元格类型枚举
enum CellType: String, CaseIterable {
    case code = "code"
    case markdown = "markdown"
    case text = "text"
    
    var displayName: String {
        switch self {
        case .code:
            return "代码"
        case .markdown:
            return "Markdown"
        case .text:
            return "文本"
        }
    }
    
    var icon: String {
        switch self {
        case .code:
            return "chevron.left.forwardslash.chevron.right"
        case .markdown:
            return "doc.text"
        case .text:
            return "textformat"
        }
    }
}

// MARK: - 单元格执行状态
enum CellExecutionStatus: String {
    case idle = "idle"
    case running = "running"
    case completed = "completed"
    case error = "error"
    
    var color: Color {
        switch self {
        case .idle:
            return .secondary
        case .running:
            return .blue
        case .completed:
            return .green
        case .error:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .idle:
            return "circle"
        case .running:
            return "arrow.triangle.2.circlepath"
        case .completed:
            return "checkmark.circle"
        case .error:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - Jupyter 单元格视图
struct JupyterCellView: View {
    @ObservedObject var cell: Cell
    @ObservedObject var documentViewModel: DocumentViewModel
    
    // 状态变量
    @State private var isEditing: Bool = false
    @State private var isHovered: Bool = false
    @State private var showingOutput: Bool = true
    @State private var executionStatus: CellExecutionStatus = .idle
    @FocusState private var isInputFocused: Bool
    
    // 计算属性
    private var cellType: CellType {
        CellType(rawValue: cell.cellType ?? "text") ?? .text
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 单元格主体
            HStack(alignment: .top, spacing: 0) {
                // 左侧指示器和控制
                VStack(spacing: 8) {
                    // 执行状态指示器
                    Button(action: executeCell) {
                        Image(systemName: executionStatus.icon)
                            .foregroundColor(executionStatus.color)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .help("执行单元格")
                    .disabled(executionStatus == .running)
                    
                    // 单元格类型指示器
                    Image(systemName: cellType.icon)
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .frame(width: 30)
                .padding(.top, 8)
                
                // 单元格内容区域
                VStack(alignment: .leading, spacing: 0) {
                    // 单元格工具栏
                    if isHovered || isEditing {
                        cellToolbar
                    }
                    
                    // 输入区域
                    cellInputArea
                    
                    // 输出区域
                    if showingOutput && !(cell.output?.isEmpty ?? true) {
                        cellOutputArea
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isEditing ? Color.accentColor.opacity(0.1) : Color.clear)
                        .stroke(isEditing ? Color.accentColor : Color.clear, lineWidth: 1)
                )
            }
        }
        .padding(.vertical, 4)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            cellContextMenu
        }
    }
    
    // MARK: - 单元格工具栏
    @ViewBuilder
    private var cellToolbar: some View {
        HStack {
            // 单元格类型选择器
            Menu {
                ForEach(CellType.allCases, id: \.self) { type in
                    Button(action: {
                        changeCellType(to: type)
                    }) {
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                            if cellType == type {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: cellType.icon)
                    Text(cellType.displayName)
                    Image(systemName: "chevron.down")
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
            }
            .menuStyle(.borderlessButton)
            
            Spacer()
            
            // 单元格操作按钮
            HStack(spacing: 4) {
                Button(action: moveUp) {
                    Image(systemName: "arrow.up")
                }
                .help("上移")
                
                Button(action: moveDown) {
                    Image(systemName: "arrow.down")
                }
                .help("下移")
                
                Button(action: duplicateCell) {
                    Image(systemName: "doc.on.doc")
                }
                .help("复制")
                
                Button(action: deleteCell) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .help("删除")
            }
            .buttonStyle(.plain)
            .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
        .cornerRadius(6)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    // MARK: - 输入区域
    @ViewBuilder
    private var cellInputArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isEditing {
                // 编辑模式
                if cellType == .code {
                    CodeEditorView(
                        text: Binding(
                            get: { cell.input ?? "" },
                            set: { newValue in
                                cell.input = newValue
                                cell.updatedAt = Date()
                                documentViewModel.saveContext()
                            }
                        ),
                        language: "python"
                    )
                    .focused($isInputFocused)
                    .frame(minHeight: 100)
                } else {
                    TextEditor(text: Binding(
                        get: { cell.input ?? "" },
                        set: { newValue in
                            cell.input = newValue
                            cell.updatedAt = Date()
                            documentViewModel.saveContext()
                        }
                    ))
                    .focused($isInputFocused)
                    .font(cellType == .code ? .system(.body, design: .monospaced) : .body)
                    .frame(minHeight: 60)
                }
            } else {
                // 显示模式
                if cellType == .markdown {
                    MarkdownRenderView(content: cell.input ?? "")
                        .frame(minHeight: 40)
                } else {
                    Text(cell.input ?? "点击编辑...")
                        .font(cellType == .code ? .system(.body, design: .monospaced) : .body)
                        .foregroundColor(cell.input?.isEmpty == false ? .primary : .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 40)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(cellType == .code ? Color(NSColor.controlBackgroundColor) : Color.clear)
        )
        .onTapGesture {
            if !isEditing {
                isEditing = true
                isInputFocused = true
            }
        }
        .onSubmit {
            if cellType == .code {
                executeCell()
            }
        }
    }
    
    // MARK: - 输出区域
    @ViewBuilder
    private var cellOutputArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 输出工具栏
            HStack {
                Text("输出")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    showingOutput.toggle()
                }) {
                    Image(systemName: showingOutput ? "eye.slash" : "eye")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help(showingOutput ? "隐藏输出" : "显示输出")
                
                Button(action: clearOutput) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("清除输出")
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            // 输出内容
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cell.output ?? "")
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 200)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.textBackgroundColor))
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - 上下文菜单
    @ViewBuilder
    private var cellContextMenu: some View {
        Button("执行单元格") {
            executeCell()
        }
        
        Divider()
        
        Menu("更改类型") {
            ForEach(CellType.allCases, id: \.self) { type in
                Button(type.displayName) {
                    changeCellType(to: type)
                }
            }
        }
        
        Divider()
        
        Button("在上方插入单元格") {
            insertCellAbove()
        }
        
        Button("在下方插入单元格") {
            insertCellBelow()
        }
        
        Divider()
        
        Button("复制单元格") {
            duplicateCell()
        }
        
        Button("删除单元格") {
            deleteCell()
        }
    }
    
    // MARK: - 单元格操作
    
    private func executeCell() {
        guard let content = cell.input, !content.isEmpty else { return }
        
        executionStatus = .running
        
        Task {
            do {
                let result: String
                
                switch cellType {
                case .code:
                    // 使用 AI 服务执行代码或提供代码解释
                    if let aiService = AIServiceManager().currentService {
                        if content.contains("?") || content.contains("help") || content.contains("explain") {
                            // 如果是问题或请求帮助，使用 AI 生成回答
                            let response = try await aiService.generateResponse(for: content, context: nil)
                            result = response.content
                        } else {
                            // 如果是代码，提供代码解释和建议
                            result = try await aiService.explainCode(code: content, language: "python")
                        }
                    } else {
                        result = "错误: AI 服务未配置。请在设置中配置 OpenAI API 密钥。"
                    }
                    
                case .markdown, .text:
                    // 对于 Markdown 和文本单元格，可以提供 AI 辅助
                    if let aiService = AIServiceManager().currentService {
                        let response = try await aiService.generateResponse(for: content, context: nil)
                        result = response.content
                    } else {
                        result = "错误: AI 服务未配置。"
                    }
                }
                
                await MainActor.run {
                    cell.output = result
                    cell.updatedAt = Date()
                    documentViewModel.saveContext()
                    executionStatus = .completed
                }
                
            } catch {
                await MainActor.run {
                    cell.output = "执行错误: \(error.localizedDescription)"
                    cell.updatedAt = Date()
                    documentViewModel.saveContext()
                    executionStatus = .error
                }
            }
        }
    }
    
    private func changeCellType(to type: CellType) {
        cell.cellType = type.rawValue
        cell.updatedAt = Date()
        documentViewModel.saveContext()
    }
    
    private func moveUp() {
        // 实现单元格上移逻辑
        documentViewModel.moveCellUp(cell)
    }
    
    private func moveDown() {
        // 实现单元格下移逻辑
        documentViewModel.moveCellDown(cell)
    }
    
    private func duplicateCell() {
        documentViewModel.duplicateCell(cell)
    }
    
    private func deleteCell() {
        documentViewModel.deleteCell(cell)
    }
    
    private func insertCellAbove() {
        documentViewModel.insertCellAbove(cell)
    }
    
    private func insertCellBelow() {
        documentViewModel.insertCellBelow(cell)
    }
    
    private func clearOutput() {
        cell.output = ""
        cell.updatedAt = Date()
        documentViewModel.saveContext()
    }
}

// MARK: - 代码编辑器视图
struct CodeEditorView: NSViewRepresentable {
    @Binding var text: String
    let language: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        // 配置滚动视图
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.documentView = textView
        
        // 配置文本视图
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.controlBackgroundColor
        textView.insertionPointColor = NSColor.textColor
        
        // 设置文本容器
        textView.textContainer?.containerSize = CGSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        
        // 启用行号（简化版）
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        
        // 设置代理
        textView.delegate = context.coordinator
        
        // 设置初始文本
        textView.string = text
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: CodeEditorView
        
        init(_ parent: CodeEditorView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            DispatchQueue.main.async {
                self.parent.text = textView.string
            }
        }
    }
}

// MARK: - Markdown 渲染视图
struct MarkdownRenderView: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseMarkdown(content), id: \.id) { element in
                renderElement(element)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        let lines = text.components(separatedBy: .newlines)
        var elements: [MarkdownElement] = []
        var inCodeBlock = false
        var codeBlockContent = ""
        
        for line in lines {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End of code block
                    elements.append(MarkdownElement(type: .codeBlock, content: codeBlockContent))
                    codeBlockContent = ""
                    inCodeBlock = false
                } else {
                    // Start of code block
                    inCodeBlock = true
                }
            } else if inCodeBlock {
                // Inside code block
                if !codeBlockContent.isEmpty {
                    codeBlockContent += "\n"
                }
                codeBlockContent += line
            } else if line.hasPrefix("# ") {
                elements.append(MarkdownElement(type: .heading1, content: String(line.dropFirst(2))))
            } else if line.hasPrefix("## ") {
                elements.append(MarkdownElement(type: .heading2, content: String(line.dropFirst(3))))
            } else if line.hasPrefix("### ") {
                elements.append(MarkdownElement(type: .heading3, content: String(line.dropFirst(4))))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                elements.append(MarkdownElement(type: .bulletPoint, content: String(line.dropFirst(2))))
            } else {
                elements.append(MarkdownElement(type: .paragraph, content: line))
            }
        }
        
        // Handle unclosed code block
        if inCodeBlock && !codeBlockContent.isEmpty {
            elements.append(MarkdownElement(type: .codeBlock, content: codeBlockContent))
        }
        
        return elements
    }
    
    @ViewBuilder
    private func renderElement(_ element: MarkdownElement) -> some View {
        switch element.type {
        case .heading1:
            Text(element.content)
                .font(.title)
                .fontWeight(.bold)
        case .heading2:
            Text(element.content)
                .font(.title2)
                .fontWeight(.semibold)
        case .heading3:
            Text(element.content)
                .font(.title3)
                .fontWeight(.medium)
        case .bulletPoint:
            HStack(alignment: .top) {
                Text("•")
                Text(element.content)
                Spacer()
            }
        case .codeBlock:
            Text(element.content)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
        case .paragraph:
            if !element.content.isEmpty {
                Text(element.content)
                    .font(.body)
            }
        }
    }
}
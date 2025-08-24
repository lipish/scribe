//
//  AIService.swift
//  Scribe
//
//  Created by AI Assistant on 2024.
//

import Foundation
import Combine

// MARK: - AI Service Protocol
protocol AIServiceProtocol {
    func generateResponse(for prompt: String, context: String?) async throws -> AIServiceResponse
    func generateCodeCompletion(for code: String, language: String) async throws -> String
    func explainCode(code: String, language: String) async throws -> String
}

// MARK: - AI Response Model
struct AIServiceResponse: Codable {
    let id: String
    let content: String
    let model: String
    let usage: Usage?
    let createdAt: Date
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, content, model, usage
        case createdAt = "created_at"
    }
}

// MARK: - OpenAI Service Implementation
class OpenAIService: AIServiceProtocol {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    private let session = URLSession.shared
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(apiKey: String) {
        self.apiKey = apiKey
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        
        // 配置日期格式
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
    }
    
    // MARK: - Generate Response
    func generateResponse(for prompt: String, context: String? = nil) async throws -> AIServiceResponse {
        let messages = buildMessages(prompt: prompt, context: context)
        let request = ChatCompletionRequest(
            model: "gpt-3.5-turbo",
            messages: messages,
            maxTokens: 1000,
            temperature: 0.7
        )
        
        let response = try await performChatCompletion(request: request)
        
        return AIServiceResponse(
            id: response.id,
            content: response.choices.first?.message.content ?? "",
            model: response.model,
            usage: response.usage.map { usage in
                AIServiceResponse.Usage(
                    promptTokens: usage.promptTokens,
                    completionTokens: usage.completionTokens,
                    totalTokens: usage.totalTokens
                )
            },
            createdAt: Date()
        )
    }
    
    // MARK: - Generate Code Completion
    func generateCodeCompletion(for code: String, language: String) async throws -> String {
        let prompt = "请为以下\(language)代码提供补全建议：\n\n```\(language)\n\(code)\n```\n\n请只返回补全的代码部分，不要包含解释。"
        let response = try await generateResponse(for: prompt)
        return response.content
    }
    
    // MARK: - Explain Code
    func explainCode(code: String, language: String) async throws -> String {
        let prompt = "请解释以下\(language)代码的功能和工作原理：\n\n```\(language)\n\(code)\n```\n\n请用中文详细解释代码的逻辑和用途。"
        let response = try await generateResponse(for: prompt)
        return response.content
    }
    
    // MARK: - Private Methods
    private func buildMessages(prompt: String, context: String?) -> [ChatMessage] {
        var messages: [ChatMessage] = []
        
        // 系统消息
        messages.append(ChatMessage(
            role: "system",
            content: "你是一个智能编程助手，专门帮助用户进行代码开发、调试和学习。请用中文回答问题，提供准确、有用的建议。"
        ))
        
        // 上下文消息
        if let context = context, !context.isEmpty {
            messages.append(ChatMessage(
                role: "user",
                content: "上下文信息：\n\(context)"
            ))
        }
        
        // 用户消息
        messages.append(ChatMessage(
            role: "user",
            content: prompt
        ))
        
        return messages
    }
    
    private func performChatCompletion(request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIServiceError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            throw AIServiceError.encodingError(error)
        }
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                if let errorResponse = try? decoder.decode(OpenAIErrorResponse.self, from: data) {
                    throw AIServiceError.apiError(errorResponse.error.message)
                }
                throw AIServiceError.httpError(httpResponse.statusCode)
            }
            
            return try decoder.decode(ChatCompletionResponse.self, from: data)
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.networkError(error)
        }
    }
}

// MARK: - Request/Response Models
struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let maxTokens: Int?
    let temperature: Double?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatCompletionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage?
    
    struct Choice: Codable {
        let index: Int
        let message: ChatMessage
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

struct OpenAIErrorResponse: Codable {
    let error: OpenAIError
    
    struct OpenAIError: Codable {
        let message: String
        let type: String?
        let code: String?
    }
}

// MARK: - Error Types
enum AIServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case encodingError(Error)
    case networkError(Error)
    case httpError(Int)
    case apiError(String)
    case missingAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "无效的响应"
        case .encodingError(let error):
            return "编码错误: \(error.localizedDescription)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .httpError(let code):
            return "HTTP 错误: \(code)"
        case .apiError(let message):
            return "API 错误: \(message)"
        case .missingAPIKey:
            return "缺少 API 密钥"
        }
    }
}

// MARK: - AI Service Manager
class AIServiceManager: ObservableObject {
    static let shared = AIServiceManager()
    
    @Published var isConfigured = false
    @Published var currentService: AIServiceProtocol?
    
    private var apiKey: String? {
        didSet {
            updateService()
        }
    }
    
    init() {
        loadAPIKey()
    }
    
    func configure(with apiKey: String) {
        self.apiKey = apiKey
        saveAPIKey(apiKey)
    }
    
    private func updateService() {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            currentService = nil
            isConfigured = false
            return
        }
        
        currentService = OpenAIService(apiKey: apiKey)
        isConfigured = true
    }
    
    private func loadAPIKey() {
        // 从 Keychain 或 UserDefaults 加载 API 密钥
        // 这里简化为 UserDefaults，实际应用中建议使用 Keychain
        apiKey = UserDefaults.standard.string(forKey: "OpenAI_API_Key")
    }
    
    private func saveAPIKey(_ key: String) {
        // 保存到 Keychain 或 UserDefaults
        UserDefaults.standard.set(key, forKey: "OpenAI_API_Key")
    }
    
    func clearAPIKey() {
        apiKey = nil
        UserDefaults.standard.removeObject(forKey: "OpenAI_API_Key")
    }
    
    // MARK: - Convenience Methods
    func explainCode(_ code: String, language: String = "Swift") async throws -> String {
        guard let service = currentService else {
            throw AIServiceError.missingAPIKey
        }
        return try await service.explainCode(code: code, language: language)
    }
    
    func generateResponse(for prompt: String, context: String? = nil) async throws -> AIServiceResponse {
        guard let service = currentService else {
            throw AIServiceError.missingAPIKey
        }
        return try await service.generateResponse(for: prompt, context: context)
    }
}
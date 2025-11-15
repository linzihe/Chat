import Foundation

struct DeepSeekAPIClient {

    struct APIMessage: Codable {
        let role: String
        let content: String
    }

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [APIMessage]
    }

    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let role: String
                let content: String
            }

            let message: Message
        }

        let choices: [Choice]
    }

    enum APIError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case serverError(statusCode: Int, message: String)
        case emptyReply

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "未提供 DeepSeek API Key。请将密钥写入构造函数或设置 DEEPSEEK_API_KEY 环境变量。"
            case .invalidResponse:
                return "服务器响应无效"
            case .serverError(let statusCode, let message):
                return "服务器错误 (\(statusCode))：\(message)"
            case .emptyReply:
                return "没有收到任何回复"
            }
        }
    }

    private let apiKey: String?
    private let urlSession: URLSession
    private let endpoint = URL(string: "https://api.deepseek.com/v1/chat/completions")!

    init(apiKey: String? = nil, urlSession: URLSession = .shared) {
        let trimmedKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedKey, !trimmedKey.isEmpty {
            self.apiKey = trimmedKey
        } else if let env = ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines), !env.isEmpty {
            self.apiKey = env
        } else {
            self.apiKey = nil
        }
        self.urlSession = urlSession
    }

    var isConfigured: Bool {
        apiKey != nil
    }

    func sendChat(messages: [APIMessage]) async throws -> String {
        guard let apiKey else { throw APIError.missingAPIKey }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload = ChatRequest(model: "deepseek-chat", messages: messages)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let choice = decoded.choices.first else {
            throw APIError.emptyReply
        }

        let reply = choice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reply.isEmpty else { throw APIError.emptyReply }
        return reply
    }
}

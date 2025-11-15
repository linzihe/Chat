import Foundation
import ExyteChat

@MainActor
final class AIChatViewModel: ObservableObject {

    @Published var messages: [Message]

    private let currentUser = User(id: "current", name: "我", avatarURL: nil, isCurrentUser: true)
    private let assistantUser = User(id: "deepseek", name: "DeepSeek", avatarURL: nil, isCurrentUser: false)
    private let client: DeepSeekAPIClient

    private var conversation: [DeepSeekAPIClient.APIMessage]

    init(client: DeepSeekAPIClient = DeepSeekAPIClient()) {
        self.client = client

        let welcomeText = "你好！我是 DeepSeek，可以和你聊聊任何问题。"
        let welcomeMessage = Message(
            id: UUID().uuidString,
            user: assistantUser,
            status: .sent,
            createdAt: Date(),
            text: welcomeText
        )

        self.messages = [welcomeMessage]
        self.conversation = [
            .init(role: "system", content: "You are DeepSeek, a helpful and friendly AI assistant."),
            .init(role: "assistant", content: welcomeText)
        ]

        if !client.isConfigured {
            let instructions = Message(
                id: UUID().uuidString,
                user: assistantUser,
                status: .sent,
                createdAt: Date(),
                text: "⚠️ 尚未检测到 DeepSeek API Key。请在运行前设置 DEEPSEEK_API_KEY 环境变量或在 DeepSeekAPIClient 初始化时传入密钥。"
            )
            messages.append(instructions)
        }
    }

    func send(draft: DraftMessage) {
        let trimmed = draft.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        Task {
            await sendMessage(draft: draft, text: trimmed)
        }
    }

    private func sendMessage(draft: DraftMessage, text: String) async {
        let userMessage = await Message.makeMessage(
            id: draft.id ?? UUID().uuidString,
            user: currentUser,
            status: .sent,
            draft: draft
        )
        messages.append(userMessage)
        conversation.append(.init(role: "user", content: text))

        let placeholderID = UUID().uuidString
        let thinkingMessage = Message(
            id: placeholderID,
            user: assistantUser,
            status: .sending,
            createdAt: Date(),
            text: "正在思考…"
        )
        messages.append(thinkingMessage)

        do {
            let reply = try await client.sendChat(messages: conversation)
            conversation.append(.init(role: "assistant", content: reply))

            updateAssistantMessage(id: placeholderID, text: reply, status: .sent)
        } catch {
            updateAssistantMessage(id: placeholderID, text: "出错了：\(error.localizedDescription)", status: .error(draft))
        }
    }

    private func updateAssistantMessage(id: String, text: String, status: Message.Status?) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        let existing = messages[index]
        let updated = Message(
            id: existing.id,
            user: existing.user,
            status: status ?? existing.status,
            createdAt: existing.createdAt,
            text: text,
            attachments: existing.attachments,
            giphyMediaId: existing.giphyMediaId,
            reactions: existing.reactions,
            recording: existing.recording,
            replyMessage: existing.replyMessage
        )
        messages[index] = updated
    }
}

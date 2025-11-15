import SwiftUI
import ExyteChat

struct AIChatView: View {

    @StateObject private var viewModel: AIChatViewModel

    init(viewModel: AIChatViewModel = AIChatViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ChatView(messages: viewModel.messages, chatType: .conversation) { draft in
            viewModel.send(draft: draft)
        }
        .keyboardDismissMode(.interactive)
        .messageUseMarkdown(true)
        .setAvailableInputs([.text])
        .navigationTitle("DeepSeek Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

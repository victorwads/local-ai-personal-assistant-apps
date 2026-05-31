import SwiftUI

struct ChatConversationView: View {
    let chat: Chat?
    let messages: [ChatMessage]
    let isLoading: Bool
    let errorMessage: String?
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            DSFeatureHeader(
                title: chat?.title ?? "Conversation",
                subtitle: chatSubtitle,
                systemImage: "text.bubble"
            ) {
                DSRefreshButton(isLoading: isLoading, action: onRefresh)
            }

            Divider()

            Group {
                if let errorMessage {
                    EmptyStateView(
                        title: "Unable to load messages",
                        message: errorMessage,
                        systemImage: "exclamationmark.triangle",
                        actionTitle: "Retry",
                        action: onRefresh
                    )
                } else if chat == nil {
                    EmptyStateView(
                        title: "Select a chat",
                        message: "Choose a chat in the sidebar to view its conversation.",
                        systemImage: "sidebar.left"
                    )
                } else if isLoading && messages.isEmpty {
                    ProgressView("Loading messages...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if messages.isEmpty {
                    EmptyStateView(
                        title: "No messages yet",
                        message: "This chat does not have persisted messages in the local cache.",
                        systemImage: "ellipsis.message"
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(messages.enumerated()), id: \.offset) { _, message in
                                ChatMessageBubbleView(message: message)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var chatSubtitle: String {
        if let chat {
            return "Persisted history for \(chat.title)."
        }
        return "Persisted message history."
    }
}

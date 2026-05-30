import SwiftUI

struct SentMessageRowView: View {
    let sentMessage: SentMessage

    var body: some View {
        DSListCardRow(
            title: sentMessage.targetTitle,
            subtitle: "Issue: \(sentMessage.issueId)",
            description: messagesPreview,
            systemImage: "paperplane"
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    DSBadge(
                        "Target",
                        secondaryText: sentMessage.targetKind.rawValue,
                        style: .neutral
                    )

                    DSBadge(
                        "Status",
                        secondaryText: sentMessage.status.rawValue,
                        style: statusBadgeStyle
                    )
                }

                if !sentMessage.providerMessageIds.isEmpty {
                    Text("Provider IDs: \(sentMessage.providerMessageIds.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage = sentMessage.errorMessage,
                   sentMessage.status == .failed,
                   !errorMessage.isEmpty {
                    Text("Error: \(errorMessage)")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var messagesPreview: String {
        guard !sentMessage.messages.isEmpty else {
            return "No outbound message content."
        }

        return sentMessage.messages.joined(separator: "\n")
    }

    private var statusBadgeStyle: DSBadge.Style {
        switch sentMessage.status {
        case .pending:
            return .warning
        case .sent:
            return .success
        case .failed:
            return .danger
        }
    }
}

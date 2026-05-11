import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sidebarHeader("Bridge")
                    Label("WhatsApp", systemImage: appModel.whatsappRunning ? "checkmark.circle.fill" : "xmark.circle")
                    Label("Accessibility", systemImage: appModel.accessibilityTrusted ? "checkmark.circle.fill" : "lock.trianglebadge.exclamationmark")

                    sidebarHeader("Conversations")
                    ForEach(appModel.conversations) { conversation in
                        Button {
                            open(conversation)
                        } label: {
                            ConversationRow(conversation: conversation)
                                .contentShape(Rectangle())
                                .padding(.horizontal, 4)
                                .background(selectionBackground(for: conversation))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    sidebarHeader("Runtime")
                    Text(appModel.runtimeDescription)
                        .font(.caption)
                        .textSelection(.enabled)
                }
                .padding(12)
            }
            .navigationTitle("Assistant MCP")
        } detail: {
            VStack(spacing: 0) {
                toolbar
                Divider()
                ChatDetailView(
                    chatState: appModel.selectedChatState,
                    messageDraft: $appModel.messageDraft,
                    isSendingMessage: appModel.isSendingMessage,
                    isBlocked: appModel.selectedChatState.map { appModel.isBlocked($0.chat.name) } ?? false,
                    onToggleBlocked: {
                        guard let conversationName = appModel.selectedChatState?.chat.name else {
                            return
                        }

                        appModel.toggleBlockedConversation(conversationName)
                    },
                    onSend: {
                        Task {
                            await appModel.sendMessageToSelectedChat()
                        }
                    }
                )
                .frame(maxHeight: .infinity)
                Divider()
                LogView(logs: appModel.logs)
                    .frame(minHeight: 180, maxHeight: 260)
            }
        }
    }

    private func open(_ conversation: ConversationSummary) {
        guard appModel.selectedConversationId != conversation.id else {
            return
        }

        appModel.openConversation(conversation)
    }

    @ViewBuilder
    private func selectionBackground(for conversation: ConversationSummary) -> some View {
        if appModel.selectedConversationId == conversation.id {
            Color.accentColor.opacity(0.22)
        } else {
            Color.clear
        }
    }

    private func sidebarHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.top, 4)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button {
                appModel.refreshStatus()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }

            Button {
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }

            Spacer()

            MCPServerStatusBadge(
                isRunning: appModel.mcpServerRunning,
                address: appModel.mcpServerAddress,
                statusDescription: appModel.mcpServerStatusDescription
            )

            Text(appModel.lastRefreshDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .sheet(isPresented: $showingSettings) {
            SettingsView(appModel: appModel)
        }
    }
}

import Foundation

@MainActor
final class SentMessagesFeature: FeatureRuntime {
    override class var id: String { "sentMessages" }

    let repository: FirestoreSentMessageRepository
    private(set) var settings: SentMessagesSettingsWrapper

    required init(context: FeatureContext) {
        guard let scope = context.profileContext.scope else {
            preconditionFailure("SentMessagesFeature requires a persisted profile scope.")
        }

        let settings = SentMessagesSettingsWrapper(settings: context.settings.store)
        self.repository = FirestoreSentMessageRepository(scope: scope)
        self.settings = settings
        super.init(context: context)

        context.settings.sectionRegistry.register(
            SentMessagesSettingsSectionProvider(wrapper: settings)
        )

        context.mcp.toolRegistry.register([
            GetAssistantNameTool(settings: settings)
        ])
    }

    func recordPending(
        issueId: String,
        targetKind: SentMessageTargetKind,
        targetId: String,
        targetTitle: String,
        messages: [String]
    ) async throws -> SentMessage {
        try await repository.save(
            SentMessage(
                id: nil,
                issueId: issueId,
                targetKind: targetKind,
                targetId: targetId,
                targetTitle: targetTitle,
                messages: messages,
                status: .pending,
                providerMessageIds: [],
                errorMessage: nil
            )
        )
    }
}

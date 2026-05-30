import Foundation

@MainActor
final class SentMessagesFeature: FeatureRuntime {
    override class var id: String { "sentMessages" }

    let repository: FirestoreSentMessageRepository

    required init(context: FeatureContext) {
        guard let scope = context.profileContext.scope else {
            preconditionFailure("SentMessagesFeature requires a persisted profile scope.")
        }

        self.repository = FirestoreSentMessageRepository(scope: scope)
        super.init(context: context)
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

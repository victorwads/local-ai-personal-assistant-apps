import Foundation

@MainActor
final class ClientVoiceFeature: FeatureRuntime {
    override class var id: String { "clientVoice" }

    private let repository: ClientVoiceRepository?

    required init(context: FeatureContext) {
        self.repository = nil
        super.init(context: context)
        context.mcp.toolRegistry.register([
            SpeakToClientTool(),
            AskToClientTool()
        ])
    }

    func listByIssueId(_ issueId: String) async throws -> [ClientVoiceMessage] {
        guard let repository else {
            return []
        }

        return try await repository.listMessages(issueId: issueId)
    }
}

import Foundation

@MainActor
struct AIConnectionRuntimeStatusProvider: ProfileRuntimeStatusProvider {
    let service: any ProfileRuntimeService

    func statusItems() -> [ProfileRuntimeStatusItem] {
        let actionTitle = ProfileRuntimeServiceStatusFormatting.actionTitle(for: service.state)
        return [
            ProfileRuntimeStatusItem(
                id: "ai.connection.status",
                title: "AI Connection",
                stateLabel: ProfileRuntimeServiceStatusFormatting.stateLabel(for: service.state),
                detail: ProfileRuntimeServiceStatusFormatting.detail(for: service.state),
                actionTitle: actionTitle,
                action: actionTitle.map { _ in
                    {
                        await performAction()
                    }
                }
            )
        ]
    }

    private func performAction() async {
        switch service.state {
        case .stopped, .failed:
            await service.start()
        case .running, .starting:
            await service.stop()
        case .stopping:
            break
        }
    }
}

import SwiftUI

struct CommandCenterHeaderView: View {
    let profile: Profile
    let runtimeState: ProfileRuntimeState
    let windowState: ProfileWindowState

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.headline)
                Text("Profile workspace")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusPill("Runtime", runtimeState.rawValue)
            statusPill("Window", windowState.rawValue)
            statusPill("MCP", "\(profile.mcpPort)")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.background)
    }

    private func statusPill(_ title: String, _ value: String) -> some View {
        HStack(spacing: 5) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
                .textSelection(.enabled)
        }
        .font(.caption)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.quaternary, in: Capsule())
    }
}

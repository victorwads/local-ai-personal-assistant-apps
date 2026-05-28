import SwiftUI

struct CommandCenterHeaderView: View {
    let profile: Profile
    let runtimeState: ProfileRuntimeState
    let windowState: ProfileWindowState
    let statusRegistry: ProfileRuntimeStatusRegistry?

    @State private var refreshID = UUID()

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

            HStack(spacing: 8) {
                ForEach(statusRegistry?.items ?? []) { item in
                    statusItemView(item)
                }
            }
            .id(refreshID)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.background)
    }

    private func statusItemView(_ item: ProfileRuntimeStatusItem) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color(for: item.stateLabel))
                .frame(width: 7, height: 7)

            Text(item.title)
                .foregroundStyle(.secondary)

            if let actionTitle = actionTitleToRender(for: item), let action = item.action {
                Button {
                    Task { @MainActor in
                        await action()
                        refreshID = UUID()
                    }
                } label: {
                    Image(systemName: iconName(for: actionTitle))
                }
                .buttonStyle(.plain)
                .controlSize(.mini)
                .help("\(actionTitle) \(item.title)")
            }
        }
        .font(.caption)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.quaternary, in: Capsule())
    }

    private func actionTitleToRender(for item: ProfileRuntimeStatusItem) -> String? {
        switch item.stateLabel.lowercased() {
        case "starting", "stopping":
            return nil
        default:
            return item.actionTitle
        }
    }

    private func iconName(for actionTitle: String) -> String {
        switch actionTitle {
        case "Start":
            return "play.fill"
        case "Stop":
            return "stop.fill"
        default:
            return "questionmark"
        }
    }

    private func color(for stateLabel: String) -> Color {
        switch stateLabel.lowercased() {
        case "running":
            return .green
        case "starting", "stopping":
            return .orange
        case "failed":
            return .red
        case "stopped":
            return .secondary
        default:
            return .secondary
        }
    }
}

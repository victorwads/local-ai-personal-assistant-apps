import SwiftUI

struct IssuesScreen: View {
    let feature: IssuesFeature

    @State private var issues: [Issue] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        FeatureScreenContainer {
            VStack(alignment: .leading, spacing: 16) {
                DSFeatureHeader(
                    title: "Issues",
                    subtitle: "Active operational issues for this profile."
                ) {
                    DSRefreshButton(isLoading: isLoading) {
                        Task { await loadIssues() }
                    }
                }

                if isLoading {
                    ProgressView("Loading active issues...")
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let errorMessage {
                    EmptyStateView(
                        title: "Could not load issues",
                        message: errorMessage,
                        systemImage: "exclamationmark.triangle",
                        actionTitle: "Retry",
                        action: {
                            Task { await loadIssues() }
                        }
                    )
                } else if issues.isEmpty {
                    EmptyStateView(
                        title: "No active issues",
                        message: "Pending or suspended issues will appear here.",
                        systemImage: "checkmark.circle"
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(issues, id: \.id) { issue in
                                issueCard(issue)
                            }
                        }
                    }
                }
            }
        }
        .task {
            await loadIssues()
        }
    }

    private func issueCard(_ issue: Issue) -> some View {
        DSListCardRow(
            title: issue.title,
            description: issue.description
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    DSBadge(
                        "Status",
                        secondaryText: issue.status.rawValue,
                        style: badgeStyle(for: issue.status)
                    )

                    DSBadge(
                        "Priority",
                        secondaryText: String(issue.priority.rawValue),
                        style: badgeStyle(for: issue.priority)
                    )
                }

                if let suspendUntil = issue.suspendUntil {
                    Text("Suspended until: \(suspendUntil.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } trailing: {
            Button("Open") {
                // TODO: Open issue details screen.
            }
            .buttonStyle(.bordered)
        }
    }

    private func badgeStyle(for status: IssueStatus) -> DSBadge.Style {
        switch status {
        case .pending:
            return .info
        case .suspended:
            return .warning
        case .resolved:
            return .success
        case .cancelled:
            return .danger
        }
    }

    private func badgeStyle(for priority: IssuePriority) -> DSBadge.Style {
        switch priority.rawValue {
        case 1, 2:
            return .neutral
        case 3:
            return .info
        case 4:
            return .warning
        default:
            return .danger
        }
    }

    @MainActor
    private func loadIssues() async {
        isLoading = true
        errorMessage = nil

        do {
            issues = try await feature.repository.getActiveIssues()
        } catch {
            errorMessage = error.localizedDescription
            issues = []
        }

        isLoading = false
    }
}

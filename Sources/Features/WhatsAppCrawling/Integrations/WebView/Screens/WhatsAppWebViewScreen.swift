import SwiftUI

struct WhatsAppWebViewScreen: View {
    let service: WebViewWhatsAppCrawlingService?

    @State private var refreshID = UUID()

    var body: some View {
        Group {
            if let service {
                content(for: service)
            } else {
                serviceStateView(
                    title: "WebView runtime unavailable",
                    description: "Open the profile window from a persisted profile so the runtime container can provide the WebView service.",
                    actionTitle: nil,
                    action: nil
                )
            }
        }
        .id(refreshID)
    }

    @ViewBuilder
    private func content(for service: WebViewWhatsAppCrawlingService) -> some View {
        switch service.state {
        case .stopped:
            serviceStateView(
                title: "WhatsApp WebView is stopped",
                description: "Start the WebView service to load WhatsApp Web in this profile workspace.",
                actionTitle: "Start",
                action: {
                    await service.start()
                }
            )
        case .starting:
            VStack(spacing: 12) {
                ProgressView()
                Text("Starting WhatsApp WebView...")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .started:
            if let webView = service.webView {
                VStack(spacing: 0) {
                    HStack {
                        Text("WhatsApp Web")
                            .font(.headline)
                        Spacer()
                        Button("Stop") {
                            Task { @MainActor in
                                await service.stop()
                                refreshID = UUID()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Divider()

                    WebViewContainerView(webView: webView)
                }
            } else {
                serviceStateView(
                    title: "WebView is running without a view",
                    description: "The runtime reports running, but no WKWebView is currently available.",
                    actionTitle: "Restart",
                    action: {
                        await service.stop()
                        await service.start()
                    }
                )
            }
        case .stopping:
            VStack(spacing: 12) {
                ProgressView()
                Text("Stopping WhatsApp WebView...")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            serviceStateView(
                title: "WhatsApp WebView failed",
                description: message,
                actionTitle: "Start",
                action: {
                    await service.start()
                }
            )
        }
    }

    private func serviceStateView(
        title: String,
        description: String,
        actionTitle: String?,
        action: (() async -> Void)?
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.weight(.semibold))

            Text(description)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button(actionTitle) {
                    Task { @MainActor in
                        await action()
                        refreshID = UUID()
                    }
                }
                .buttonStyle(.borderedProminent)
            }

        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

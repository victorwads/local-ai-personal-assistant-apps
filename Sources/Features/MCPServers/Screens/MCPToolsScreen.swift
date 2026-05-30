import SwiftUI

struct MCPToolsScreen: View {
    @StateObject private var viewModel: MCPToolsBrowserViewModel

    init(registry: MCPToolRegistry) {
        _viewModel = StateObject(wrappedValue: MCPToolsBrowserViewModel(registry: registry))
    }

    var body: some View {
        NavigationSplitView {
            MCPToolsSidebar(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 280, ideal: 340)
        } detail: {
            MCPToolDetailView(viewModel: viewModel)
        }
        .navigationTitle("MCP Tools")
    }
}

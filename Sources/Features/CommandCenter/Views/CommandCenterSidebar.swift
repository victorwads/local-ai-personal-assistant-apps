import SwiftUI

struct CommandCenterSidebar: View {
    let sections: [CommandCenterSection]
    @Binding var selectedRoute: CommandCenterRoute

    var body: some View {
        List(selection: $selectedRoute) {
            ForEach(sections) { section in
                Section(section.title) {
                    ForEach(section.items) { item in
                        Label(item.title, systemImage: item.icon)
                            .tag(item.route)
                    }
                }
            }
        }
        .navigationTitle("Command Center")
        .listStyle(.sidebar)
        .frame(minWidth: 220)
    }
}

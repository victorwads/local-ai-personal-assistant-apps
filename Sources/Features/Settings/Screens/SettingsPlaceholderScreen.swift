import SwiftUI

struct SettingsPlaceholderScreen: View {
    var body: some View {
        CommandCenterPlaceholderScreen(
            title: "Settings",
            description: "Profile-scoped settings will appear here as one unified settings workspace."
        )
        // TODO: Each feature can declare its own settings section later.
        // TODO: The Settings feature should own persistence, rendering, and composition.
        // TODO: Features should not create independent settings repositories.
        // TODO: Settings should remain profile-scoped.
    }
}

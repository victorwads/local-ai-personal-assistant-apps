import SwiftUI

struct AIConnectionSettingsView: View {
    let wrapper: AIConnectionSettingsWrapper

    @State private var autoStart = false
    @State private var baseURL = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Auto Start AI Connection", isOn: autoStartBinding)
            TextField("Base URL", text: baseURLBinding)

            Text("Used later for the local AI provider connection.")
                .foregroundStyle(.secondary)
        }
        .task {
            autoStart = wrapper.autoStart
            baseURL = wrapper.baseURL
        }
    }

    private var autoStartBinding: Binding<Bool> {
        Binding {
            autoStart
        } set: { value in
            autoStart = value
            wrapper.autoStart = value
        }
    }

    private var baseURLBinding: Binding<String> {
        Binding {
            baseURL
        } set: { value in
            baseURL = value
            wrapper.baseURL = value
        }
    }
}

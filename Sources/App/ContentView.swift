import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Assistant Hub")
                .font(.largeTitle.weight(.semibold))

            Text("Project scaffold is ready. WhatsApp crawling lives under Features/WhatsAppCrawling.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 640, minHeight: 360, alignment: .topLeading)
    }
}

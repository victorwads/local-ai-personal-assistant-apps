import SwiftUI

struct DSCodeBlock: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

import Foundation

struct ChatIdGenerator {
    func makeIdentifier(from normalizedTitle: String) -> String {
        let folded = normalizedTitle
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsed = folded
            .replacingOccurrences(of: #"[\s_]+"#, with: "-", options: .regularExpression)
            .replacingOccurrences(of: #"[^a-zA-Z0-9\-]+"#, with: "", options: .regularExpression)
        return collapsed.lowercased()
    }
}

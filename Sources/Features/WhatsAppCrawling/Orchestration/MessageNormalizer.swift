import Foundation

struct NormalizedMessage: Equatable, Sendable {
    let text: String?
    let timestampText: String?
    let authorName: String?
    let direction: String?
    let kind: String?
    let status: String?
    let rawPosition: Int?
}

struct MessageNormalizer {
    func normalize(_ message: CrawledMessage) -> NormalizedMessage {
        NormalizedMessage(
            text: message.rawText?.trimmingCharacters(in: .whitespacesAndNewlines),
            timestampText: message.rawTimestampText?.trimmingCharacters(in: .whitespacesAndNewlines),
            authorName: message.rawAuthorName?.trimmingCharacters(in: .whitespacesAndNewlines),
            direction: message.rawDirection?.trimmingCharacters(in: .whitespacesAndNewlines),
            kind: message.rawKind?.trimmingCharacters(in: .whitespacesAndNewlines),
            status: message.rawStatus?.trimmingCharacters(in: .whitespacesAndNewlines),
            rawPosition: message.rawPosition
        )
    }
}

import Foundation

struct SensitiveDataItem: Codable, Equatable, Sendable {
    let id: String
    let label: String?
    let value: String
    let issueId: String?
    let allowedChatIds: [String]
}

import Foundation

struct Memory: Codable, Equatable, Sendable {
    let id: String
    let kind: String?
    let title: String?
    let value: String
    let updatedAt: Date?
}

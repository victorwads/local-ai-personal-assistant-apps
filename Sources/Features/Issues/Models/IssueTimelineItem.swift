import Foundation

struct IssueTimelineItem: Codable, Equatable, Sendable {
    let id: String
    let issueId: String
    let kind: String?
    let summary: String?
    let createdAt: Date
}

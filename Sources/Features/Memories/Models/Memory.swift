import Foundation

struct Memory: PersistableModel, Equatable, Sendable {
    @DocumentID var id: String?
    var kind: String?
    var title: String?
    var value: String
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}

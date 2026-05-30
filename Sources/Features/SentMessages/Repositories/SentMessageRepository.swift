import Foundation

final class FirestoreSentMessageRepository: FirestoreRepository<SentMessage> {
    init(scope: FirebaseProfileScope) {
        super.init(
            entityName: "SentMessage",
            path: .profileScoped(scope: scope, collection: "SentMessages")
        )
    }

    func listAll() async throws -> [SentMessage] {
        try await query(sortedBy: [FirestoreRepositorySort(field: "_createdAt", descending: true)])
    }

    // TODO create firestore compose index
    func listByIssueId(_ issueId: String) async throws -> [SentMessage] {
        try await query(
            matching: ["issueId": issueId],
            sortedBy: [FirestoreRepositorySort(field: "_createdAt", descending: true)]
        )
    }

    // Why?
    func listByTarget(
        targetKind: SentMessageTargetKind,
        targetId: String
    ) async throws -> [SentMessage] {
        try await query(
            matching: [
                "targetKind": targetKind.rawValue,
                "targetId": targetId
            ],
            sortedBy: [FirestoreRepositorySort(field: "_createdAt", descending: true)]
        )
    }
}

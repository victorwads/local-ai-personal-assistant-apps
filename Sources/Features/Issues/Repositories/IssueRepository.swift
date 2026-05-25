import Foundation

protocol IssueRepository {
    func fetchIssue(id: String) async throws -> Issue?
    func listIssues() async throws -> [Issue]
    func saveIssue(_ issue: Issue) async throws
    func deleteIssue(id: String) async throws
}

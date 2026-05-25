import Foundation

protocol SensitiveDataRepository {
    func fetchItem(id: String) async throws -> SensitiveDataItem?
    func listItems() async throws -> [SensitiveDataItem]
    func saveItem(_ item: SensitiveDataItem) async throws
    func deleteItem(id: String) async throws
    func listUsage(for itemId: String) async throws -> [SensitiveDataUsage]
}

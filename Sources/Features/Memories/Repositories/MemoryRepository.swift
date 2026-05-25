import Foundation

protocol MemoryRepository {
    func fetchMemory(id: String) async throws -> Memory?
    func listMemories() async throws -> [Memory]
    func saveMemory(_ memory: Memory) async throws
    func deleteMemory(id: String) async throws
}

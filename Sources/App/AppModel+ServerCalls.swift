import Foundation

extension AppModel {
    private var serverCallsInMemoryLimit: Int { 2_000 }

    func appendServerCall(_ entry: MCPServerCallEntry) {
        serverCalls.append(entry)

        if serverCalls.count > serverCallsInMemoryLimit {
            serverCalls.removeFirst(serverCalls.count - serverCallsInMemoryLimit)
        }

        Task {
            await serverCallStore.append(entry)
        }
    }

    func clearServerCalls() {
        serverCalls.removeAll()
        Task {
            await serverCallStore.clear()
        }
    }

    func loadPersistedServerCalls() async {
        let loaded = await serverCallStore.loadAll()
        serverCalls = Array(loaded.suffix(serverCallsInMemoryLimit))
    }
}

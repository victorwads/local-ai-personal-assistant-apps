import Foundation

final class WhatsAppCrawlerPolling {
    private let worker: WhatsAppCrawlerWorker
    private let intervalNanoseconds: UInt64
    private var pollingTask: Task<Void, Never>?

    init(worker: WhatsAppCrawlerWorker, intervalNanoseconds: UInt64 = 30_000_000_000) {
        self.worker = worker
        self.intervalNanoseconds = intervalNanoseconds
    }

    func start() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [worker, intervalNanoseconds] in
            while !Task.isCancelled {
                _ = await worker.runCycle()
                try? await Task.sleep(nanoseconds: intervalNanoseconds)
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}

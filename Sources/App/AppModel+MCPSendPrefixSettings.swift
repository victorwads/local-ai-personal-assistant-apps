import Combine
import Foundation

extension AppModel {
    func loadMCPSendMessagePrefixSetting() {
        mcpSendMessagePrefix = MCPSendPrefixRepository.shared.load()

        $mcpSendMessagePrefix
            .dropFirst()
            .sink { [weak self] value in
                guard self != nil else { return }
                MCPSendPrefixRepository.shared.save(value)
            }
            .store(in: &cancellables)
    }

    func applyMCPSendMessagePrefixIfNeeded(_ text: String) -> String {
        let assistantName = mcpSendMessagePrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !assistantName.isEmpty else { return text }
        return "\(assistantName):\n\(text)"
    }
}

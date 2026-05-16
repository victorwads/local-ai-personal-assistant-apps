import Combine
import Foundation

extension AppModel {
    func assistantNameForMCP() -> String {
        mcpSendPrefixSettings.assistantName
    }

    func applyMCPSendMessagePrefixIfNeeded(_ text: String) -> String {
        mcpSendPrefixSettings.applyPrefixIfNeeded(text)
    }
}

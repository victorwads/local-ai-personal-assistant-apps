import Foundation

extension AppModel {
    func shutdown() async {
        guard !isShuttingDown else {
            return
        }
        isShuttingDown = true

        pollingTask?.cancel()
        pollingTask = nil
        permissionMonitorTask?.cancel()
        permissionMonitorTask = nil
        liveStatusTask?.cancel()
        liveStatusTask = nil

        closeAllDetachedWhatsAppWebWindows()
        whatsAppWebSessionStore.setSessionsEnabled(false)

        await lmStudio.pauseSession()

        if mcpServerRunning {
            await stopMCPServer()
        }

        isPolling = false
    }
}

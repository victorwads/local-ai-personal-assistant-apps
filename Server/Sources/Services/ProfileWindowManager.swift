import AppKit
import SwiftUI

@MainActor
private final class ProfileRuntime {
    let profile: AppProfile
    var appModel: AppModel
    var controller: NSWindowController?

    init(profile: AppProfile, appModel: AppModel, controller: NSWindowController? = nil) {
        self.profile = profile
        self.appModel = appModel
        self.controller = controller
    }

    var window: NSWindow? {
        controller?.window
    }

    func shutdown() async {
        await appModel.shutdown()
    }
}

@MainActor
final class ProfileWindowManager: NSObject, ObservableObject, NSWindowDelegate {
    static let shared = ProfileWindowManager()

    private enum StorageKey {
        static let homeWindowVisible = "assistant.window.home.visible.v1"
    }

    private var runtimesByProfileId: [String: ProfileRuntime] = [:]
    private var profileIdsByWindowId: [ObjectIdentifier: String] = [:]
    private weak var homeWindow: NSWindow?
    private var isTerminating = false
    private let defaults: UserDefaults = .standard
    @Published private(set) var runningProfileIds: Set<String> = []
    @Published private(set) var visibleProfileIds: Set<String> = []
    @Published private(set) var isHomeWindowVisible = true

    override init() {
        isHomeWindowVisible = defaults.object(forKey: StorageKey.homeWindowVisible) as? Bool ?? true
        super.init()
    }

    func showMainWindow(profile: AppProfile, appModel: AppModel) {
        let runtime = runtimesByProfileId[profile.id] ?? ProfileRuntime(profile: profile, appModel: appModel)
        runtimesByProfileId[profile.id] = runtime

        if let window = runtime.window {
            runningProfileIds.insert(profile.id)
            setProfileWindowVisible(profile.id, true)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = ContentView()
            .environmentObject(runtime.appModel)
            .frame(minWidth: 980, minHeight: 680)

        let hosting = NSHostingView(rootView: rootView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Assistant MCP — \(profile.displayName)"
        window.contentView = hosting
        window.isReleasedWhenClosed = false
        window.delegate = self
        profileIdsByWindowId[ObjectIdentifier(window)] = profile.id
        runningProfileIds.insert(profile.id)
        setProfileWindowVisible(profile.id, true)

        let controller = NSWindowController(window: window)
        runtime.controller = controller

        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func startBackgroundProfile(profile: AppProfile, appModel: AppModel) {
        let runtime = runtimesByProfileId[profile.id] ?? ProfileRuntime(profile: profile, appModel: appModel)
        runtime.appModel = appModel
        runtimesByProfileId[profile.id] = runtime
        runningProfileIds.insert(profile.id)
        setProfileWindowVisible(profile.id, false)
    }

    func revealMainWindow(profileId: String) {
        guard let runtime = runtimesByProfileId[profileId] else {
            return
        }

        guard let window = runtime.window else {
            showMainWindow(profile: runtime.profile, appModel: runtime.appModel)
            return
        }

        runningProfileIds.insert(profileId)
        setProfileWindowVisible(profileId, true)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showHomeWindow() {
        setHomeWindowVisible(true)

        if let window = homeWindow ?? NSApp.windows.first(where: { $0.identifier?.rawValue == "profiles" }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func hideHomeWindow() {
        setHomeWindowVisible(false)

        if let window = homeWindow ?? NSApp.windows.first(where: { $0.identifier?.rawValue == "profiles" }) {
            window.orderOut(nil)
        }
    }

    func showAllManagedWindows() {
        showHomeWindow()

        for profileId in Array(runningProfileIds) {
            revealMainWindow(profileId: profileId)
        }
    }

    func isProfileWindowVisible(profileId: String) -> Bool {
        visibleProfileIds.contains(profileId)
    }

    func stopMainWindow(profileId: String) async {
        guard let runtime = runtimesByProfileId.removeValue(forKey: profileId) else {
            runningProfileIds.remove(profileId)
            setProfileWindowVisible(profileId, false)
            return
        }

        runningProfileIds.remove(profileId)
        setProfileWindowVisible(profileId, false)
        if let window = runtime.window {
            profileIdsByWindowId.removeValue(forKey: ObjectIdentifier(window))
        }

        await runtime.shutdown()
        runtime.controller?.close()
    }

    func registerHomeWindow(_ window: NSWindow) {
        homeWindow = window
        window.delegate = self
        window.identifier = NSUserInterfaceItemIdentifier("profiles")

        if isHomeWindowVisible {
            window.makeKeyAndOrderFront(nil)
        } else {
            window.orderOut(nil)
        }
    }

    func prepareForTermination() {
        isTerminating = true
    }

    func isProfileRunning(profileId: String) -> Bool {
        runningProfileIds.contains(profileId)
    }

    nonisolated func windowShouldClose(_ sender: NSWindow) -> Bool {
        MainActor.assumeIsolated {
            if sender.identifier?.rawValue == "profiles" {
                if !isTerminating {
                    setHomeWindowVisible(false)
                }
                return true
            }
            return handleWindowShouldClose(sender)
        }
    }

    @MainActor
    private func handleWindowShouldClose(_ sender: NSWindow) -> Bool {
        let windowId = ObjectIdentifier(sender)
        guard let profileId = profileIdsByWindowId[windowId] else {
            return true
        }

        setProfileWindowVisible(profileId, false)
        sender.orderOut(nil)
        return false
    }

    nonisolated func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
            return
        }
        let windowId = ObjectIdentifier(window)
        Task { @MainActor [weak self] in
            self?.handleWindowWillClose(window: window, windowId: windowId)
        }
    }

    @MainActor
    private func handleWindowWillClose(window: NSWindow, windowId: ObjectIdentifier) {
        if window.identifier?.rawValue == "profiles" {
            guard !isTerminating else { return }
            homeWindow = nil
            return
        }

        guard let profileId = profileIdsByWindowId.removeValue(forKey: windowId) else {
            return
        }

        runningProfileIds.remove(profileId)
        visibleProfileIds.remove(profileId)
        guard let runtime = runtimesByProfileId.removeValue(forKey: profileId) else {
            return
        }

        Task { await runtime.shutdown() }
    }

    private func setProfileWindowVisible(_ profileId: String, _ isVisible: Bool) {
        if isVisible {
            visibleProfileIds.insert(profileId)
        } else {
            visibleProfileIds.remove(profileId)
        }
    }

    private func persistHomeWindowVisibility() {
        defaults.set(isHomeWindowVisible, forKey: StorageKey.homeWindowVisible)
    }

    func setHomeWindowVisible(_ isVisible: Bool) {
        isHomeWindowVisible = isVisible
        persistHomeWindowVisibility()
    }
}

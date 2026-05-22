import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import os

@MainActor
final class FirebaseBootstrap {
    static let shared = FirebaseBootstrap()

    private let logger = Logger(subsystem: "dev.wads.AssistantMCPServer", category: "Firebase")

    private(set) var isConfigured = false

    func configure() {
        guard !isRunningUnitTests else {
            logger.info("Firebase bootstrap skipped while running unit tests.")
            return
        }
        guard FirebaseApp.app() == nil else {
            isConfigured = true
            return
        }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            logger.warning("Firebase bootstrap skipped because GoogleService-Info.plist was not found in the main bundle.")
            return
        }

        FirebaseApp.configure()

        // Persistent on-disk cache so reads work fully offline after first launch
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings

        isConfigured = true
        logger.info("FirebaseApp configured. Persistent Firestore cache enabled.")
    }

    var firestore: Firestore? {
        isConfigured ? Firestore.firestore() : nil
    }

    var storage: Storage? {
        isConfigured ? Storage.storage() : nil
    }

    private var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}

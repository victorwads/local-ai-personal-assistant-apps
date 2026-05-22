import Foundation
import FirebaseFirestore
import os

/// Provides read/write access to per-profile settings stored in Firestore.
/// Reads use the local persistent cache when available (offline-first).
/// Writes go online immediately.
@MainActor
final class FirestoreSettingsService {
    private let profileID: String
    private let logger = Logger(subsystem: "dev.wads.AssistantMCPServer", category: "FirestoreSettingsService")

    private var cachedSettings: [String: Any] = [:]
    private var listenerRegistration: (any ListenerRegistration)?

    init(profileID: String) {
        self.profileID = profileID
    }

    // MARK: - Start real-time listener

    func startListening() async {
        let firestore = Firestore.firestore()
        let path = "\(FirestoreCollections.Settings(profileID))/profileDefaults"

        // Seed cachedSettings from cache first, then fall back to the server on a cold start.
        if let snapshot = try? await firestore.document(path).getDocument(source: .cache),
           let data = snapshot.data() {
            cachedSettings = data
            logger.info("Loaded \(data.count) settings from local cache for profile \(self.profileID).")
        }

        if cachedSettings.isEmpty,
           let snapshot = try? await firestore.document(path).getDocument(source: .default),
           let data = snapshot.data() {
            cachedSettings = data
            logger.info("Loaded \(data.count) settings from Firestore for profile \(self.profileID).")
        }

        // Then attach listener so future server updates arrive automatically
        listenerRegistration = firestore.document(path).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error { self.logger.error("Settings listener error: \(error.localizedDescription)"); return }
            guard let data = snapshot?.data() else { return }
            self.cachedSettings = data
            self.logger.info("Settings updated from Firestore (\(data.count) keys).")
            NotificationCenter.default.post(name: .firestoreSettingsDidChange, object: self.profileID)
        }
    }

    // MARK: - Read (always from in-memory cache — populated from Firestore persistent cache or listener)

    func value(forKey key: String) -> Any? {
        cachedSettings[key]
    }

    func string(forKey key: String) -> String? {
        cachedSettings[key] as? String
    }

    func bool(forKey key: String, default defaultValue: Bool = false) -> Bool {
        cachedSettings[key] as? Bool ?? defaultValue
    }

    func integer(forKey key: String, default defaultValue: Int = 0) -> Int {
        cachedSettings[key] as? Int ?? defaultValue
    }

    func double(forKey key: String, default defaultValue: Double = 0) -> Double {
        if let number = cachedSettings[key] as? NSNumber {
            return number.doubleValue
        }
        return cachedSettings[key] as? Double ?? defaultValue
    }

    func data(forKey key: String) -> Data? {
        cachedSettings[key] as? Data
    }

    func allSettings() -> [String: Any] {
        cachedSettings
    }

    // MARK: - Write (online, immediately)

    func set(_ value: Any?, forKey key: String) async {
        let firestore = Firestore.firestore()
        let path = "\(FirestoreCollections.Settings(profileID))/profileDefaults"
        do {
            if let value {
                try await firestore.document(path).setData([key: value], merge: true)
                cachedSettings[key] = value
            } else {
                try await firestore.document(path).setData([key: FieldValue.delete()], merge: true)
                cachedSettings.removeValue(forKey: key)
            }
        } catch {
            logger.error("Failed to write setting '\(key)': \(error.localizedDescription)")
        }
    }

    func setMultiple(_ dict: [String: Any]) async {
        guard !dict.isEmpty else { return }
        let firestore = Firestore.firestore()
        let path = "\(FirestoreCollections.Settings(profileID))/profileDefaults"
        do {
            try await firestore.document(path).setData(dict, merge: true)
            for (k, v) in dict { cachedSettings[k] = v }
        } catch {
            logger.error("Failed to write \(dict.count) settings: \(error.localizedDescription)")
        }
    }

    func remove(forKey key: String) async {
        await set(nil, forKey: key)
    }
}

// MARK: - Notification

extension Notification.Name {
    static let firestoreSettingsDidChange = Notification.Name("firestoreSettingsDidChange")
}

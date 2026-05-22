import Foundation
import FirebaseFirestore
import os

actor AppProfilesRepository {
    static let shared = AppProfilesRepository()

    private var entries: [AppProfile] = []
    private var listenerRegistration: ListenerRegistrationWrapper?
    private let logger = Logger(subsystem: "dev.wads.AssistantMCPServer", category: "AppProfilesRepository")

    // The 3 default profiles. These are written to Firestore once on first launch.
    private static let defaultProfiles: [AppProfile] = [
        AppProfile(id: "00000000-0000-0000-0000-000000000001", displayName: "Wads Nativo", isDefault: true),
        AppProfile(id: "00000000-0000-0000-0000-000000000002", displayName: "Leo Web", isDefault: false),
        AppProfile(id: "00000000-0000-0000-0000-000000000003", displayName: "Wads Web", isDefault: false)
    ]

    // MARK: - Public API

    /// Loads profiles from Firestore (cache-first). Seeds defaults on first launch. Starts listener.
    func loadOrCreateDefaultProfiles() async -> [AppProfile] {
        startListeningIfNeeded()

        let firestore = Firestore.firestore()
        let path = FirestoreCollections.profiles

        do {
            let snapshot: QuerySnapshot
            do {
                snapshot = try await firestore.collection(path).getDocuments(source: .cache)
            } catch {
                // First launch — no cache yet, go to server
                snapshot = try await firestore.collection(path).getDocuments(source: .default)
            }

            var loaded = snapshot.documents.compactMap { AppProfile.fromFirestoreData($0.data()) }

            if loaded.isEmpty {
                logger.info("No profiles in Firestore. Writing defaults...")
                for profile in Self.defaultProfiles {
                    try await upsertProfile(profile)
                }
                loaded = Self.defaultProfiles
            }

            entries = loaded.sorted { $0.id < $1.id }
            return entries

        } catch {
            logger.error("Failed to load profiles: \(error.localizedDescription)")
            return entries.isEmpty ? Self.defaultProfiles : entries
        }
    }

    func list() -> [AppProfile] {
        entries.sorted { $0.id < $1.id }
    }

    func persist(_ profile: AppProfile) async {
        do {
            try await upsertProfile(profile)
        } catch {
            logger.error("Failed to persist profile \(profile.id): \(error.localizedDescription)")
        }
    }

    func delete(id: String) async {
        do {
            let firestore = Firestore.firestore()
            try await firestore.document(FirestoreCollections.ProfileDocument(id)).delete()
        } catch {
            logger.error("Failed to delete profile \(id): \(error.localizedDescription)")
        }
    }

    // MARK: - Real-time listener

    private func startListeningIfNeeded() {
        guard listenerRegistration == nil else { return }
        let firestore = Firestore.firestore()
        let registration = firestore.collection(FirestoreCollections.profiles).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error { self.logger.error("Profiles listener error: \(error.localizedDescription)"); return }
            let updated = snapshot?.documents.compactMap { AppProfile.fromFirestoreData($0.data()) } ?? []
            Task { await self.updateEntries(updated) }
        }
        listenerRegistration = ListenerRegistrationWrapper(registration)
    }

    private func updateEntries(_ newEntries: [AppProfile]) {
        entries = newEntries.sorted { $0.id < $1.id }
        NotificationCenter.default.post(name: .appProfilesRepositoryDidChange, object: nil)
    }

    // MARK: - Firestore write

    private func upsertProfile(_ profile: AppProfile) async throws {
        let firestore = Firestore.firestore()
        try await firestore.document(FirestoreCollections.ProfileDocument(profile.id))
            .setData(profile.toFirestoreData(), merge: true)
    }
}

// MARK: - AppProfile Firestore serialization

extension AppProfile {
    func toFirestoreData() -> [String: Any] {
        [
            "id": id,
            "displayName": displayName,
            "isDefault": isDefault,
            "isAutoStart": isAutoStart,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: Date())
        ]
    }

    static func fromFirestoreData(_ data: [String: Any]) -> AppProfile? {
        guard let id = data["id"] as? String,
              let displayName = data["displayName"] as? String else { return nil }
        return AppProfile(
            id: id,
            displayName: displayName,
            isDefault: data["isDefault"] as? Bool ?? false,
            isAutoStart: data["isAutoStart"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Notification

extension Notification.Name {
    static let appProfilesRepositoryDidChange = Notification.Name("appProfilesRepositoryDidChange")
}

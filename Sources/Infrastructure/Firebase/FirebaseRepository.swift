import Foundation
import FirebaseFirestore

public enum FirebaseRepositoryReadSource: Equatable {
    case `default`
    case cacheOnly
}

enum FirebaseRepositoryMetadataField {
    static let createdAt = "_createdAt"
    static let updatedAt = "_updatedAt"
    static let deletedAt = "_deletedAt"
}

open class FirebaseRepository<Model: PersistableModel> {
    public let entityName: String
    public let path: FirebaseRepositoryPath
    public let collection: CollectionReference

    private let firestore: Firestore
    private let dateProvider: () -> Date
    private let readSource: FirebaseRepositoryReadSource

    public init(
        entityName: String,
        path: FirebaseRepositoryPath,
        firestore: Firestore = .firestore(),
        readSource: FirebaseRepositoryReadSource = .cacheOnly,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.entityName = entityName
        self.path = path
        self.firestore = firestore
        self.collection = firestore.collection(path.collectionPath)
        self.dateProvider = dateProvider
        self.readSource = readSource
    }

    open func getAll(includeDeleted: Bool = false) async throws -> [Model] {
        let snapshot: QuerySnapshot
        switch readSource {
        case .default:
            snapshot = try await collection.getDocuments()
        case .cacheOnly:
            snapshot = try await collection.getDocuments(source: .cache)
        }

        let records = try snapshot.documents.map { document in
            try decode(document: document)
        }

        if includeDeleted {
            return records.map(\.model)
        }
        return records.filter { !$0.isDeleted }.map(\.model)
    }

    open func getById(_ id: String) async throws -> Model? {
        let snapshot: DocumentSnapshot
        do {
            switch readSource {
            case .default:
                snapshot = try await documentReference(for: id).getDocument()
            case .cacheOnly:
                snapshot = try await documentReference(for: id).getDocument(source: .cache)
            }
        } catch {
            if readSource == .cacheOnly {
                return nil
            }
            throw error
        }

        guard snapshot.exists else {
            return nil
        }

        let record = try decode(document: snapshot)
        guard !record.isDeleted else {
            return nil
        }
        return record.model
    }

    @discardableResult
    open func save(_ model: Model, merge: Bool = true) async throws -> Model {
        var record = model
        let isCreating = record.id?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true

        if isCreating {
            record.id = collection.document().documentID
        }

        let document = try documentReference(for: record.id)
        let now = dateProvider()
        let payload = try makePayload(
            from: record,
            isCreating: isCreating,
            now: now
        )

        try await document.setData(payload, merge: merge)
        return record
    }

    open func saveAll(_ models: [Model]) async throws {
        guard !models.isEmpty else {
            return
        }

        let batch = firestore.batch()
        let now = dateProvider()

        for model in models {
            var record = model
            let isCreating = record.id?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
            if isCreating {
                record.id = collection.document().documentID
            }

            guard let documentID = record.id, !documentID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw FirestoreRepositoryError.missingDocumentId
            }

            let payload = try makePayload(
                from: record,
                isCreating: isCreating,
                now: now
            )

            let document = collection.document(documentID)
            batch.setData(payload, forDocument: document, merge: true)
        }

        try await batch.commit()
    }

    open func updateAll(ids: [String], data: [String: Any]) async throws {
        guard !ids.isEmpty else {
            return
        }

        let payload = makeUpdatePayload(from: data)
        let batch = firestore.batch()

        for id in ids {
            let document = try documentReference(for: id)
            batch.updateData(payload, forDocument: document)
        }

        try await batch.commit()
    }

    open func delete(_ id: String, soft: Bool = false) async throws {
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FirestoreRepositoryError.missingDocumentId
        }

        let reference = try documentReference(for: id)

        if soft {
            let now = dateProvider()
            try await reference.updateData([
                FirebaseRepositoryMetadataField.deletedAt: now,
                FirebaseRepositoryMetadataField.updatedAt: now
            ])
        } else {
            try await reference.delete()
        }
    }

    open func observe(_ listener: @escaping ([Model]) -> Void) -> FirestoreListenerToken {
        let registration = collection.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            guard let snapshot else {
                if let error {
                    print("Failed to observe \(self.entityName): \(error.localizedDescription)")
                }
                listener([])
                return
            }

            do {
                let records = try snapshot.documents.map { document in
                    try self.decode(document: document)
                }
                listener(records.filter { !$0.isDeleted }.map(\.model))
            } catch {
                print("Failed to decode \(self.entityName) snapshot: \(error.localizedDescription)")
                listener([])
            }
        }

        return FirestoreListenerToken {
            registration.remove()
        }
    }

    private func documentReference(for id: String?) throws -> DocumentReference {
        guard path.isValid else {
            throw FirestoreRepositoryError.invalidPath
        }
        guard let id, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FirestoreRepositoryError.missingDocumentId
        }
        return firestore.collection(path.collectionPath).document(id)
    }

    private func decode(document: QueryDocumentSnapshot) throws -> (model: Model, isDeleted: Bool) {
        do {
            let model = try document.data(as: Model.self)
            return (model: model, isDeleted: isDeleted(from: document.data()))
        } catch {
            throw FirestoreRepositoryError.decodingFailed(entity: entityName)
        }
    }

    private func decode(document: DocumentSnapshot) throws -> (model: Model, isDeleted: Bool) {
        do {
            let model = try document.data(as: Model.self)
            let data = document.data() ?? [:]
            return (model: model, isDeleted: isDeleted(from: data))
        } catch {
            throw FirestoreRepositoryError.decodingFailed(entity: entityName)
        }
    }

    private func makePayload(
        from model: Model,
        isCreating: Bool,
        now: Date
    ) throws -> [String: Any] {
        var payload = try Firestore.Encoder().encode(model)
        payload = removeNilFields(from: payload)

        if isCreating {
            payload[FirebaseRepositoryMetadataField.createdAt] = now
            payload[FirebaseRepositoryMetadataField.updatedAt] = now
            payload.removeValue(forKey: FirebaseRepositoryMetadataField.deletedAt)
            return payload
        }

        payload.removeValue(forKey: FirebaseRepositoryMetadataField.createdAt)
        payload[FirebaseRepositoryMetadataField.updatedAt] = now
        payload.removeValue(forKey: FirebaseRepositoryMetadataField.deletedAt)
        return payload
    }

    private func makeUpdatePayload(from data: [String: Any]) -> [String: Any] {
        var payload = removeNilFields(from: data)
        payload.removeValue(forKey: FirebaseRepositoryMetadataField.createdAt)
        payload[FirebaseRepositoryMetadataField.updatedAt] = dateProvider()
        payload.removeValue(forKey: FirebaseRepositoryMetadataField.deletedAt)
        return payload
    }

    private func removeNilFields(from data: [String: Any]) -> [String: Any] {
        var cleaned: [String: Any] = [:]
        for (key, value) in data {
            if let normalized = normalizeFirestoreValue(value) {
                cleaned[key] = normalized
            }
        }
        return cleaned
    }

    private func normalizeFirestoreValue(_ value: Any) -> Any? {
        if value is NSNull {
            return nil
        }

        if let dictionary = value as? [String: Any] {
            return removeNilFields(from: dictionary)
        }

        if let array = value as? [Any] {
            return array.compactMap { normalizeFirestoreValue($0) }
        }

        return value
    }

    private func isDeleted(from data: [String: Any]) -> Bool {
        guard let value = data[FirebaseRepositoryMetadataField.deletedAt] else {
            return false
        }

        if value is NSNull {
            return false
        }

        return true
    }
}

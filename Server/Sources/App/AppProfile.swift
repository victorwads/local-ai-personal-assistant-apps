import Foundation

struct AppProfile: Codable, Identifiable, Hashable {
    let id: String
    let displayName: String
    let isDefault: Bool
    var isAutoStart: Bool = false
    var createdAt: Date = Date()

    static let `default` = AppProfile(
        id: "00000000-0000-0000-0000-000000000001",
        displayName: "Default",
        isDefault: true
    )

    static func defaultNamed(_ name: String) -> AppProfile {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return AppProfile(
            id: "00000000-0000-0000-0000-000000000001",
            displayName: trimmed.isEmpty ? "Default" : trimmed,
            isDefault: true
        )
    }

    static func forWhatsAppWebAccount(_ account: WhatsAppWebAccount, isDefault: Bool) -> AppProfile {
        if isDefault {
            return .default
        }
        if let appProfileId = account.appProfileId {
            let mappedId: String
            switch appProfileId {
            case "default":
                mappedId = "00000000-0000-0000-0000-000000000001"
            case "profile-2":
                mappedId = "00000000-0000-0000-0000-000000000002"
            case "profile-3":
                mappedId = "00000000-0000-0000-0000-000000000003"
            default:
                if appProfileId.hasPrefix("waweb-") {
                    mappedId = String(appProfileId.dropFirst(6))
                } else {
                    mappedId = appProfileId
                }
            }
            return AppProfile(
                id: mappedId,
                displayName: account.name,
                isDefault: mappedId == Self.default.id,
                isAutoStart: account.isAutoStart,
                createdAt: account.createdAt
            )
        }
        return AppProfile(
            id: account.id.uuidString,
            displayName: account.name,
            isDefault: false,
            isAutoStart: account.isAutoStart,
            createdAt: account.createdAt
        )
    }
}

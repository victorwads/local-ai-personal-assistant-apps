import Foundation
import FirebaseFirestore

enum FirestoreCollections {
    static let profiles = "Profiles"
    static let memories = "Memories"
    static let issues = "Issues"
    static let settings = "Settings"
    static let nicknames = "Nicknames"
    static let whatszapChats = "WhatszapChats"
    static let messages = "Messages"
    static let voiceEvents = "VoiceEvents"
    static let promptQueue = "PromptQueue"
    static let promptState = "PromptState"

    static func ProfileDocument(_ profileID: String) -> String {
        "\(profiles)/\(profileID)"
    }

    static func Memories(_ profileID: String) -> String {
        "\(ProfileDocument(profileID))/\(memories)"
    }

    static func Issues(_ profileID: String) -> String {
        "\(ProfileDocument(profileID))/\(issues)"
    }

    static func Settings(_ profileID: String) -> String {
        "\(ProfileDocument(profileID))/\(settings)"
    }

    static func Nicknames(_ profileID: String) -> String {
        "\(ProfileDocument(profileID))/\(nicknames)"
    }

    static func WhatszapChats(_ profileID: String) -> String {
        "\(ProfileDocument(profileID))/\(whatszapChats)"
    }

    static func WhatszapChatDocument(_ profileID: String, chatID: String) -> String {
        "\(WhatszapChats(profileID))/\(sanitizedDocumentID(chatID))"
    }

    static func Messages(_ profileID: String, chatID: String) -> String {
        "\(WhatszapChatDocument(profileID, chatID: chatID))/\(messages)"
    }

    static func VoiceEvents(_ profileID: String) -> String {
        "\(ProfileDocument(profileID))/\(voiceEvents)"
    }

    static func PromptQueue(_ profileID: String) -> String {
        "\(ProfileDocument(profileID))/\(promptQueue)"
    }

    static func PromptStateDocument(_ profileID: String) -> String {
        "\(ProfileDocument(profileID))/\(promptState)/current"
    }

    private static func sanitizedDocumentID(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "unknown"
        }
        return trimmed.replacingOccurrences(of: "/", with: "_")
    }
}


final class ListenerRegistrationWrapper: @unchecked Sendable {
    private let registration: any ListenerRegistration
    
    init(_ registration: any ListenerRegistration) {
        self.registration = registration
    }
    
    deinit {
        registration.remove()
    }
}

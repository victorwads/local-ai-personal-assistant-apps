import Foundation

extension AppModel {
    func dumpWhatsAppSnapshot() {
        let trustedNow = accessibility.isTrusted(prompt: false)
        accessibilityTrusted = trustedNow

        guard trustedNow else {
            appendLog("Cannot inspect WhatsApp before Accessibility permission is granted to this exact app binary.", level: .warning)
            appendLog(accessibility.currentAppIdentityDescription(), level: .warning)
            appendLog("When running from Xcode, macOS may require granting permission to the built app in DerivedData and then relaunching it.", level: .warning)
            return
        }

        do {
            let snapshot = try accessibility.captureWhatsAppSnapshot(maxDepth: 14)
            writeDebugArtifacts(snapshot: snapshot, screenState: parser.parse(snapshot: snapshot, messageLimit: 10), prefix: "manual-dump")
            appendLog("Captured WhatsApp Accessibility snapshot.")
            appendLog("Wrote debug files to \(debugDirectory.path).")
            appendLog(snapshot.prettyDescription)
        } catch {
            appendLog("Failed to capture WhatsApp snapshot: \(error.localizedDescription)", level: .error)
        }
    }

    func captureDebugSnapshot() {
        guard prepareForWhatsAppInspection() else {
            return
        }

        do {
            let snapshot = try accessibility.captureWhatsAppSnapshot(maxDepth: 14)
            debugSnapshot = snapshot
            debugNodePath = []
            appendLog("Captured debug snapshot for tree view.")
        } catch {
            appendLog("Failed to capture debug snapshot: \(error.localizedDescription)", level: .error)
        }
    }

    func saveDebugSnapshot(named rawName: String) {
        guard let snapshot = debugSnapshot else {
            appendLog("No debug snapshot available to save.", level: .warning)
            return
        }

        let captureName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveName = captureName.isEmpty ? "capture" : captureName
        let screenState = parser.parse(snapshot: snapshot, messageLimit: 10)

        do {
            let capturesDirectory = debugDirectory.appendingPathComponent("captures", isDirectory: true)
            try FileManager.default.createDirectory(at: capturesDirectory, withIntermediateDirectories: true)

            let timestamp = Self.debugCaptureTimestamp(Date())
            let slug = Self.debugCaptureFileSlug(effectiveName)
            let fileURL = capturesDirectory.appendingPathComponent("\(timestamp)-\(slug).yaml")
            let contents = debugCaptureYAML(name: effectiveName, snapshot: snapshot, screenState: screenState)
            try contents.write(to: fileURL, atomically: true, encoding: .utf8)

            appendLog("Saved WhatsApp debug capture to \(fileURL.path).")
        } catch {
            appendLog("Failed to save debug capture: \(error.localizedDescription)", level: .warning)
        }
    }

    func writeDebugArtifacts(snapshot: WhatsAppSnapshot, screenState: WhatsAppScreenState, prefix: String) {
        do {
            try FileManager.default.createDirectory(at: debugDirectory, withIntermediateDirectories: true)
            try snapshot.prettyDescription.write(to: debugDirectory.appendingPathComponent("latest-snapshot.txt"), atomically: true, encoding: .utf8)
            try parser.debugReport(snapshot: snapshot).write(to: debugDirectory.appendingPathComponent("latest-parser-report.txt"), atomically: true, encoding: .utf8)
            try conversationReport(screenState).write(to: debugDirectory.appendingPathComponent("latest-state.txt"), atomically: true, encoding: .utf8)

            let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            try parser.debugReport(snapshot: snapshot).write(to: debugDirectory.appendingPathComponent("\(timestamp)-\(prefix)-parser-report.txt"), atomically: true, encoding: .utf8)
        } catch {
            appendLog("Failed to write parser debug artifacts: \(error.localizedDescription)", level: .warning)
        }
    }

    private func debugCaptureYAML(name: String, snapshot: WhatsAppSnapshot, screenState: WhatsAppScreenState) -> String {
        var lines: [String] = []
        lines.append("whatsapp_capture:")
        lines.append("  name: \(yamlScalar(name))")
        lines.append("  saved_at: \(yamlScalar(Self.debugCaptureTimestamp(Date())))")
        lines.append("  captured_at: \(yamlScalar(Self.debugCaptureTimestamp(snapshot.capturedAt)))")
        lines.append("  bundle_identifier: \(yamlScalar(snapshot.bundleIdentifier))")
        lines.append("  process_identifier: \(snapshot.processIdentifier)")
        lines.append("  focus_path: \(yamlPath(debugNodePath))")
        lines.append("  screen_state:")
        lines.append("    selected_chat_name: \(yamlScalar(screenState.selectedChatName))")
        lines.append("    compose_focused: \(yamlBool(screenState.composeFocused))")
        lines.append("    can_send_text: \(yamlBool(screenState.canSendText))")
        lines.append("    send_button_path: \(yamlPath(screenState.sendButtonPath))")
        if screenState.conversations.isEmpty {
            lines.append("    conversations: []")
        } else {
            lines.append("    conversations:")
            for conversation in screenState.conversations {
                lines.append(contentsOf: conversationCaptureLines(conversation, depth: 3))
            }
        }

        if screenState.messages.isEmpty {
            lines.append("    messages: []")
        } else {
            lines.append("    messages:")
            for message in screenState.messages {
                lines.append(contentsOf: messageCaptureLines(message, depth: 3))
            }
        }

        lines.append("  tree:")
        lines.append(contentsOf: snapshot.rootNode.yamlDescription(depth: 2).split(separator: "\n").map(String.init))
        return lines.joined(separator: "\n")
    }

    private func conversationReport(_ screenState: WhatsAppScreenState) -> String {
        let conversations = screenState.conversations.map { conversation in
            "- \(conversation.name) | unread=\(conversation.unreadCount) | date=\(conversation.lastMessageAtText ?? "nil") | preview=\(conversation.lastMessagePreview ?? "nil")"
        }.joined(separator: "\n")

        let messages = screenState.messages.map { message in
            "- \(message.direction.rawValue) \(message.status.rawValue): \(message.text ?? message.rawAccessibilityText)"
        }.joined(separator: "\n")

        return """
        Conversations:
        \(conversations.isEmpty ? "- none" : conversations)

        Messages:
        \(messages.isEmpty ? "- none" : messages)
        """
    }

    private func conversationCaptureLines(_ conversation: ConversationSummary, depth: Int) -> [String] {
        let indent = String(repeating: "  ", count: depth)
        let childIndent = indent + "  "

        return [
            "\(indent)- id: \(yamlScalar(conversation.id))",
            "\(childIndent)accessibility_path: \(yamlPath(conversation.accessibilityPath))",
            "\(childIndent)name: \(yamlScalar(conversation.name))",
            "\(childIndent)unread_count: \(conversation.unreadCount)",
            "\(childIndent)is_pinned: \(yamlBool(conversation.isPinned))",
            "\(childIndent)is_selected: \(yamlBool(conversation.isSelected))",
            "\(childIndent)last_message_preview: \(yamlScalar(conversation.lastMessagePreview))",
            "\(childIndent)last_message_at_text: \(yamlScalar(conversation.lastMessageAtText))",
            "\(childIndent)last_message_direction: \(yamlScalar(conversation.lastMessageDirection.rawValue))",
            "\(childIndent)last_message_status: \(yamlScalar(conversation.lastMessageStatus.rawValue))",
            "\(childIndent)is_typing: \(yamlBool(conversation.isTyping))"
        ]
    }

    private func messageCaptureLines(_ message: Message, depth: Int) -> [String] {
        let indent = String(repeating: "  ", count: depth)
        let childIndent = indent + "  "

        return [
            "\(indent)- id: \(yamlScalar(message.id))",
            "\(childIndent)chat_id: \(yamlScalar(message.chatId))",
            "\(childIndent)direction: \(yamlScalar(message.direction.rawValue))",
            "\(childIndent)kind: \(yamlScalar(message.kind.rawValue))",
            "\(childIndent)text: \(yamlScalar(message.text))",
            "\(childIndent)duration_seconds: \(yamlNumber(message.durationSeconds))",
            "\(childIndent)timestamp: \(yamlScalar(message.timestamp.map(Self.debugCaptureTimestamp)))",
            "\(childIndent)status: \(yamlScalar(message.status.rawValue))",
            "\(childIndent)raw_accessibility_text: \(yamlScalar(message.rawAccessibilityText))"
        ]
    }

    private func yamlScalar(_ value: String?) -> String {
        guard let value else { return "null" }
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "\"\(escaped)\""
    }

    private func yamlBool(_ value: Bool) -> String {
        value ? "true" : "false"
    }

    private func yamlNumber(_ value: Double?) -> String {
        guard let value else { return "null" }
        return String(value)
    }

    private func yamlPath(_ value: [Int]?) -> String {
        guard let value else { return "null" }
        return "[" + value.map(String.init).joined(separator: ", ") + "]"
    }

    private static func debugCaptureTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date).replacingOccurrences(of: ":", with: "-")
    }

    private static func debugCaptureFileSlug(_ value: String) -> String {
        let lowered = value.lowercased()
        let mapped = lowered.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) {
                return Character(scalar)
            }
            return "-"
        }

        let collapsed = String(mapped)
            .replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return collapsed.isEmpty ? "capture" : collapsed
    }
}

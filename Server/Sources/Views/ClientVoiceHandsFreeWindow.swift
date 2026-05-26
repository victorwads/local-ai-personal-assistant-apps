import SwiftUI

struct ClientVoiceHandsFreeWindow: View {
    @ObservedObject var appModel: AppModel
    @ObservedObject var voiceSettings: VoiceSettingsModel
    let askId: UUID
    let prompt: String
    let onDone: () -> Void

    @State private var draftResponse = ""
    @State private var isListening = false
    @State private var statusText: String?
    @State private var recognitionTask: Task<Void, Never>?
    @State private var debounceTask: Task<Void, Never>?
    @State private var restartTask: Task<Void, Never>?
    @State private var latestTranscript = ""
    @State private var receivedFinalTranscript = false
    @State private var sawSpeechStart = false
    @State private var didStartListening = false
    @State private var didResolve = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text("Client response pending")
                    .font(.headline)
                Spacer()
                Button {
                    onDone()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text(prompt)
                .font(.body)
                .lineLimit(3)

            HStack(spacing: 10) {
                TextField("Speak now… or type the response", text: $draftResponse)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.send)
                    .onSubmit { Task { await submitDraft() } }

                Button {
                    Task { await submitDraft() }
                } label: {
                    Text("Submit")
                }
                .disabled(draftResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }

            HStack(spacing: 8) {
                if isListening {
                    ProgressView()
                        .controlSize(.small)
                    Text("Listening…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let statusText {
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Hands-free is enabled. Waiting for your response.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(14)
        .task(id: appModel.speechSynthesizerSpeaking) {
            guard !PreviewSupport.isRunningForPreviews else { return }
            await handleSpeechStateChange()
        }
        .task {
            guard !PreviewSupport.isRunningForPreviews else { return }
            if let persisted = await appModel.clientVoiceEventsRepository.draftForAsk(id: askId) {
                draftResponse = persisted
            }
        }
        .onDisappear { stopRecognition() }
    }

    private func handleSpeechStateChange() async {
        if appModel.speechSynthesizerSpeaking {
            sawSpeechStart = true
            return
        }

        guard sawSpeechStart else { return }
        guard !didStartListening else { return }
        didStartListening = true
        startHandsFreeListening()
    }

    private func startHandsFreeListening() {
        recognitionTask?.cancel()
        debounceTask?.cancel()
        restartTask?.cancel()
        statusText = nil
        isListening = true
        didResolve = false

        recognitionTask = Task { @MainActor in
            do {
                try await appModel.voiceAssistant.startListening(
                    recognitionLocaleIdentifier: voiceSettings.recognitionLocaleIdentifier,
                    onPartial: { partial in
                        guard !didResolve else { return }
                        latestTranscript = partial
                        receivedFinalTranscript = false
                        draftResponse = partial
                        Task { await appModel.clientVoiceEventsRepository.updateAskDraft(id: askId, draft: partial) }
                        scheduleAutoSubmit()
                    },
                    onFinal: { final in
                        Task { @MainActor in
                            latestTranscript = final
                            receivedFinalTranscript = true
                            await finalizeRecognizedText(final, closeWindow: true)
                        }
                    },
                    onError: { error in
                        Task { @MainActor in
                            handleRecognitionError(error)
                        }
                    }
                )
            } catch {
                recognitionTask = nil
                isListening = false
                statusText = error.localizedDescription
            }
        }
    }

    private func scheduleAutoSubmit() {
        debounceTask?.cancel()
        let debounceSeconds = max(0.5, appModel.handsFreeClientVoiceSettings.debounceSeconds)

        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(debounceSeconds))
            guard !Task.isCancelled else { return }
            if !receivedFinalTranscript {
                try? await Task.sleep(for: .seconds(0.8))
                guard !Task.isCancelled else { return }
            }
            await finalizeRecognizedText(latestTranscript, closeWindow: true)
        }
    }

    private func handleRecognitionError(_ error: VoiceAssistantError) {
        debounceTask?.cancel()
        recognitionTask = nil

        guard isNoSpeechDetected(error) else {
            isListening = false
            statusText = error.localizedDescription
            return
        }

        scheduleRecognitionRestart()
    }

    private func stopRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        debounceTask?.cancel()
        debounceTask = nil
        restartTask?.cancel()
        restartTask = nil
        Task { @MainActor in
            appModel.voiceAssistant.stopListening()
        }
    }

    private func scheduleRecognitionRestart() {
        restartTask?.cancel()
        statusText = nil
        isListening = true

        restartTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.75))
            guard !Task.isCancelled, !didResolve else { return }
            startHandsFreeListening()
        }
    }

    private func isNoSpeechDetected(_ error: VoiceAssistantError) -> Bool {
        guard case .recognitionFailed(let description) = error else { return false }
        let normalized = description.lowercased()
        return normalized.contains("no speech detected")
            || normalized.contains("speech was detected")
            || normalized.contains("didn't detect any speech")
            || normalized.contains("did not detect any speech")
    }

    private func finalizeRecognizedText(_ text: String, closeWindow: Bool) async {
        guard !didResolve else { return }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        didResolve = true
        debounceTask?.cancel()
        debounceTask = nil
        recognitionTask = nil

        appModel.voiceAssistant.stopListening()

        do {
            _ = try await appModel.clientVoiceEventsRepository.answerAsk(id: askId, response: trimmed)
            await appModel.refreshPendingClientAskCount()
            isListening = false
            statusText = nil
            if closeWindow {
                onDone()
            }
        } catch {
            didResolve = false
            isListening = false
            statusText = error.localizedDescription
        }
    }

    private func submitDraft() async {
        await finalizeRecognizedText(draftResponse, closeWindow: true)
    }
}

#Preview {
    let appModel = AppModel.preview
    return ClientVoiceHandsFreeWindow(
        appModel: appModel,
        voiceSettings: appModel.voiceSettings,
        askId: UUID(),
        prompt: "Você pode confirmar o endereço de entrega?",
        onDone: {}
    )
    .frame(width: 560)
    .padding()
}

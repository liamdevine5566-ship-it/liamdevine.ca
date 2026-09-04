import Foundation

enum DictationState: Equatable {
    case idle
    case recording
    case transcribing
    case cleaningUp
    case inserting
    case error(String)
}

/// Ties the whole pipeline together: hold hotkey → record → transcribe →
/// (optionally) clean up → insert. Owns the `DictationState` the HUD and
/// menu bar icon observe.
@MainActor
final class RecordingController: ObservableObject {
    @Published private(set) var state: DictationState = .idle

    private let hotkeyMonitor: HotkeyMonitor
    private let audioRecorder: AudioRecorder
    private let transcriptionService: TranscriptionService
    private let cleanupService: CleanupService
    private let textInserter: TextInserter
    private let settings: AppSettings
    private let permissions: PermissionsManager

    private var pipelineTask: Task<Void, Never>?
    private var errorResetTask: Task<Void, Never>?

    init(
        hotkeyMonitor: HotkeyMonitor,
        audioRecorder: AudioRecorder,
        transcriptionService: TranscriptionService,
        cleanupService: CleanupService,
        textInserter: TextInserter,
        settings: AppSettings = .shared,
        permissions: PermissionsManager = .shared
    ) {
        self.hotkeyMonitor = hotkeyMonitor
        self.audioRecorder = audioRecorder
        self.transcriptionService = transcriptionService
        self.cleanupService = cleanupService
        self.textInserter = textInserter
        self.settings = settings
        self.permissions = permissions

        hotkeyMonitor.onKeyDown = { [weak self] in self?.beginRecording() }
        hotkeyMonitor.onKeyUp = { [weak self] in self?.finishRecording() }
    }

    func start() {
        hotkeyMonitor.start()
    }

    func stop() {
        hotkeyMonitor.stop()
        if audioRecorder.isRecording {
            audioRecorder.stop()
        }
        state = .idle
    }

    private func beginRecording() {
        guard state == .idle else { return }
        permissions.refresh()
        guard permissions.allGranted else {
            showError("Grant Microphone & Accessibility access in Settings first")
            return
        }

        audioRecorder.preferredInputDeviceUID = settings.preferredInputDeviceUID
        do {
            try audioRecorder.start()
            state = .recording
        } catch {
            showError("Couldn't start recording: \(error.localizedDescription)")
        }
    }

    private func finishRecording() {
        guard state == .recording else { return }
        let samples = audioRecorder.stop()

        guard !samples.isEmpty else {
            state = .idle
            return
        }

        state = .transcribing
        pipelineTask?.cancel()
        pipelineTask = Task { [weak self] in
            await self?.runPipeline(samples: samples)
        }
    }

    private func runPipeline(samples: [Float]) async {
        do {
            let rawTranscript = try await transcriptionService.transcribe(samples: samples)
            let trimmed = rawTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                state = .idle
                return
            }

            var finalText = trimmed
            if settings.aiCleanupEnabled {
                state = .cleaningUp
                do {
                    finalText = try await cleanupService.cleanUp(transcript: trimmed)
                } catch {
                    // Cleanup is a nice-to-have; fall back to the raw
                    // transcript rather than losing the dictation entirely.
                    print("Echo: cleanup failed, inserting raw transcript instead: \(error)")
                    finalText = trimmed
                }
            }

            state = .inserting
            textInserter.insert(text: finalText)
            state = .idle
        } catch {
            showError("Transcription failed: \(error.localizedDescription)")
        }
    }

    private func showError(_ message: String) {
        state = .error(message)
        errorResetTask?.cancel()
        errorResetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            guard let self, !Task.isCancelled else { return }
            if case .error = self.state {
                self.state = .idle
            }
        }
    }
}

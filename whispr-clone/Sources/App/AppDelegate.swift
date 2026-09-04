import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var recordingController: RecordingController!
    private var menuBarController: MenuBarController!
    private var hudOverlayWindow: HUDOverlayWindow!
    private var transcriptionService: WhisperKitTranscriptionService!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = AppSettings.shared
        let permissions = PermissionsManager.shared

        let hotkeyMonitor = HotkeyMonitor(keyCode: settings.pushToTalkKeyCode)
        let audioRecorder = AudioRecorder()
        let transcriptionService = WhisperKitTranscriptionService()
        let cleanupService = ClaudeCleanupService()
        let textInserter = TextInserter()

        self.transcriptionService = transcriptionService

        let recordingController = RecordingController(
            hotkeyMonitor: hotkeyMonitor,
            audioRecorder: audioRecorder,
            transcriptionService: transcriptionService,
            cleanupService: cleanupService,
            textInserter: textInserter,
            settings: settings,
            permissions: permissions
        )
        self.recordingController = recordingController

        // Keep the hotkey monitor in sync if the user rebinds it in Settings.
        settings.$pushToTalkKeyCode
            .dropFirst()
            .sink { keyCode in
                hotkeyMonitor.updateKeyCode(keyCode)
            }
            .store(in: &cancellables)

        menuBarController = MenuBarController(recordingController: recordingController)
        hudOverlayWindow = HUDOverlayWindow(recordingController: recordingController)

        recordingController.start()
        permissions.startPolling()

        // Warm the transcription model in the background so the *first*
        // push-to-talk isn't stuck waiting on a multi-second model load.
        Task {
            do {
                try await transcriptionService.preload()
            } catch {
                print("Echo: failed to preload WhisperKit model: \(error)")
            }
        }

        // Only actually prompts if the user hasn't decided yet — see
        // PermissionsManager.
        permissions.requestMicrophoneAccess { _ in }
    }

    func applicationWillTerminate(_ notification: Notification) {
        recordingController?.stop()
        PermissionsManager.shared.stopPolling()
    }

    private var cancellables = Set<AnyCancellable>()
}

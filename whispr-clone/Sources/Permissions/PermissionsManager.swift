import AVFoundation
import ApplicationServices
import Foundation

/// Echo needs three OS permissions to work at all:
///   1. Microphone        — to capture what you say
///   2. Accessibility     — to hear the global push-to-talk hotkey and to
///                          insert text into whatever app is frontmost
///   3. Input Monitoring  — global key events are also gated behind this on
///                          modern macOS; granting Accessibility usually
///                          prompts for this too
///
/// None of these can be requested silently — the user has to flip them on
/// in System Settings. This type checks current status and can jump the
/// user straight to the right settings pane.
final class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()

    @Published private(set) var microphoneAuthorized: Bool = false
    @Published private(set) var accessibilityAuthorized: Bool = false

    private var pollTimer: Timer?

    init() {
        refresh()
    }

    func refresh() {
        microphoneAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        accessibilityAuthorized = AXIsProcessTrusted()
    }

    /// Triggers the system microphone permission prompt if not yet decided.
    func requestMicrophoneAccess(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphoneAuthorized = true
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.microphoneAuthorized = granted
                    completion(granted)
                }
            }
        default:
            microphoneAuthorized = false
            completion(false)
        }
    }

    /// Accessibility can't be granted programmatically. This prompts macOS
    /// to show its "Echo would like to control this computer" dialog, which
    /// adds Echo to the Accessibility list (still off) so the user just has
    /// to flip the switch rather than hunt for the app themselves.
    func promptForAccessibilityAccess() {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        accessibilityAuthorized = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Starts polling permission status while an onboarding window is open,
    /// since macOS doesn't push a notification when the user flips the
    /// switch in System Settings themselves.
    func startPolling(interval: TimeInterval = 1.0) {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    var allGranted: Bool {
        microphoneAuthorized && accessibilityAuthorized
    }
}

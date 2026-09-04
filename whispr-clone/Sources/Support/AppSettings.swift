import Foundation
import Carbon.HIToolbox

/// Persisted, non-secret user preferences. The Claude API key is NOT stored
/// here — it lives in the Keychain via `KeychainStore`.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let pushToTalkKeyCode = "pushToTalkKeyCode"
        static let aiCleanupEnabled = "aiCleanupEnabled"
        static let preferredInputDeviceUID = "preferredInputDeviceUID"
    }

    /// Default push-to-talk key: Right Option. Chosen because it's rarely
    /// bound to anything else and is comfortable to hold with the same hand
    /// that's on the mouse/trackpad.
    static let defaultKeyCode = UInt16(kVK_RightOption)

    @Published var pushToTalkKeyCode: UInt16 {
        didSet { defaults.set(Int(pushToTalkKeyCode), forKey: Keys.pushToTalkKeyCode) }
    }

    /// When true, the raw transcript is sent to Claude for spelling/grammar/
    /// punctuation cleanup and filler-word removal before insertion. When
    /// false, the raw WhisperKit transcript is inserted as-is.
    @Published var aiCleanupEnabled: Bool {
        didSet { defaults.set(aiCleanupEnabled, forKey: Keys.aiCleanupEnabled) }
    }

    @Published var preferredInputDeviceUID: String? {
        didSet { defaults.set(preferredInputDeviceUID, forKey: Keys.preferredInputDeviceUID) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: Keys.pushToTalkKeyCode) != nil {
            self.pushToTalkKeyCode = UInt16(defaults.integer(forKey: Keys.pushToTalkKeyCode))
        } else {
            self.pushToTalkKeyCode = Self.defaultKeyCode
        }

        // Default ON: the user asked specifically for spelling/grammar/
        // punctuation cleanup and filler-word removal in v1.
        if defaults.object(forKey: Keys.aiCleanupEnabled) != nil {
            self.aiCleanupEnabled = defaults.bool(forKey: Keys.aiCleanupEnabled)
        } else {
            self.aiCleanupEnabled = true
        }

        self.preferredInputDeviceUID = defaults.string(forKey: Keys.preferredInputDeviceUID)
    }
}

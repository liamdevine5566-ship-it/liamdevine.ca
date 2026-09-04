import AppKit
import Carbon.HIToolbox

/// Watches for a single physical key being held down and released, system-wide.
///
/// Defaults to Right Option, a pure modifier key: holding it doesn't type
/// anything or trigger another app's shortcut, so we can watch it via
/// `NSEvent` global/local monitors without needing to swallow the event
/// (which would require a lower-level `CGEventTap`). If a user rebinds the
/// hotkey to a regular key later, note that this monitor *observes* the key
/// but can't prevent it from also reaching the frontmost app — swallowing
/// input requires a CGEventTap and is a reasonable v2 upgrade.
final class HotkeyMonitor {
    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    private(set) var keyCode: UInt16
    private var isDown = false

    private var globalMonitor: Any?
    private var localMonitor: Any?

    /// Modifier keys report state changes via `.flagsChanged`, not
    /// `.keyDown`/`.keyUp`, and there's no single flag per physical key
    /// (e.g. left vs right Option share `.option`). We check the raw
    /// `keyCode` on the flagsChanged event instead, which macOS does
    /// populate, and infer press/release from whether the *specific*
    /// modifier's bit is present.
    /// Which `NSEvent.ModifierFlags` bit corresponds to each modifier keyCode.
    /// Left/right variants of the same key (e.g. Option / Right Option)
    /// share one bit — holding both simultaneously is an unsupported edge
    /// case for v1.
    private static let modifierFlagByKeyCode: [UInt16: NSEvent.ModifierFlags] = [
        UInt16(kVK_Option): .option, UInt16(kVK_RightOption): .option,
        UInt16(kVK_Command): .command, UInt16(kVK_RightCommand): .command,
        UInt16(kVK_Control): .control, UInt16(kVK_RightControl): .control,
        UInt16(kVK_Shift): .shift, UInt16(kVK_RightShift): .shift,
        UInt16(kVK_Function): .function,
    ]

    init(keyCode: UInt16 = AppSettings.defaultKeyCode) {
        self.keyCode = keyCode
    }

    func updateKeyCode(_ newKeyCode: UInt16) {
        keyCode = newKeyCode
        isDown = false
    }

    func start() {
        stop()

        let mask: NSEvent.EventTypeMask = [.flagsChanged, .keyDown, .keyUp]

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
        isDown = false
    }

    private func handle(_ event: NSEvent) {
        guard event.keyCode == keyCode else { return }

        if let flag = Self.modifierFlagByKeyCode[keyCode] {
            guard event.type == .flagsChanged else { return }
            setDown(event.modifierFlags.contains(flag))
        } else {
            switch event.type {
            case .keyDown where !event.isARepeat:
                setDown(true)
            case .keyUp:
                setDown(false)
            default:
                break
            }
        }
    }

    private func setDown(_ down: Bool) {
        guard down != isDown else { return }
        isDown = down
        if down {
            onKeyDown?()
        } else {
            onKeyUp?()
        }
    }
}

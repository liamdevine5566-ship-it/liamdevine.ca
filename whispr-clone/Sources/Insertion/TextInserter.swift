import AppKit
import Carbon.HIToolbox

/// Inserts text into whatever app is currently frontmost, at the current
/// text cursor (or replacing the current selection, if any) — because a
/// real ⌘V is exactly that: the OS itself decides where it lands, same as
/// if the user had pressed paste themselves.
///
/// This goes through the clipboard + a synthetic Cmd+V rather than the
/// Accessibility "set the value of the focused element" API, for two
/// reasons: (1) AX value-setting *replaces the entire field's contents*,
/// ignoring cursor position entirely — wrong for "insert where my cursor
/// is" — and (2) a lot of real-world apps (Electron apps, Chrome-based
/// ones, many custom text editors) either don't implement
/// `kAXValueAttribute` as settable or handle it inconsistently. Clipboard +
/// paste works almost everywhere because it's the same path a human
/// pasting text uses.
final class TextInserter {
    private let pasteboard = NSPasteboard.general

    func insert(text: String) {
        let previous = capturePasteboard()

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        synthesizePaste()

        // Give the target app a moment to actually read the pasteboard
        // before we put the user's previous clipboard contents back.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.restorePasteboard(previous)
        }
    }

    private func capturePasteboard() -> [NSPasteboard.PasteboardType: Data] {
        var saved: [NSPasteboard.PasteboardType: Data] = [:]
        for type in pasteboard.types ?? [] {
            if let data = pasteboard.data(forType: type) {
                saved[type] = data
            }
        }
        return saved
    }

    private func restorePasteboard(_ saved: [NSPasteboard.PasteboardType: Data]) {
        guard !saved.isEmpty else { return }
        pasteboard.clearContents()
        for (type, data) in saved {
            pasteboard.setData(data, forType: type)
        }
    }

    private func synthesizePaste() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }

        let vKeyCode = CGKeyCode(kVK_ANSI_V)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

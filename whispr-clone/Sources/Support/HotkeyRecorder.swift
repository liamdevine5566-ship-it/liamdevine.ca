import AppKit

/// One-shot capture of "the next key the user presses," used by Settings to
/// let someone rebind push-to-talk without typing a key code by hand.
final class HotkeyRecorder {
    private var monitor: Any?

    func start(onCapture: @escaping (UInt16) -> Void) {
        stop()
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard event.keyCode != 0 || event.type == .flagsChanged else { return }
            onCapture(event.keyCode)
            self?.stop()
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    deinit {
        stop()
    }
}

import AppKit
import Combine
import SwiftUI

/// A borderless, click-through panel floating above all other windows near
/// the bottom of the screen, showing `HUDView`. Never becomes key/main so
/// it can never steal focus from whatever app the user is dictating into.
@MainActor
final class HUDOverlayWindow {
    private let panel: NSPanel
    private var cancellable: AnyCancellable?

    init(recordingController: RecordingController) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 44),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false

        self.panel = panel

        cancellable = recordingController.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.update(for: state)
            }
    }

    private func update(for state: DictationState) {
        if state == .idle {
            panel.orderOut(nil)
            return
        }

        let hostingView = NSHostingView(rootView: HUDView(state: state))
        panel.contentView = hostingView
        hostingView.layout()
        panel.setContentSize(hostingView.fittingSize)
        positionPanel()
        panel.orderFrontRegardless()
    }

    private func positionPanel() {
        guard let screen = NSScreen.main else { return }
        let panelSize = panel.frame.size
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - panelSize.width / 2
        let y = screenFrame.minY + 60
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

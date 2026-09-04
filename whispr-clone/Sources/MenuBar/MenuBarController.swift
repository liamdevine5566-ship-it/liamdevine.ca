import AppKit
import Combine
import SwiftUI

/// Owns the status-bar icon and its settings popover. The icon's SF Symbol
/// reflects `RecordingController.state` so there's always a glanceable
/// answer to "is it listening right now?" even without the floating HUD.
@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let recordingController: RecordingController
    private var cancellable: AnyCancellable?

    init(recordingController: RecordingController) {
        self.recordingController = recordingController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        configureStatusItem()
        configurePopover()
        observeState()
    }

    private func configureStatusItem() {
        statusItem.button?.image = NSImage(
            systemSymbolName: "mic.fill",
            accessibilityDescription: "Echo"
        )
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 360)
        popover.contentViewController = NSHostingController(
            rootView: SettingsView()
                .environmentObject(AppSettings.shared)
                .environmentObject(PermissionsManager.shared)
        )
    }

    private func observeState() {
        cancellable = recordingController.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateIcon(for: state)
            }
    }

    private func updateIcon(for state: DictationState) {
        let symbolName: String
        switch state {
        case .idle: symbolName = "mic.fill"
        case .recording: symbolName = "waveform"
        case .transcribing, .cleaningUp: symbolName = "ellipsis.circle"
        case .inserting: symbolName = "checkmark.circle"
        case .error: symbolName = "exclamationmark.triangle.fill"
        }
        statusItem.button?.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Echo")
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            PermissionsManager.shared.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}

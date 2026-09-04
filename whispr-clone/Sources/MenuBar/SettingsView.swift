import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var permissions: PermissionsManager

    @State private var apiKeyText: String = KeychainStore.loadAPIKey() ?? ""
    @State private var isCapturingHotkey = false
    @State private var inputDevices: [AudioDeviceSelector.Device] = []
    private let hotkeyRecorder = HotkeyRecorder()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            permissionsSection

            Divider()

            hotkeySection

            Toggle("Clean up dictation with Claude", isOn: $settings.aiCleanupEnabled)
                .help("Fixes spelling, grammar, and punctuation, and removes filler words like \"um\" — before the text is inserted.")

            apiKeySection

            inputDeviceSection

            Spacer()
        }
        .padding(16)
        .frame(width: 320)
        .onAppear {
            permissions.refresh()
            inputDevices = AudioDeviceSelector.listInputDevices()
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "mic.fill")
            Text("Echo")
                .font(.headline)
            Spacer()
            Text("v0.1.0")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            permissionRow(
                title: "Microphone",
                granted: permissions.microphoneAuthorized,
                action: { permissions.requestMicrophoneAccess { _ in } }
            )
            permissionRow(
                title: "Accessibility",
                granted: permissions.accessibilityAuthorized,
                action: { permissions.promptForAccessibilityAccess() }
            )
        }
    }

    private func permissionRow(title: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(granted ? .green : .red)
            Text(title)
            Spacer()
            if !granted {
                Button("Grant…", action: action)
                    .controlSize(.small)
            }
        }
        .font(.callout)
    }

    private var hotkeySection: some View {
        HStack {
            Text("Push-to-talk key")
            Spacer()
            Button(isCapturingHotkey ? "Press a key…" : KeyCodeNaming.displayName(for: settings.pushToTalkKeyCode)) {
                beginCapturingHotkey()
            }
            .disabled(isCapturingHotkey)
        }
    }

    private func beginCapturingHotkey() {
        isCapturingHotkey = true
        hotkeyRecorder.start { keyCode in
            DispatchQueue.main.async {
                settings.pushToTalkKeyCode = keyCode
                isCapturingHotkey = false
            }
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Claude API key")
                .font(.caption)
                .foregroundStyle(.secondary)
            SecureField("sk-ant-...", text: $apiKeyText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: apiKeyText) { _, newValue in
                    if newValue.isEmpty {
                        KeychainStore.deleteAPIKey()
                    } else {
                        KeychainStore.saveAPIKey(newValue)
                    }
                }
            Text("Stored in your Keychain. Only used for the cleanup pass — get a key at console.anthropic.com.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var inputDeviceSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Microphone")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("Microphone", selection: Binding(
                get: { settings.preferredInputDeviceUID ?? "" },
                set: { settings.preferredInputDeviceUID = $0.isEmpty ? nil : $0 }
            )) {
                Text("System Default").tag("")
                ForEach(inputDevices) { device in
                    Text(device.name).tag(device.uid)
                }
            }
            .labelsHidden()
        }
    }
}

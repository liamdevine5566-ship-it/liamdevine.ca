import SwiftUI

/// Small floating pill shown while Echo is recording/processing, similar in
/// spirit to Wispr Flow's own overlay — a glanceable "yes, it's hearing
/// you" indicator that doesn't require looking at the menu bar.
struct HUDView: View {
    let state: DictationState

    var body: some View {
        HStack(spacing: 8) {
            icon
            Text(label)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(radius: 8, y: 2)
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .idle:
            EmptyView()
        case .recording:
            Image(systemName: "waveform")
                .foregroundStyle(.red)
                .symbolEffect(.variableColor.iterative, options: .repeating)
        case .transcribing, .cleaningUp:
            ProgressView()
                .controlSize(.small)
        case .inserting:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
        }
    }

    private var label: String {
        switch state {
        case .idle: return ""
        case .recording: return "Listening…"
        case .transcribing: return "Transcribing…"
        case .cleaningUp: return "Cleaning up…"
        case .inserting: return "Done"
        case .error(let message): return message
        }
    }
}

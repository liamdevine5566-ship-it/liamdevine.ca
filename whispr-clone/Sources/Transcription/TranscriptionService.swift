import Foundation

/// Abstracts "turn audio samples into text" so the recording pipeline
/// doesn't care whether that happens on-device or over the network. v1
/// only ships `WhisperKitTranscriptionService`, but this seam is what would
/// let a cloud fallback (e.g. OpenAI/Whisper API) be dropped in later
/// without touching `RecordingController`.
protocol TranscriptionService {
    /// `samples` are mono, 16kHz, Float32 — see `AudioRecorder`.
    func transcribe(samples: [Float]) async throws -> String
}

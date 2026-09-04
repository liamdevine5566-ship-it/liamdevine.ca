import Foundation
import WhisperKit

enum TranscriptionError: Error {
    case modelNotLoaded
    case emptyResult
}

/// On-device transcription via WhisperKit (github.com/argmaxinc/WhisperKit),
/// which runs Whisper through Core ML so it uses the Apple Silicon Neural
/// Engine — fast, free, works offline, and no audio ever leaves the Mac.
///
/// NOTE for whoever builds this in Xcode: WhisperKit's public API has moved
/// around across versions. This targets the shape as of late-2025 releases
/// (`WhisperKit(WhisperKitConfig)` + `transcribe(audioArray:)`). If Xcode's
/// autocomplete/compiler disagrees, check WhisperKit's README for the
/// current initializer and transcribe signature — the fix is local to this
/// file, `TranscriptionService` is the stable seam the rest of the app uses.
actor WhisperKitTranscriptionService: TranscriptionService {
    /// "openai_whisper-base.en" is small/fast and a reasonable default for
    /// a push-to-talk utterance (a few seconds of audio at a time). Swap
    /// for "openai_whisper-small.en" or larger if accuracy matters more
    /// than the first-run download size / per-utterance latency.
    private let modelName: String
    private var pipe: WhisperKit?

    init(modelName: String = "openai_whisper-base.en") {
        self.modelName = modelName
    }

    /// Loads (and on first run, downloads) the Core ML model. Call this
    /// once at app launch so the first push-to-talk isn't stalled on a
    /// multi-second model load.
    func preload() async throws {
        guard pipe == nil else { return }
        let config = WhisperKitConfig(model: modelName)
        pipe = try await WhisperKit(config)
    }

    func transcribe(samples: [Float]) async throws -> String {
        if pipe == nil {
            try await preload()
        }
        guard let pipe else { throw TranscriptionError.modelNotLoaded }

        let results = try await pipe.transcribe(audioArray: samples)
        let text = results.map(\.text).joined(separator: " ")

        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TranscriptionError.emptyResult
        }
        return text
    }
}

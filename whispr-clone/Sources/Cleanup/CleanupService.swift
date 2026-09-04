import Foundation

/// Turns a raw speech-to-text transcript into clean, insertable text:
/// spelling/grammar/punctuation fixed, filler words and stammers removed,
/// meaning and wording otherwise left alone.
protocol CleanupService {
    func cleanUp(transcript: String) async throws -> String
}

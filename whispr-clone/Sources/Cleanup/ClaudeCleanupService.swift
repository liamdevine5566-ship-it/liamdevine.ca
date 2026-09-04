import Foundation

enum CleanupError: Error {
    case missingAPIKey
    case badResponse(Int, String)
    case emptyResponse
}

/// Sends the raw transcript (text only — never audio) to the Claude API for
/// a cleanup pass. Uses the user's own API key, entered in Settings and
/// stored in Keychain.
final class ClaudeCleanupService: CleanupService {
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let apiVersion = "2023-06-01"

    /// Haiku: fast and cheap, which matters here since this call sits in
    /// the critical path between "finish talking" and "text appears."
    private let model: String
    private let session: URLSession

    init(model: String = "claude-haiku-4-5-20251001", session: URLSession = .shared) {
        self.model = model
        self.session = session
    }

    /// Tuned for a dyslexic user: fix *spelling* mistakes (typos, phonetic
    /// misspellings) without silently swapping in a different word than
    /// they said, fix grammar and punctuation, and strip disfluencies
    /// (um/uh/like-as-filler, stutters, false starts, repeated words). It
    /// must not summarize, rephrase for style, or add anything not in the
    /// original.
    private static let systemPrompt = """
    You clean up raw speech-to-text dictation transcripts before they're \
    inserted into whatever the user is typing into (an email, a doc, a \
    chat message, etc). The speaker is dyslexic, so getting spelling right \
    matters a lot to them.

    Rules:
    1. Fix spelling mistakes and misheard/mistranscribed words based on \
    context, without changing the speaker's actual word choices or meaning.
    2. Fix grammar and add correct punctuation and capitalization.
    3. Remove filler words and disfluencies: "um", "uh", "er", filler \
    "like"/"you know", false starts, and stuttered or repeated words \
    (e.g. "I I think" -> "I think").
    4. Do NOT summarize, rephrase for style, change the tone, add \
    information, or add any commentary, quotes, or preamble.
    5. If the transcript is already clean, return it unchanged.
    6. Reply with ONLY the cleaned text. No explanations, no quotation \
    marks around it, nothing else.
    """

    func cleanUp(transcript: String) async throws -> String {
        guard let apiKey = KeychainStore.loadAPIKey(), !apiKey.isEmpty else {
            throw CleanupError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = MessagesRequest(
            model: model,
            maxTokens: 1024,
            system: Self.systemPrompt,
            messages: [.init(role: "user", content: transcript)]
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw CleanupError.badResponse(status, bodyText)
        }

        let decoded = try JSONDecoder().decode(MessagesResponse.self, from: data)
        let text = decoded.content.map(\.text).joined()
        guard !text.isEmpty else { throw CleanupError.emptyResponse }
        return text
    }
}

// MARK: - Anthropic Messages API wire format (minimal subset used here)

private struct MessagesRequest: Encodable {
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [Message]

    struct Message: Encodable {
        let role: String
        let content: String
    }

    enum CodingKeys: String, CodingKey {
        case model, system, messages
        case maxTokens = "max_tokens"
    }
}

private struct MessagesResponse: Decodable {
    let content: [ContentBlock]

    struct ContentBlock: Decodable {
        let text: String
    }
}

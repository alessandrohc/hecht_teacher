import Foundation

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidResponse(String)
    case http(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing. Open Settings (⌘,) and paste your key."
        case .invalidResponse(let detail):
            return "Unexpected response from OpenAI: \(detail)"
        case .http(let code, let body):
            return "OpenAI returned HTTP \(code): \(body)"
        }
    }
}

final class OpenAIClient {
    static let shared = OpenAIClient()

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }

    private static let improveSystemPrompt = """
    You are an English coach helping a native Brazilian Portuguese speaker who is at an intermediate level and wants to sound more natural in English.

    The user will give you two things:
    - CONTEXT: the situation they are responding to (it may be in any language).
    - ATTEMPT: their attempt to reply in English.

    Reply using this exact structure in English:

    **Improved version:**
    A rewritten version of their reply in natural, native-sounding English appropriate to the context's register.

    **What I changed and why:**
    A short bulleted list (max 4 bullets) of the most important corrections or improvements. Mention grammar, word choice, register, idioms, or naturalness. Keep each bullet to one line.

    **Alternative phrasings:**
    1 or 2 other natural ways a native speaker might phrase the same idea, with a one-line note on when each fits.

    Rules:
    - Keep the whole answer under 220 words.
    - Never repeat the answer fully in Portuguese, but you may add short Portuguese glosses in parentheses after rare or tricky words.
    - If the attempt is already good, say so briefly and still offer one alternative.
    """

    private static let teachSystemPrompt = """
    You are an English coach for a native Brazilian Portuguese speaker (intermediate level). The user selected a piece of text inside another app and asked for help.

    Reply in this exact structure, using Markdown headings:

    **Tradução:** a natural Portuguese translation of the selected text.

    **Vocabulary:** up to 3 words or expressions the learner is unlikely to know, each followed by a short Portuguese gloss. Skip this section if everything is basic.

    **Better in English:** if the text is awkward, unidiomatic or could sound more natural, give one improved version with a one-line note. Skip this section if the text is already idiomatic.

    Rules:
    - The selected text may be in English or Portuguese. If it is in Portuguese, swap the sections: give an idiomatic English translation under "Translation:" and useful English vocabulary under "Vocabulary:".
    - Keep the whole reply under 140 words.
    - Be direct, no greetings, no closing remarks.
    """

    func improveAnswer(context: String, attempt: String) async throws -> String {
        let userMessage = """
        CONTEXT:
        \(context.isEmpty ? "(no context provided)" : context)

        ATTEMPT:
        \(attempt)
        """
        return try await chat(system: Self.improveSystemPrompt, user: userMessage, temperature: 0.4)
    }

    func teachSelectedText(_ text: String) async throws -> String {
        return try await chat(system: Self.teachSystemPrompt, user: text, temperature: 0.3)
    }

    private func chat(system: String, user: String, temperature: Double) async throws -> String {
        guard let apiKey = Settings.apiKey, !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        let body: [String: Any] = [
            "model": Settings.model,
            "temperature": temperature,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse("No HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "<no body>"
            throw OpenAIError.http(http.statusCode, bodyText)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let firstMessage = choices.first?["message"] as? [String: Any],
            let content = firstMessage["content"] as? String
        else {
            let bodyText = String(data: data, encoding: .utf8) ?? "<no body>"
            throw OpenAIError.invalidResponse(bodyText)
        }
        return content
    }
}

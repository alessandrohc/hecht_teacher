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

    func improveAnswer(context: String, attempt: String) async throws -> String {
        let userMessage = """
        CONTEXT:
        \(context.isEmpty ? "(no context provided)" : context)

        ATTEMPT:
        \(attempt)
        """
        return try await chat(system: Settings.improvePrompt, user: userMessage, temperature: Settings.improveTemperature)
    }

    func teachSelectedText(_ text: String) async throws -> String {
        return try await chat(system: Settings.teachPrompt, user: text, temperature: Settings.teachTemperature)
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

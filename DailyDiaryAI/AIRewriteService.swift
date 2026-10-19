import Foundation

struct AIRewriteService {
    private let apiKey = "YOUR_API_KEY"
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!

    func rewrite(_ entry: String) async throws -> String {
        let prompt = "Rewrite the diary entry with better language use while preserving meaning and tone:\n\n\(entry)"

        let body: [String: Any] = [
            "model": "gpt-4.1-mini",
            "input": prompt
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(ResponsePayload.self, from: data)
        return decoded.outputText ?? "No rewrite returned."
    }
}

private struct ResponsePayload: Decodable {
    let output: [OutputItem]?

    var outputText: String? {
        output?
            .flatMap { $0.content ?? [] }
            .compactMap { $0.text }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct OutputItem: Decodable {
    let content: [ContentItem]?
}

private struct ContentItem: Decodable {
    let text: String?
}

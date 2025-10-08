import Foundation

protocol APIService {
    func sendMessages(_ messages: [Message], systemPrompt: String, model: String, apiKey: String) async throws -> String
}

enum APIError: Error {
    case invalidResponse(String)
}


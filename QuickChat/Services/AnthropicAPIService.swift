import Foundation

class AnthropicAPIService: APIService {
    func sendMessages(_ messages: [Message], systemPrompt: String, model: String, apiKey: String) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let apiMessages = messages.map { ["role": $0.role, "content": $0.content] }
        var body: [String: Any] = ["model": model, "max_tokens": 4096, "messages": apiMessages]
        
        if !systemPrompt.isEmpty {
            body["system"] = systemPrompt
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let content = json?["content"] as? [[String: Any]],
           let firstContent = content.first,
           let text = firstContent["text"] as? String {
            return text
        }
        
        throw APIError.invalidResponse("Invalid Anthropic response")
    }
}


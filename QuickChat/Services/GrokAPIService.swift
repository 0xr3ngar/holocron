import Foundation

class GrokAPIService: APIService {
    func sendMessages(_ messages: [Message], systemPrompt: String, model: String, apiKey: String) async throws -> String {
        let url = URL(string: "https://api.x.ai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 3600
        
        var apiMessages = messages.map { ["role": $0.role, "content": $0.content] }
        
        if !systemPrompt.isEmpty {
            apiMessages.insert(["role": "system", "content": systemPrompt], at: 0)
        }
        
        let body: [String: Any] = ["messages": apiMessages, "model": model]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let choices = json?["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw APIError.invalidResponse("Invalid Grok response")
    }
}


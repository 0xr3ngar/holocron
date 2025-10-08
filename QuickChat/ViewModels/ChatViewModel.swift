import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var apiKeys: [AIProvider: String] = [:]
    @Published var showingSettings = false
    @Published var showingModelPicker = false
    @Published var isTransitioning = false
    @Published var existingMessageIds: Set<UUID> = []
    @Published var selectedProvider: AIProvider = .gemini
    @Published var selectedModel: String = "gemini-2.5-flash"
    @Published var selectedConversationID: Conversation.ID?
    @Published var systemPrompt: String = ""
    
    private let geminiService = GeminiAPIService()
    private let grokService = GrokAPIService()
    private let anthropicService = AnthropicAPIService()
    private let openaiService = OpenAIAPIService()
    
    init() {
        loadAPIKeys()
        loadConversations()
        loadProviderSettings()
        loadSystemPrompt()
    }
    
    var sortedConversations: [Conversation] {
        conversations.sorted { $0.lastUpdated > $1.lastUpdated }
    }
    
    var currentAPIKey: String {
        apiKeys[selectedProvider] ?? ""
    }
    
    
    func loadAPIKeys() {
        for provider in AIProvider.allCases {
            if let key = UserDefaults.standard.string(forKey: "api_key_\(provider.rawValue)") {
                apiKeys[provider] = key
            }
        }
    }
    
    func saveAPIKeys() {
        for (provider, key) in apiKeys {
            UserDefaults.standard.set(key, forKey: "api_key_\(provider.rawValue)")
        }
    }
    
    func loadProviderSettings() {
        if let providerRaw = UserDefaults.standard.string(forKey: "selected_provider"),
           let provider = AIProvider(rawValue: providerRaw) {
            selectedProvider = provider
        }
        if let model = UserDefaults.standard.string(forKey: "selected_model") {
            selectedModel = model
        } else {
            selectedModel = selectedProvider.models.first ?? ""
        }
    }
    
    func saveProviderSettings() {
        UserDefaults.standard.set(selectedProvider.rawValue, forKey: "selected_provider")
        UserDefaults.standard.set(selectedModel, forKey: "selected_model")
    }
    
    func loadSystemPrompt() {
        systemPrompt = UserDefaults.standard.string(forKey: "system_prompt") ?? ""
    }
    
    func saveSystemPrompt() {
        UserDefaults.standard.set(systemPrompt, forKey: "system_prompt")
    }
    
    func loadConversations() {
        if let data = UserDefaults.standard.data(forKey: "conversations"),
           let decoded = try? JSONDecoder().decode([Conversation].self, from: data) {
            conversations = decoded
            selectedConversationID = conversations.sorted { $0.lastUpdated > $1.lastUpdated }.first?.id
        }
    }
    
    func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(encoded, forKey: "conversations")
        }
    }
    
    
    func selectNextConversation(isDownArrow: Bool) {
        let sorted = sortedConversations
        guard !sorted.isEmpty else { return }
        
        let currentIndex = sorted.firstIndex(where: { $0.id == selectedConversationID }) ?? (isDownArrow ? -1 : 0)
        var nextIndex = currentIndex + (isDownArrow ? 1 : -1)
        nextIndex = max(0, min(sorted.count - 1, nextIndex))
        
        if nextIndex < sorted.count {
            selectedConversationID = sorted[nextIndex].id
        }
    }
    
    func selectCurrentConversationByID() {
        if let conversation = sortedConversations.first(where: { $0.id == selectedConversationID }) {
            selectConversation(conversation)
        }
    }
    
    func selectConversation(_ conv: Conversation) {
        isTransitioning = true
        existingMessageIds = Set(conv.messages.map { $0.id })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.currentConversation = conv
            self.isTransitioning = false
        }
    }
    
    func deleteConversation(_ conv: Conversation) {
        conversations.removeAll { $0.id == conv.id }
        saveConversations()
        if currentConversation?.id == conv.id {
            currentConversation = nil
        }
        if selectedConversationID == conv.id {
            selectedConversationID = sortedConversations.first?.id
        }
    }
    
    func goBack() {
        isTransitioning = true
        existingMessageIds = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.currentConversation = nil
            self.isTransitioning = false
            self.selectedConversationID = self.sortedConversations.first?.id
        }
    }
    
    func startNewConversation(with prompt: String) {
        guard !currentAPIKey.isEmpty else {
            showingSettings = true
            return
        }
        
        isTransitioning = true
        let userMessage = Message(role: "user", content: prompt)
        let newConv = Conversation(title: String(prompt.prefix(60)), messages: [userMessage])
        
        existingMessageIds = [userMessage.id]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.currentConversation = newConv
            self.isTransitioning = false
            self.isLoading = true
        }
        
        Task {
            do {
                let response = try await callAI(messages: [userMessage])
                await MainActor.run {
                    let assistantMessage = Message(role: "assistant", content: response)
                    self.currentConversation?.messages.append(assistantMessage)
                    self.currentConversation?.lastUpdated = Date()
                    
                    if let conv = self.currentConversation {
                        self.conversations.append(conv)
                        self.saveConversations()
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = Message(role: "assistant", content: "Error: \(error.localizedDescription)")
                    self.currentConversation?.messages.append(errorMessage)
                    self.isLoading = false
                }
            }
        }
    }
    
    func continueConversation(with prompt: String) {
        guard var conv = currentConversation else { return }
        
        let userMessage = Message(role: "user", content: prompt)
        conv.messages.append(userMessage)
        conv.lastUpdated = Date()
        currentConversation = conv
        isLoading = true
        
        Task {
            do {
                let response = try await callAI(messages: conv.messages)
                await MainActor.run {
                    let assistantMessage = Message(role: "assistant", content: response)
                    self.currentConversation?.messages.append(assistantMessage)
                    self.currentConversation?.lastUpdated = Date()
                    
                    if let index = self.conversations.firstIndex(where: { $0.id == conv.id }) {
                        if let current = self.currentConversation {
                            self.conversations[index] = current
                        }
                    }
                    self.saveConversations()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = Message(role: "assistant", content: "Error: \(error.localizedDescription)")
                    self.currentConversation?.messages.append(errorMessage)
                    self.isLoading = false
                }
            }
        }
    }
    
    private func callAI(messages: [Message]) async throws -> String {
        let service: APIService
        
        switch selectedProvider {
        case .gemini:
            service = geminiService
        case .grok:
            service = grokService
        case .anthropic:
            service = anthropicService
        case .openai:
            service = openaiService
        }
        
        return try await service.sendMessages(
            messages,
            systemPrompt: systemPrompt,
            model: selectedModel,
            apiKey: currentAPIKey
        )
    }
}


import SwiftUI
import Carbon

// Custom window class to ensure it can receive keyboard input
class InputReadyWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var eventMonitor: Any?
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "AI Chat")
            button.action = #selector(statusItemClicked)
        }
        
        let window = InputReadyWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 550),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hasShadow = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentView = NSHostingView(rootView: ContentView(windowManager: WindowManager(window: window)))
        
        self.window = window
        registerGlobalHotkey()
    }
    
    @objc func statusItemClicked() {
        toggleWindow()
    }
    
    func registerGlobalHotkey() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if modifiers == [.option, .command] && event.keyCode == 49 {
                DispatchQueue.main.async {
                    self.toggleWindow()
                }
            }
        }
    }
    
    func toggleWindow() {
        guard let window = window else { return }
        
        if window.isVisible {
            window.orderOut(nil)
        } else {
            centerWindow()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func centerWindow() {
        guard let window = window, let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        let x = screenFrame.midX - windowFrame.width / 2
        let y = screenFrame.midY - windowFrame.height / 2 + 80
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

class WindowManager: ObservableObject {
    let window: NSWindow
    init(window: NSWindow) { self.window = window }
    func hide() { window.orderOut(nil) }
}

enum AIProvider: String, Codable, CaseIterable {
    case gemini = "Google Gemini"
    case grok = "Grok"
    case anthropic = "Anthropic"
    case openai = "OpenAI"
    
    var models: [String] {
        switch self {
        case .gemini:
            return ["gemini-2.5-pro", "gemini-2.5-flash"]
        case .grok:
            return ["grok-code-fast-1", "grok-4-fast-reasoning", "grok-4-fast-non-reasoning"]
        case .anthropic:
            return ["claude-sonnet-4-20250514", "claude-opus-4-20250514", "claude-3-5-sonnet-20241022"]
        case .openai:
            return ["gpt-5-2025-08-07", "gpt-5-mini-2025-08-07", "gpt-5-nano-2025-08-07"]
        }
    }
    
    var apiKeyPlaceholder: String {
        switch self {
        case .gemini: return "AIza..."
        case .grok: return "xai-..."
        case .anthropic: return "sk-ant-..."
        case .openai: return "sk-..."
        }
    }
    
    var icon: String {
        switch self {
        case .gemini: return "sparkle"
        case .grok: return "bolt.fill"
        case .anthropic: return "brain.head.profile"
        case .openai: return "cpu"
        }
    }
}

struct Message: Identifiable, Codable, Hashable {
    let id: UUID
    let role: String
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: String, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

struct Conversation: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var title: String
    var messages: [Message]
    var lastUpdated: Date
    
    init(id: UUID = UUID(), title: String, messages: [Message] = [], lastUpdated: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.lastUpdated = lastUpdated
    }
}

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
    
    func callAI(messages: [Message]) async throws -> String {
        switch selectedProvider {
        case .gemini:
            return try await callGeminiAPI(messages: messages)
        case .grok:
            return try await callGrokAPI(messages: messages)
        case .anthropic:
            return try await callAnthropicAPI(messages: messages)
        case .openai:
            return try await callOpenAIAPI(messages: messages)
        }
    }
    
    private func callGeminiAPI(messages: [Message]) async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(selectedModel):generateContent?key=\(currentAPIKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let contents = messages.map { message -> [String: Any] in
            return [
                "role": message.role == "user" ? "user" : "model",
                "parts": [["text": message.content]]
            ]
        }
        
        var body: [String: Any] = ["contents": contents]
        
        if !systemPrompt.isEmpty {
            body["systemInstruction"] = [
                "parts": [["text": systemPrompt]]
            ]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let candidates = json?["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            return text
        }
        
        throw NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Gemini response"])
    }
    
    private func callGrokAPI(messages: [Message]) async throws -> String {
        let url = URL(string: "https://api.x.ai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(currentAPIKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 3600
        
        var apiMessages = messages.map { ["role": $0.role, "content": $0.content] }
        
        if !systemPrompt.isEmpty {
            apiMessages.insert(["role": "system", "content": systemPrompt], at: 0)
        }
        
        let body: [String: Any] = ["messages": apiMessages, "model": selectedModel]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let choices = json?["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Grok response"])
    }
    
    private func callAnthropicAPI(messages: [Message]) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(currentAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let apiMessages = messages.map { ["role": $0.role, "content": $0.content] }
        var body: [String: Any] = ["model": selectedModel, "max_tokens": 4096, "messages": apiMessages]
        
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
        
        throw NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Anthropic response"])
    }
    
    private func callOpenAIAPI(messages: [Message]) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(currentAPIKey)", forHTTPHeaderField: "Authorization")
        
        var apiMessages = messages.map { ["role": $0.role, "content": $0.content] }
        
        if !systemPrompt.isEmpty {
            apiMessages.insert(["role": "system", "content": systemPrompt], at: 0)
        }
        
        let body: [String: Any] = ["model": selectedModel, "messages": apiMessages]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let choices = json?["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid OpenAI response"])
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
}

let burgundyColor = Color(red: 173/255, green: 77/255, blue: 106/255)

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @ObservedObject var windowManager: WindowManager
    @FocusState private var isInputFocused: Bool
    @Namespace private var animation
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: NSColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 0.95)))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: 20)
            
            if viewModel.currentConversation == nil {
                LauncherView(
                    viewModel: viewModel,
                    windowManager: windowManager,
                    isInputFocused: $isInputFocused,
                    namespace: animation
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 1.05).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
                .zIndex(0)
            } else {
                ChatView(
                    viewModel: viewModel,
                    windowManager: windowManager,
                    isInputFocused: $isInputFocused,
                    namespace: animation
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 1.05).combined(with: .opacity)
                ))
                .zIndex(1)
            }
        }
        .frame(width: 680, height: 550)
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingModelPicker) {
            ModelPickerView(viewModel: viewModel)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
        .onKeyPress(.escape) {
            windowManager.hide()
            return .handled
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.9, blendDuration: 0), value: viewModel.currentConversation?.id)
    }
}

struct ModelPickerView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: NSColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 0.98)))
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "cpu.fill")
                        .font(.title3)
                        .foregroundColor(burgundyColor)
                    
                    Text("Select Model")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(20)
                .padding(.bottom, 4)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -10)
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(AIProvider.allCases, id: \.self) { provider in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Image(systemName: provider.icon)
                                        .font(.caption)
                                        .foregroundColor(burgundyColor.opacity(0.7))
                                    
                                    Text(provider.rawValue)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white.opacity(0.6))
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                }
                                .padding(.horizontal, 12)
                                .padding(.top, provider == AIProvider.allCases.first ? 0 : 8)
                                
                                ForEach(provider.models, id: \.self) { model in
                                    ModelRow(
                                        model: model,
                                        provider: provider,
                                        isSelected: viewModel.selectedProvider == provider && viewModel.selectedModel == model,
                                        hasAPIKey: viewModel.apiKeys[provider] != nil && !viewModel.apiKeys[provider]!.isEmpty
                                    ) {
                                        viewModel.selectedProvider = provider
                                        viewModel.selectedModel = model
                                        viewModel.saveProviderSettings()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                            dismiss()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
            }
        }
        .frame(width: 480, height: 540)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
        }
    }
}

struct ModelRow: View {
    let model: String
    let provider: AIProvider
    let isSelected: Bool
    let hasAPIKey: Bool
    let onSelect: () -> Void
    @State private var isHovering = false
    
    var modelDisplayName: String {
        model.replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
    
    var body: some View {
        Button(action: {
            if hasAPIKey {
                onSelect()
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? burgundyColor : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 18, height: 18)
                    
                    if isSelected {
                        Circle()
                            .fill(burgundyColor)
                            .frame(width: 10, height: 10)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(modelDisplayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(model)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
                
                if !hasAPIKey {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text("No API Key")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.orange.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? burgundyColor.opacity(0.15) : (isHovering && hasAPIKey ? Color.white.opacity(0.05) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? burgundyColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!hasAPIKey)
        .opacity(hasAPIKey ? 1 : 0.5)
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                isHovering = hovering
            }
        }
    }
}


struct LauncherView: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var windowManager: WindowManager
    @FocusState.Binding var isInputFocused: Bool
    var namespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(burgundyColor)
                        .matchedGeometryEffect(id: "icon", in: namespace)
                    
                    TextField("Ask anything...", text: $viewModel.inputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white)
                        .focused($isInputFocused)
                        .disabled(viewModel.isTransitioning)
                        .matchedGeometryEffect(id: "textfield", in: namespace)
                        .onSubmit {
                            if !viewModel.inputText.isEmpty && !viewModel.isTransitioning {
                                let query = viewModel.inputText
                                viewModel.inputText = ""
                                viewModel.startNewConversation(with: query)
                            }
                        }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: { viewModel.showingModelPicker.toggle() }) {
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.selectedProvider.icon)
                                    .font(.system(size: 11))
                                Text(viewModel.selectedModel.components(separatedBy: "-").last ?? "")
                                    .font(.system(size: 11, weight: .medium))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .semibold))
                            }
                            .foregroundColor(burgundyColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(burgundyColor.opacity(0.15))
                            )
                        }
                        .buttonStyle(.plain)
                        .matchedGeometryEffect(id: "modelpicker", in: namespace)
                        
                        Button(action: { viewModel.showingSettings.toggle() }) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                        .matchedGeometryEffect(id: "settings", in: namespace)
                        
                        Button(action: { windowManager.hide() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                        .matchedGeometryEffect(id: "close", in: namespace)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(nsColor: NSColor(white: 1, alpha: 0.02)))
            
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
            
            if viewModel.conversations.isEmpty {
                EmptyStateView()
            } else {
                ConversationListView(viewModel: viewModel)
            }
        }
        .onKeyPress(.upArrow) {
            if viewModel.inputText.isEmpty {
                viewModel.selectNextConversation(isDownArrow: false)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.downArrow) {
            if viewModel.inputText.isEmpty {
                viewModel.selectNextConversation(isDownArrow: true)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.return) {
            if viewModel.inputText.isEmpty && viewModel.selectedConversationID != nil {
                viewModel.selectCurrentConversationByID()
                return .handled
            }
            return .ignored
        }
    }
}

struct EmptyStateView: View {
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(burgundyColor.opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(burgundyColor)
            }
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
            
            VStack(spacing: 8) {
                Text("No Conversations")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Type a question above to start chatting with AI")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.05)) {
                appeared = true
            }
        }
    }
}

struct ConversationListView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var appeared = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(viewModel.sortedConversations) { conv in
                        ConversationRow(
                            conversation: conv,
                            isSelected: conv.id == viewModel.selectedConversationID,
                            onSelect: {
                                viewModel.selectedConversationID = conv.id
                                viewModel.selectConversation(conv)
                            },
                            onDelete: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    viewModel.deleteConversation(conv)
                                }
                            }
                        )
                        .id(conv.id)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(
                            .spring(response: 0.35, dampingFraction: 0.85)
                            .delay(Double(viewModel.sortedConversations.firstIndex(of: conv) ?? 0) * 0.02),
                            value: appeared
                        )
                    }
                }
                .padding(.vertical, 6)
            }
            .onChange(of: viewModel.selectedConversationID) { newID in
                if let newID = newID {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(newID, anchor: .center)
                    }
                }
            }
            .onAppear {
                appeared = true
                if viewModel.selectedConversationID == nil {
                    viewModel.selectedConversationID = viewModel.sortedConversations.first?.id
                }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    @State private var isHovering = false
    
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    private func formattedRelativeDate(from date: Date) -> String {
        return Self.relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(burgundyColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(burgundyColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(conversation.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 5) {
                    Text("\(conversation.messages.count) messages")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("•")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text(formattedRelativeDate(from: conversation.lastUpdated))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            Spacer()
            
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? burgundyColor.opacity(0.15) : (isHovering ? Color.white.opacity(0.04) : Color.clear))
        )
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                isHovering = hovering
            }
        }
    }
}

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var windowManager: WindowManager
    @FocusState.Binding var isInputFocused: Bool
    var namespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Button(action: {
                        viewModel.goBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(burgundyColor)
                        .matchedGeometryEffect(id: "icon", in: namespace)
                    
                    TextField("Ask follow-up...", text: $viewModel.inputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white)
                        .focused($isInputFocused)
                        .disabled(viewModel.isTransitioning)
                        .matchedGeometryEffect(id: "textfield", in: namespace)
                        .onSubmit {
                            if !viewModel.inputText.isEmpty {
                                let query = viewModel.inputText
                                viewModel.inputText = ""
                                viewModel.continueConversation(with: query)
                            }
                        }
                    
                    Spacer()
                    
                    Button(action: { viewModel.showingModelPicker.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.selectedProvider.icon)
                                .font(.system(size: 11))
                            Text(viewModel.selectedModel.components(separatedBy: "-").last ?? "")
                                .font(.system(size: 11, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(burgundyColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(burgundyColor.opacity(0.15))
                        )
                    }
                    .buttonStyle(.plain)
                    .matchedGeometryEffect(id: "modelpicker", in: namespace)
                    
                    Button(action: { viewModel.showingSettings.toggle() }) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .matchedGeometryEffect(id: "settings", in: namespace)
                    
                    Button(action: { windowManager.hide() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .matchedGeometryEffect(id: "close", in: namespace)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(nsColor: NSColor(white: 1, alpha: 0.02)))
            
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if let messages = viewModel.currentConversation?.messages {
                            ForEach(messages) { message in
                                QAMessageRow(message: message)
                                    .environmentObject(viewModel)
                                    .id(message.id)
                            }
                        }
                        
                        if viewModel.isLoading {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .progressViewStyle(CircularProgressViewStyle(tint: burgundyColor))
                                
                                Text("Thinking...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }
                    }
                    .padding(20)
                }
                .onChange(of: viewModel.currentConversation?.messages.count) { _ in
                    if let lastMessage = viewModel.currentConversation?.messages.last {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isInputFocused = true
            }
        }
        .onKeyPress(.escape) {
            if viewModel.inputText.isEmpty {
                viewModel.goBack()
                return .handled
            }
            return .ignored
        }
    }
}

struct QAMessageRow: View {
    let message: Message
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var displayedText = ""
    @State private var hasAnimated = false
    
    var shouldAnimate: Bool {
        !viewModel.existingMessageIds.contains(message.id)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if message.role == "user" {
                VStack(alignment: .leading, spacing: 8) {
                    Text(message.content)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .padding(16)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(displayedText)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
        }
        .onAppear {
            if message.role == "user" {
                displayedText = message.content
            } else if !hasAnimated {
                hasAnimated = true
                if shouldAnimate {
                    animateText()
                } else {
                    displayedText = message.content
                }
            }
        }
    }
    
    private func animateText() {
        let chunkSize = 5
        let words = message.content.split(separator: " ", omittingEmptySubsequences: false)
        
        let totalChunks = (words.count + chunkSize - 1) / chunkSize
        
        for chunkIndex in 0..<totalChunks {
            let delay = Double(chunkIndex) * 0.04
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let startIndex = chunkIndex * chunkSize
                let endIndex = min(startIndex + chunkSize, words.count)
                let chunk = words[startIndex..<endIndex].joined(separator: " ")
                
                if self.displayedText.isEmpty {
                    self.displayedText = chunk
                } else {
                    self.displayedText += " " + chunk
                }
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: NSColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 0.98)))
            
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "key.fill")
                        .font(.title3)
                        .foregroundColor(burgundyColor)
                    
                    Text("API Keys")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -10)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "text.bubble")
                                    .font(.subheadline)
                                    .foregroundColor(burgundyColor.opacity(0.8))
                                
                                Text("System Prompt")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            
                            TextEditor(text: $viewModel.systemPrompt)
                                .font(.system(.body, design: .monospaced))
                                .frame(height: 80)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle")
                                    .font(.caption2)
                                Text("Define how the AI should behave (optional)")
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        ForEach(AIProvider.allCases, id: \.self) { provider in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: provider.icon)
                                        .font(.subheadline)
                                        .foregroundColor(burgundyColor.opacity(0.8))
                                    
                                    Text(provider.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                
                                SecureField(provider.apiKeyPlaceholder, text: Binding(
                                    get: { viewModel.apiKeys[provider] ?? "" },
                                    set: { viewModel.apiKeys[provider] = $0 }
                                ))
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.body, design: .monospaced))
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "info.circle")
                                        .font(.caption2)
                                    Text(apiKeyHelpText(for: provider))
                                        .font(.caption)
                                }
                                .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .opacity(appeared ? 1 : 0)
                
                HStack {
                    Button("Cancel") {
                        viewModel.loadAPIKeys()
                        viewModel.loadSystemPrompt()
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Button("Save") {
                        viewModel.saveAPIKeys()
                        viewModel.saveSystemPrompt()
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(burgundyColor)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
            }
            .padding(24)
        }
        .frame(width: 500, height: 600)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
        }
    }
    
    private func apiKeyHelpText(for provider: AIProvider) -> String {
        switch provider {
        case .gemini:
            return "Get your API key from aistudio.google.com/apikey"
        case .grok:
            return "Get your API key from console.x.ai"
        case .anthropic:
            return "Get your API key from console.anthropic.com"
        case .openai:
            return "Get your API key from platform.openai.com"
        }
    }
}

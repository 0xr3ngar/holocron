import Foundation

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
    
    var apiKeyHelpText: String {
        switch self {
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


import SwiftUI

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
                        .foregroundColor(Theme.burgundyColor)
                    
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
                                    .foregroundColor(Theme.burgundyColor.opacity(0.8))
                                
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
                                        .foregroundColor(Theme.burgundyColor.opacity(0.8))
                                    
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
                                    Text(provider.apiKeyHelpText)
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
                    .tint(Theme.burgundyColor)
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
}


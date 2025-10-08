import SwiftUI

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
                        .foregroundColor(Theme.burgundyColor)
                    
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
                                        .foregroundColor(Theme.burgundyColor.opacity(0.7))
                                    
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


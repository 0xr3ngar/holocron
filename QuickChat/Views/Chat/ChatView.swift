import SwiftUI

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
                        .foregroundColor(Theme.burgundyColor)
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
                        .foregroundColor(Theme.burgundyColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Theme.burgundyColor.opacity(0.15))
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
                                MessageRow(message: message)
                                    .environmentObject(viewModel)
                                    .id(message.id)
                            }
                        }
                        
                        if viewModel.isLoading {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.burgundyColor))
                                
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


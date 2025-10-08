import SwiftUI

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
                        .foregroundColor(Theme.burgundyColor)
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


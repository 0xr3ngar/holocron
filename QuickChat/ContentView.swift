import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @ObservedObject var windowManager: WindowManager
    @FocusState private var isInputFocused: Bool
    @Namespace private var animation
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.backgroundColor)
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

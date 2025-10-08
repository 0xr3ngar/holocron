import SwiftUI

struct MessageRow: View {
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

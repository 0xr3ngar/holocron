import SwiftUI

struct EmptyStateView: View {
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Theme.burgundyColor.opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(Theme.burgundyColor)
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


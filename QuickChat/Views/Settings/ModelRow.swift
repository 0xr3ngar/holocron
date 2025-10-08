import SwiftUI

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
                        .strokeBorder(isSelected ? Theme.burgundyColor : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 18, height: 18)
                    
                    if isSelected {
                        Circle()
                            .fill(Theme.burgundyColor)
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
                    .fill(isSelected ? Theme.burgundyColor.opacity(0.15) : (isHovering && hasAPIKey ? Color.white.opacity(0.05) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Theme.burgundyColor.opacity(0.3) : Color.clear, lineWidth: 1)
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


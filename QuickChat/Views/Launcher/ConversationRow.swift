import SwiftUI

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
                    .fill(Theme.burgundyColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.burgundyColor)
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
                .fill(isSelected ? Theme.burgundyColor.opacity(0.15) : (isHovering ? Color.white.opacity(0.04) : Color.clear))
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


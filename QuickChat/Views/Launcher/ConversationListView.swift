import SwiftUI

struct ConversationListView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var appeared = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(viewModel.sortedConversations) { conv in
                        ConversationRow(
                            conversation: conv,
                            isSelected: conv.id == viewModel.selectedConversationID,
                            onSelect: {
                                viewModel.selectedConversationID = conv.id
                                viewModel.selectConversation(conv)
                            },
                            onDelete: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    viewModel.deleteConversation(conv)
                                }
                            }
                        )
                        .id(conv.id)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(
                            .spring(response: 0.35, dampingFraction: 0.85)
                            .delay(Double(viewModel.sortedConversations.firstIndex(of: conv) ?? 0) * 0.02),
                            value: appeared
                        )
                    }
                }
                .padding(.vertical, 6)
            }
            .onChange(of: viewModel.selectedConversationID) { newID in
                if let newID = newID {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(newID, anchor: .center)
                    }
                }
            }
            .onAppear {
                appeared = true
                if viewModel.selectedConversationID == nil {
                    viewModel.selectedConversationID = viewModel.sortedConversations.first?.id
                }
            }
        }
    }
}


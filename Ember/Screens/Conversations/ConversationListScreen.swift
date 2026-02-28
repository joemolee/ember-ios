import SwiftUI

// MARK: - ConversationListScreen

/// Displays all conversations sorted by most recently updated, with swipe-to-delete,
/// a toolbar button to create new conversations, and an inviting empty state.
struct ConversationListScreen: View {

    // MARK: - Properties

    @Binding var conversations: [Conversation]
    let onSelect: (Conversation) -> Void
    let onNew: () -> Void
    let onDelete: (Conversation) -> Void

    // MARK: - State

    @State private var appearAnimated: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationListView
                }
            }
            .background(Color.ember.background)
            .navigationTitle("Ember")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.ember.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onNew()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.ember.primary)
                    }
                    .accessibilityLabel("New conversation")
                }
            }
        }
        .onAppear {
            withAnimation(.emberStandard) {
                appearAnimated = true
            }
        }
    }

    // MARK: - Conversation List

    private var conversationListView: some View {
        let sorted = conversations.sorted { $0.updatedAt > $1.updatedAt }
        let mostRecentID = sorted.first?.id

        return List {
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, conversation in
                ConversationRowView(
                    conversation: conversation,
                    isMostRecent: conversation.id == mostRecentID
                )
                .listRowBackground(Color.ember.background)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: EmberTheme.Spacing.xs,
                    leading: EmberTheme.Spacing.md,
                    bottom: EmberTheme.Spacing.xs,
                    trailing: EmberTheme.Spacing.md
                ))
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect(conversation)
                }
                .opacity(appearAnimated ? 1 : 0)
                .offset(y: appearAnimated ? 0 : 12)
                .animation(
                    EmberAnimations.staggeredSnappy(for: index),
                    value: appearAnimated
                )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let conversation = sorted[index]
                    onDelete(conversation)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: EmberTheme.Spacing.lg) {
            Spacer()

            // Ember icon
            Image(systemName: "flame.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.ember.primary, Color.ember.glow],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .emberGlow(color: Color.ember.primary, radius: 24)
                .scaleEffect(appearAnimated ? 1.0 : 0.8)
                .opacity(appearAnimated ? 1 : 0)
                .animation(.emberBouncy, value: appearAnimated)

            VStack(spacing: EmberTheme.Spacing.sm) {
                Text("Start a conversation")
                    .font(EmberTheme.Typography.headline)
                    .foregroundStyle(Color.ember.textPrimary)

                Text("Ask Ember anything to get started")
                    .font(EmberTheme.Typography.body)
                    .foregroundStyle(Color.ember.textSecondary)
            }
            .opacity(appearAnimated ? 1 : 0)
            .animation(.emberStandard.delay(0.1), value: appearAnimated)

            EmberButton("New Conversation", style: .primary) {
                onNew()
            }
            .frame(maxWidth: 260)
            .opacity(appearAnimated ? 1 : 0)
            .animation(.emberStandard.delay(0.2), value: appearAnimated)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(EmberTheme.Spacing.lg)
    }
}

// MARK: - Preview

#Preview("ConversationListScreen - With Conversations") {
    @Previewable @State var conversations: [Conversation] = [
        Conversation(
            title: "Swift Concurrency",
            messages: [
                Message(role: .user, content: "Explain async/await in Swift"),
                Message(role: .assistant, content: "Swift concurrency is built around three core concepts that make writing safe, efficient asynchronous code much easier than before.")
            ],
            updatedAt: Date()
        ),
        Conversation(
            title: "Recipe Ideas",
            messages: [
                Message(role: .user, content: "What can I make with chicken and rice?"),
                Message(role: .assistant, content: "Here are some great chicken and rice recipes you might enjoy for dinner tonight.")
            ],
            updatedAt: Date().addingTimeInterval(-3600)
        ),
        Conversation(
            title: "Travel Planning",
            messages: [
                Message(role: .user, content: "Best places to visit in Japan?"),
                Message(role: .assistant, content: "Japan offers an incredible variety of experiences. Here are my top recommendations for your trip.")
            ],
            updatedAt: Date().addingTimeInterval(-86400 * 3)
        ),
    ]

    ConversationListScreen(
        conversations: $conversations,
        onSelect: { _ in },
        onNew: { },
        onDelete: { _ in }
    )
}

#Preview("ConversationListScreen - Empty") {
    @Previewable @State var conversations: [Conversation] = []

    ConversationListScreen(
        conversations: $conversations,
        onSelect: { _ in },
        onNew: { },
        onDelete: { _ in }
    )
}

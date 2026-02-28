import SwiftUI

// MARK: - MessageListView

/// A scrollable list of chat messages with auto-scrolling and a typing indicator.
/// Uses ScrollView + LazyVStack for efficient rendering of large conversations.
struct MessageListView: View {

    let messages: [Message]
    let isStreaming: Bool

    // MARK: - Private

    /// Sentinel ID used as the scroll anchor at the bottom of the list.
    private let bottomAnchorID = "bottomAnchor"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: EmberTheme.Spacing.md) {
                    ForEach(messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                            .padding(.horizontal, EmberTheme.Spacing.md)
                    }

                    if isStreaming && (messages.last?.content.isEmpty ?? true) {
                        TypingIndicatorView(isVisible: true)
                            .padding(.horizontal, EmberTheme.Spacing.md)
                    }

                    // Invisible anchor for scrolling to the bottom
                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchorID)
                }
                .padding(.top, EmberTheme.Spacing.sm)
                .padding(.bottom, EmberTheme.Spacing.sm)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: messages.last?.content) { _, _ in
                scrollToBottom(proxy: proxy, animated: false)
            }
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
        }
    }

    // MARK: - Scroll Helpers

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(bottomAnchorID, anchor: .bottom)
        }
    }
}

// MARK: - Preview

#Preview("MessageListView") {
    let sampleMessages: [Message] = [
        Message(role: .user, content: "What is SwiftUI?"),
        Message(
            role: .assistant,
            content: """
            **SwiftUI** is Apple's declarative framework for building user interfaces across all Apple platforms.

            Key features:
            - Declarative syntax
            - Live previews
            - Automatic support for Dark Mode, accessibility, and localization

            It was introduced at WWDC 2019.
            """
        ),
        Message(role: .user, content: "How does state management work?"),
        Message(
            role: .assistant,
            content: "SwiftUI uses property wrappers like `@State`, `@Binding`, `@Observable`, and `@Environment` to manage state and drive UI updates automatically.",
            isStreaming: true
        ),
    ]

    MessageListView(messages: sampleMessages, isStreaming: true)
        .background(Color.ember.background)
}

import SwiftUI
import MarkdownUI

// MARK: - StreamingTextView

/// Displays text that is being streamed token-by-token using MarkdownUI,
/// with a blinking cursor indicator appended while streaming is active.
struct StreamingTextView: View {

    let text: String
    let isStreaming: Bool

    @State private var cursorOpacity: Double = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if text.isEmpty && isStreaming {
                // Show just the cursor when waiting for the first token
                blinkingCursor
                    .padding(.leading, EmberTheme.Spacing.xs)
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Markdown(text)
                        .markdownTextStyle {
                            FontFamily(.system(.rounded))
                            FontSize(16)
                            ForegroundColor(Color.ember.textPrimary)
                        }
                        .markdownBlockStyle(\.codeBlock) { configuration in
                            configuration.label
                                .padding(EmberTheme.Spacing.sm)
                                .background(Color.ember.surface)
                                .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.small, style: .continuous))
                        }

                    if isStreaming {
                        blinkingCursor
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: text)
    }

    // MARK: - Blinking Cursor

    private var blinkingCursor: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.ember.primary)
            .frame(width: 2.5, height: 18)
            .opacity(cursorOpacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                ) {
                    cursorOpacity = 0.15
                }
            }
    }
}

// MARK: - Preview

#Preview("StreamingTextView") {
    VStack(alignment: .leading, spacing: EmberTheme.Spacing.lg) {
        // Empty state (waiting for first token)
        StreamingTextView(text: "", isStreaming: true)

        Divider()

        // Partial text streaming
        StreamingTextView(
            text: "Swift's concurrency model uses **structured concurrency** to manage async tasks. This means",
            isStreaming: true
        )

        Divider()

        // Complete text (no cursor)
        StreamingTextView(
            text: "Here is a complete response with no streaming cursor.",
            isStreaming: false
        )
    }
    .padding(EmberTheme.Spacing.md)
    .background(Color.ember.background)
}

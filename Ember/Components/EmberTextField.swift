import SwiftUI

// MARK: - EmberTextField

/// A themed text field following the Ember design system.
/// Shows a surface background, rounded corners, placeholder in textSecondary color,
/// and a glowing primary-color border when focused.
struct EmberTextField: View {

    // MARK: - Properties

    @Binding var text: String
    let placeholder: String
    let trailingIcon: Image?

    // MARK: - Focus State

    @FocusState private var isFocused: Bool

    // MARK: - Init

    init(
        text: Binding<String>,
        placeholder: String = "Type something…",
        trailingIcon: Image? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.trailingIcon = trailingIcon
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: EmberTheme.Spacing.sm) {
            // Native TextField with custom placeholder rendering
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(EmberTheme.Typography.body)
                        .foregroundStyle(Color.ember.textSecondary)
                        .allowsHitTesting(false)
                }

                TextField("", text: $text)
                    .font(EmberTheme.Typography.body)
                    .foregroundStyle(Color.ember.textPrimary)
                    .tint(Color.ember.primary)
                    .focused($isFocused)
            }

            // Optional trailing icon
            if let icon = trailingIcon {
                icon
                    .font(EmberTheme.Typography.body)
                    .foregroundStyle(isFocused ? Color.ember.primary : Color.ember.textSecondary)
                    .animation(.emberSubtle, value: isFocused)
            }
        }
        .padding(.horizontal, EmberTheme.Spacing.md)
        .padding(.vertical, EmberTheme.Spacing.sm + 2) // 10pt vertical padding
        .background(Color.ember.surface)
        .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.medium, style: .continuous))
        .overlay(borderOverlay)
        .shadow(
            color: isFocused ? Color.ember.primary.opacity(0.15) : .clear,
            radius: isFocused ? 8 : 0,
            x: 0,
            y: 0
        )
        .animation(.emberSubtle, value: isFocused)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }

    // MARK: - Border Overlay

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: EmberTheme.Radii.medium, style: .continuous)
            .stroke(
                isFocused ? Color.ember.primary : Color.ember.textSecondary.opacity(0.3),
                lineWidth: isFocused ? 1.5 : 1
            )
            .animation(.emberSubtle, value: isFocused)
    }
}

// MARK: - Preview

#Preview("EmberTextField — States") {
    @Previewable @State var text1: String = ""
    @Previewable @State var text2: String = "Hello, Ember!"

    VStack(spacing: EmberTheme.Spacing.md) {
        EmberTextField(
            text: $text1,
            placeholder: "Ask Ember anything…",
            trailingIcon: Image(systemName: "magnifyingglass")
        )

        EmberTextField(
            text: $text2,
            placeholder: "Message",
            trailingIcon: Image(systemName: "mic.fill")
        )

        EmberTextField(
            text: $text1,
            placeholder: "No trailing icon"
        )
    }
    .padding(EmberTheme.Spacing.lg)
    .background(Color.ember.background)
}

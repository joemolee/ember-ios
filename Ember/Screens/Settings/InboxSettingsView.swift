import SwiftUI

// MARK: - InboxSettingsView

/// Settings section for the unified inbox: toggle, source selection,
/// urgency threshold, VIP list, and priority topics.
struct InboxSettingsView: View {

    // MARK: - Properties

    @Bindable var settings: UserSettings

    // MARK: - State

    @State private var newVIP: String = ""
    @State private var newTopic: String = ""

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            // Master toggle
            EmberCard {
                Toggle(isOn: $settings.inboxEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unified Inbox")
                            .font(EmberTheme.Typography.body)
                            .foregroundStyle(Color.ember.textPrimary)
                        Text("Aggregate messages from iMessage, Slack, and Teams with AI triage")
                            .font(EmberTheme.Typography.caption)
                            .foregroundStyle(Color.ember.textSecondary)
                    }
                }
                .tint(Color.ember.primary)
            }

            if settings.inboxEnabled {
                // Source selection
                sourcesCard

                // Urgency threshold
                thresholdCard

                // VIP list
                vipCard

                // Priority topics
                topicsCard
            }
        }
    }

    // MARK: - Sources

    private var sourcesCard: some View {
        EmberCard(header: "Message Sources") {
            VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
                ForEach(MessagePlatform.allCases) { platform in
                    Toggle(isOn: sourceBinding(for: platform)) {
                        HStack(spacing: EmberTheme.Spacing.sm) {
                            PlatformIcon(platform: platform, size: 24)
                            Text(platform.displayName)
                                .font(EmberTheme.Typography.body)
                                .foregroundStyle(Color.ember.textPrimary)
                        }
                    }
                    .tint(Color.ember.primary)
                }
            }
        }
    }

    private func sourceBinding(for platform: MessagePlatform) -> Binding<Bool> {
        Binding(
            get: { settings.inboxSources.contains(platform) },
            set: { enabled in
                if enabled {
                    settings.inboxSources.insert(platform)
                } else {
                    settings.inboxSources.remove(platform)
                }
            }
        )
    }

    // MARK: - Threshold

    private var thresholdCard: some View {
        EmberCard(header: "Minimum Urgency") {
            VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
                Text("Only show messages at or above this urgency level")
                    .font(EmberTheme.Typography.caption)
                    .foregroundStyle(Color.ember.textSecondary)

                Picker("Threshold", selection: $settings.inboxUrgencyThreshold) {
                    ForEach(UrgencyLevel.allCases, id: \.rawValue) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - VIP List

    private var vipCard: some View {
        EmberCard(header: "VIP Senders") {
            VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
                Text("Messages from VIPs are always treated as important or higher")
                    .font(EmberTheme.Typography.caption)
                    .foregroundStyle(Color.ember.textSecondary)

                ForEach(settings.inboxVIPs, id: \.self) { vip in
                    HStack {
                        Text(vip)
                            .font(EmberTheme.Typography.body)
                            .foregroundStyle(Color.ember.textPrimary)
                        Spacer()
                        Button {
                            settings.inboxVIPs.removeAll { $0 == vip }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.ember.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: EmberTheme.Spacing.sm) {
                    EmberTextField(text: $newVIP, placeholder: "Name or identifier")
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit { addVIP() }

                    Button("Add") { addVIP() }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.ember.primary)
                        .disabled(newVIP.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addVIP() {
        let trimmed = newVIP.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !settings.inboxVIPs.contains(trimmed) else { return }
        settings.inboxVIPs.append(trimmed)
        newVIP = ""
    }

    // MARK: - Topics

    private var topicsCard: some View {
        EmberCard(header: "Priority Topics") {
            VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
                Text("Messages mentioning these topics get a triage boost")
                    .font(EmberTheme.Typography.caption)
                    .foregroundStyle(Color.ember.textSecondary)

                FlowLayout(spacing: EmberTheme.Spacing.xs) {
                    ForEach(settings.inboxPriorityTopics, id: \.self) { topic in
                        topicChip(topic)
                    }
                }

                HStack(spacing: EmberTheme.Spacing.sm) {
                    EmberTextField(text: $newTopic, placeholder: "e.g. budget, deployment")
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .onSubmit { addTopic() }

                    Button("Add") { addTopic() }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.ember.primary)
                        .disabled(newTopic.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func topicChip(_ topic: String) -> some View {
        HStack(spacing: 4) {
            Text(topic)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.ember.textPrimary)

            Button {
                settings.inboxPriorityTopics.removeAll { $0 == topic }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.ember.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.ember.surface)
        .clipShape(Capsule())
    }

    private func addTopic() {
        let trimmed = newTopic.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty, !settings.inboxPriorityTopics.contains(trimmed) else { return }
        settings.inboxPriorityTopics.append(trimmed)
        newTopic = ""
    }
}

// MARK: - FlowLayout

/// Simple flow layout for wrapping topic chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, offset) in result.offsets.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (offsets: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            offsets.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (offsets, CGSize(width: maxX, height: currentY + lineHeight))
    }
}

// MARK: - Preview

#Preview("InboxSettingsView") {
    let settings = UserSettings()
    settings.selectedProvider = .openClaw
    settings.inboxEnabled = true
    settings.inboxVIPs = ["Lindsay", "Daniel"]
    settings.inboxPriorityTopics = ["budget", "deployment", "security"]

    return ScrollView {
        InboxSettingsView(settings: settings)
            .padding(EmberTheme.Spacing.md)
    }
    .background(Color.ember.background)
    .preferredColorScheme(.dark)
}

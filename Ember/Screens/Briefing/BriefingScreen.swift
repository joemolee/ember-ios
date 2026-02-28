import SwiftUI
import MarkdownUI

// MARK: - BriefingScreen

/// Displays the latest morning briefing with summary, action items, and past briefings.
struct BriefingScreen: View {

    // MARK: - Properties

    let appState: AppState

    @State private var selectedBriefing: Briefing?

    // MARK: - Computed

    private var displayBriefing: Briefing? {
        selectedBriefing ?? appState.latestBriefing
    }

    private var pastBriefings: [Briefing] {
        guard appState.briefings.count > 1 else { return [] }
        return Array(appState.briefings.dropFirst())
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: EmberTheme.Spacing.lg) {
                if let briefing = displayBriefing {
                    headerCard(briefing)
                    summarySection(briefing)

                    if !briefing.actionItems.isEmpty {
                        actionItemsSection(briefing)
                    }

                    if !pastBriefings.isEmpty {
                        pastBriefingsSection
                    }
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, EmberTheme.Spacing.md)
            .padding(.vertical, EmberTheme.Spacing.lg)
        }
        .background(Color.ember.background)
        .scrollContentBackground(.hidden)
        .navigationTitle("Briefing")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.ember.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Header Card

    private func headerCard(_ briefing: Briefing) -> some View {
        EmberCard {
            VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.ember.primary, Color.ember.glow],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(briefing.title)
                            .font(EmberTheme.Typography.headline)
                            .foregroundStyle(Color.ember.textPrimary)

                        Text(briefing.date, style: .date)
                            .font(EmberTheme.Typography.caption)
                            .foregroundStyle(Color.ember.textSecondary)
                    }

                    Spacer()
                }

                Divider()
                    .background(Color.ember.textSecondary.opacity(0.2))

                HStack(spacing: EmberTheme.Spacing.lg) {
                    statItem(value: "\(briefing.messageCount)", label: "Messages")
                    statItem(value: "\(briefing.urgentCount)", label: "Urgent")
                    statItem(value: "\(briefing.actionItems.count)", label: "Actions")
                }
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ember.primary)

            Text(label)
                .font(EmberTheme.Typography.caption)
                .foregroundStyle(Color.ember.textSecondary)
        }
    }

    // MARK: - Summary Section

    private func summarySection(_ briefing: Briefing) -> some View {
        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            sectionHeader("Summary")

            EmberCard {
                Markdown(briefing.summary)
                    .markdownTextStyle {
                        ForegroundColor(Color.ember.textPrimary)
                    }
            }
        }
    }

    // MARK: - Action Items

    private func actionItemsSection(_ briefing: Briefing) -> some View {
        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            sectionHeader("Action Items")

            EmberCard {
                VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
                    ForEach(Array(briefing.actionItems.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: EmberTheme.Spacing.sm) {
                            Image(systemName: "circle")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.ember.primary)
                                .padding(.top, 2)

                            Text(item)
                                .font(EmberTheme.Typography.body)
                                .foregroundStyle(Color.ember.textPrimary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Past Briefings

    private var pastBriefingsSection: some View {
        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            sectionHeader("Past Briefings")

            LazyVStack(spacing: EmberTheme.Spacing.sm) {
                ForEach(pastBriefings) { briefing in
                    Button {
                        selectedBriefing = briefing
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(briefing.title)
                                    .font(EmberTheme.Typography.body)
                                    .foregroundStyle(Color.ember.textPrimary)

                                Text(briefing.date, style: .date)
                                    .font(EmberTheme.Typography.caption)
                                    .foregroundStyle(Color.ember.textSecondary)
                            }

                            Spacer()

                            Text("\(briefing.messageCount) msgs")
                                .font(EmberTheme.Typography.caption)
                                .foregroundStyle(Color.ember.textSecondary)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.ember.textSecondary)
                        }
                        .padding(EmberTheme.Spacing.sm)
                        .background(Color.ember.surface)
                        .clipShape(RoundedRectangle(cornerRadius: EmberTheme.CornerRadius.medium))
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: EmberTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.ember.textSecondary.opacity(0.5))

            VStack(spacing: EmberTheme.Spacing.sm) {
                Text("No Briefings Yet")
                    .font(EmberTheme.Typography.headline)
                    .foregroundStyle(Color.ember.textPrimary)

                Text("Enable morning briefings in Settings to receive a daily summary of your messages and action items.")
                    .font(EmberTheme.Typography.body)
                    .foregroundStyle(Color.ember.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, EmberTheme.Spacing.xl)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.ember.textSecondary)
            .padding(.leading, EmberTheme.Spacing.xs)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BriefingScreen(appState: AppState())
    }
    .preferredColorScheme(.dark)
}

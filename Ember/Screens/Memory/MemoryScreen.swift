import SwiftUI

// MARK: - MemoryScreen

/// Searchable list of AI memories grouped by category, with swipe-to-delete.
struct MemoryScreen: View {

    // MARK: - Properties

    let appState: AppState

    @State private var viewModel: MemoryViewModel

    // MARK: - Init

    init(appState: AppState) {
        self.appState = appState
        self._viewModel = State(initialValue: MemoryViewModel(appState: appState))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: EmberTheme.Spacing.md) {
                if viewModel.isEmpty {
                    emptyState
                } else {
                    searchBar
                    categoryFilter
                    memoryList
                }
            }
            .padding(.horizontal, EmberTheme.Spacing.md)
            .padding(.vertical, EmberTheme.Spacing.lg)
        }
        .background(Color.ember.background)
        .scrollContentBackground(.hidden)
        .navigationTitle("Memories")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.ember.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: EmberTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.ember.textSecondary)

            TextField("Search memories...", text: $viewModel.searchText)
                .font(EmberTheme.Typography.body)
                .foregroundStyle(Color.ember.textPrimary)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.ember.textSecondary)
                }
            }
        }
        .padding(EmberTheme.Spacing.sm)
        .background(Color.ember.surface)
        .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.medium))
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: EmberTheme.Spacing.sm) {
                filterChip(label: "All", isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }

                ForEach(MemoryCategory.allCases) { category in
                    filterChip(
                        label: category.displayName,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectedCategory = category
                    }
                }
            }
        }
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .padding(.horizontal, EmberTheme.Spacing.sm)
                .padding(.vertical, EmberTheme.Spacing.xs)
                .background(isSelected ? Color.ember.primary : Color.ember.surface)
                .foregroundStyle(isSelected ? .white : Color.ember.textSecondary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Memory List

    private var memoryList: some View {
        LazyVStack(spacing: EmberTheme.Spacing.sm) {
            ForEach(viewModel.groupedMemories, id: \.category) { group in
                Section {
                    ForEach(group.memories) { memory in
                        MemoryCard(memory: memory)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteMemory(memory)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    HStack {
                        Image(systemName: group.category.iconName)
                            .font(.system(size: 12, weight: .semibold))
                        Text(group.category.displayName.uppercased())
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color.ember.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, EmberTheme.Spacing.sm)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: EmberTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundStyle(Color.ember.textSecondary.opacity(0.5))

            VStack(spacing: EmberTheme.Spacing.sm) {
                Text("No Memories Yet")
                    .font(EmberTheme.Typography.headline)
                    .foregroundStyle(Color.ember.textPrimary)

                Text("As you chat with Ember, it will remember your preferences, facts, and corrections to provide better responses.")
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MemoryScreen(appState: AppState())
    }
    .preferredColorScheme(.dark)
}

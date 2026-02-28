import Foundation
import Observation

// MARK: - MemoryViewModel

/// View model for the memory screen. Provides search, category filtering,
/// and deletion via AppState.
@Observable
@MainActor
final class MemoryViewModel {

    // MARK: - Properties

    let appState: AppState

    var searchText: String = ""
    var selectedCategory: MemoryCategory?

    // MARK: - Computed

    var filteredMemories: [Memory] {
        var result = appState.memories

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { $0.content.lowercased().contains(query) }
        }

        return result.sorted { $0.updatedAt > $1.updatedAt }
    }

    var groupedMemories: [(category: MemoryCategory, memories: [Memory])] {
        let grouped = Dictionary(grouping: filteredMemories, by: \.category)
        return MemoryCategory.allCases.compactMap { category in
            guard let memories = grouped[category], !memories.isEmpty else { return nil }
            return (category: category, memories: memories)
        }
    }

    var isEmpty: Bool {
        appState.memories.isEmpty
    }

    // MARK: - Init

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Actions

    func deleteMemory(_ memory: Memory) {
        appState.requestMemoryDelete(id: memory.id)
    }

    func clearSearch() {
        searchText = ""
        selectedCategory = nil
    }
}

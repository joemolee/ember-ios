import Foundation

// MARK: - MemoryStore

/// Actor-based file cache for memories, stored as `memories.json` in Application Support.
/// Follows the same pattern as `InboxMessageStore`.
actor MemoryStore {

    // MARK: - Private

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var memoriesFileURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("Ember", isDirectory: true)
            .appendingPathComponent("memories.json")
    }

    // MARK: - Init

    init() {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    // MARK: - Public

    /// Loads all cached memories from disk. Returns an empty array on failure.
    func load() -> [Memory] {
        guard fileManager.fileExists(atPath: memoriesFileURL.path) else { return [] }

        do {
            let data = try Data(contentsOf: memoriesFileURL)
            return try decoder.decode([Memory].self, from: data)
        } catch {
            return []
        }
    }

    /// Saves the full set of memories to disk atomically.
    func save(_ memories: [Memory]) {
        do {
            let dir = memoriesFileURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: dir.path) {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            }

            let data = try encoder.encode(memories)
            try data.write(to: memoriesFileURL, options: [.atomic, .completeFileProtection])
        } catch {
            // Best-effort persistence; swallow errors.
        }
    }

    /// Deletes the cached memories file.
    func clear() {
        try? fileManager.removeItem(at: memoriesFileURL)
    }
}

import Foundation

// MARK: - BriefingStore

/// Actor-based file cache for briefings, stored as `briefings.json` in Application Support.
/// Retains the last 30 days of briefings.
actor BriefingStore {

    // MARK: - Private

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let retentionDays: Int = 30

    private var briefingsFileURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("Ember", isDirectory: true)
            .appendingPathComponent("briefings.json")
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

    /// Loads all cached briefings from disk. Returns an empty array on failure.
    func load() -> [Briefing] {
        guard fileManager.fileExists(atPath: briefingsFileURL.path) else { return [] }

        do {
            let data = try Data(contentsOf: briefingsFileURL)
            return try decoder.decode([Briefing].self, from: data)
        } catch {
            return []
        }
    }

    /// Saves the full set of briefings to disk atomically, pruning entries older than 30 days.
    func save(_ briefings: [Briefing]) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        let pruned = briefings.filter { $0.date > cutoff }

        do {
            let dir = briefingsFileURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: dir.path) {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            }

            let data = try encoder.encode(pruned)
            try data.write(to: briefingsFileURL, options: [.atomic, .completeFileProtection])
        } catch {
            // Best-effort persistence; swallow errors.
        }
    }

    /// Deletes the cached briefings file.
    func clear() {
        try? fileManager.removeItem(at: briefingsFileURL)
    }
}

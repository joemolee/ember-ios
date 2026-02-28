import Foundation

// MARK: - InboxMessageStore

/// File-based cache for inbox messages, stored as a single `inbox.json` in Application Support.
/// Thread-safe via actor isolation.
actor InboxMessageStore {

    // MARK: - Private

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var inboxFileURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("Ember", isDirectory: true)
            .appendingPathComponent("inbox.json")
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

    /// Loads all cached inbox messages from disk. Returns an empty array on failure.
    func load() -> [InboxMessage] {
        guard fileManager.fileExists(atPath: inboxFileURL.path) else { return [] }

        do {
            let data = try Data(contentsOf: inboxFileURL)
            return try decoder.decode([InboxMessage].self, from: data)
        } catch {
            return []
        }
    }

    /// Saves the full set of inbox messages to disk atomically.
    func save(_ messages: [InboxMessage]) {
        do {
            // Ensure the parent directory exists.
            let dir = inboxFileURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: dir.path) {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            }

            let data = try encoder.encode(messages)
            try data.write(to: inboxFileURL, options: [.atomic, .completeFileProtection])
        } catch {
            // Best-effort persistence; swallow errors.
        }
    }

    /// Deletes the cached inbox file.
    func clear() {
        try? fileManager.removeItem(at: inboxFileURL)
    }
}

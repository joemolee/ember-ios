import Foundation

enum PersistenceError: LocalizedError {
    case directoryCreationFailed(underlying: Error)
    case encodingFailed(underlying: Error)
    case decodingFailed(underlying: Error)
    case writeFailed(underlying: Error)
    case deleteFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let error):
            return "Failed to create storage directory: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .writeFailed(let error):
            return "Failed to write file: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete file: \(error.localizedDescription)"
        }
    }
}

final class PersistenceService: Sendable {

    static let shared = PersistenceService()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let settingsKey = "com.incendoai.ember.userSettings"

    private var conversationsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("Ember", isDirectory: true)
            .appendingPathComponent("conversations", isDirectory: true)
    }

    private init() {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    // MARK: - Directory Setup

    private func ensureConversationsDirectoryExists() throws {
        guard !fileManager.fileExists(atPath: conversationsDirectory.path) else { return }
        do {
            try fileManager.createDirectory(
                at: conversationsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            throw PersistenceError.directoryCreationFailed(underlying: error)
        }
    }

    // MARK: - Conversation Persistence

    func saveConversation(_ conversation: Conversation) throws {
        try ensureConversationsDirectoryExists()

        let fileURL = conversationsDirectory.appendingPathComponent("\(conversation.id.uuidString).json")

        let data: Data
        do {
            data = try encoder.encode(conversation)
        } catch {
            throw PersistenceError.encodingFailed(underlying: error)
        }

        do {
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            throw PersistenceError.writeFailed(underlying: error)
        }
    }

    func loadConversations() throws -> [Conversation] {
        try ensureConversationsDirectoryExists()

        let fileURLs: [URL]
        do {
            fileURLs = try fileManager.contentsOfDirectory(
                at: conversationsDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            return []
        }

        let jsonFiles = fileURLs.filter { $0.pathExtension == "json" }
        var conversations: [Conversation] = []

        for fileURL in jsonFiles {
            do {
                let data = try Data(contentsOf: fileURL)
                let conversation = try decoder.decode(Conversation.self, from: data)
                conversations.append(conversation)
            } catch {
                // Skip corrupt files rather than failing the entire load
                continue
            }
        }

        // Sort by most recently updated first
        conversations.sort { $0.updatedAt > $1.updatedAt }
        return conversations
    }

    func deleteConversation(id: UUID) throws {
        let fileURL = conversationsDirectory.appendingPathComponent("\(id.uuidString).json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw PersistenceError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Settings Persistence (UserDefaults)

    func saveSettings(_ settings: UserSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: settingsKey)
    }

    func loadSettings() -> UserSettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let settings = try? decoder.decode(UserSettings.self, from: data)
        else {
            return UserSettings()
        }
        return settings
    }
}

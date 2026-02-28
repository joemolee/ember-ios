import XCTest
@testable import Ember

final class MemoryTests: XCTestCase {

    // MARK: - Codable Round-Trip

    func testMemoryCodableRoundTrip() throws {
        let memory = Memory(
            id: "mem-001",
            category: .preference,
            content: "Prefers concise summaries",
            source: .conversation,
            createdAt: Date(timeIntervalSince1970: 1700000000),
            updatedAt: Date(timeIntervalSince1970: 1700000100)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(memory)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Memory.self, from: data)

        XCTAssertEqual(memory, decoded)
        XCTAssertEqual(decoded.id, "mem-001")
        XCTAssertEqual(decoded.category, .preference)
        XCTAssertEqual(decoded.content, "Prefers concise summaries")
        XCTAssertEqual(decoded.source, .conversation)
    }

    func testMemoryArrayCodableRoundTrip() throws {
        let memories = [
            Memory(id: "1", category: .preference, content: "A", source: .conversation),
            Memory(id: "2", category: .fact, content: "B", source: .manual),
            Memory(id: "3", category: .correction, content: "C", source: .inferred),
            Memory(id: "4", category: .context, content: "D", source: .conversation),
        ]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(memories)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([Memory].self, from: data)

        XCTAssertEqual(decoded.count, 4)
        XCTAssertEqual(decoded[0].category, .preference)
        XCTAssertEqual(decoded[1].category, .fact)
        XCTAssertEqual(decoded[2].category, .correction)
        XCTAssertEqual(decoded[3].category, .context)
    }

    // MARK: - Category Enum

    func testMemoryCategoryAllCases() {
        XCTAssertEqual(MemoryCategory.allCases.count, 4)
        XCTAssertTrue(MemoryCategory.allCases.contains(.preference))
        XCTAssertTrue(MemoryCategory.allCases.contains(.fact))
        XCTAssertTrue(MemoryCategory.allCases.contains(.correction))
        XCTAssertTrue(MemoryCategory.allCases.contains(.context))
    }

    func testMemoryCategoryDisplayNames() {
        XCTAssertEqual(MemoryCategory.preference.displayName, "Preference")
        XCTAssertEqual(MemoryCategory.fact.displayName, "Fact")
        XCTAssertEqual(MemoryCategory.correction.displayName, "Correction")
        XCTAssertEqual(MemoryCategory.context.displayName, "Context")
    }

    func testMemoryCategoryIcons() {
        XCTAssertEqual(MemoryCategory.preference.iconName, "heart.fill")
        XCTAssertEqual(MemoryCategory.fact.iconName, "brain.head.profile")
        XCTAssertEqual(MemoryCategory.correction.iconName, "arrow.triangle.2.circlepath")
        XCTAssertEqual(MemoryCategory.context.iconName, "info.circle.fill")
    }

    // MARK: - Source Enum

    func testMemorySourceCodable() throws {
        let sources: [MemorySource] = [.conversation, .manual, .inferred]
        let data = try JSONEncoder().encode(sources)
        let decoded = try JSONDecoder().decode([MemorySource].self, from: data)
        XCTAssertEqual(sources, decoded)
    }

    // MARK: - Equatable

    func testMemoryEquatable() {
        let date = Date()
        let a = Memory(id: "same", category: .fact, content: "X", source: .conversation, createdAt: date, updatedAt: date)
        let b = Memory(id: "same", category: .fact, content: "X", source: .conversation, createdAt: date, updatedAt: date)
        let c = Memory(id: "different", category: .fact, content: "X", source: .conversation, createdAt: date, updatedAt: date)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - Identifiable

    func testMemoryIdentifiable() {
        let memory = Memory(id: "test-id", category: .preference, content: "Test")
        XCTAssertEqual(memory.id, "test-id")
    }
}

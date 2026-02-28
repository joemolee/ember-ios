import XCTest
@testable import Ember

final class InboxMessageTests: XCTestCase {

    // MARK: - Codable Round-Trip

    func testInboxMessageCodableRoundTrip() throws {
        let message = InboxMessage(
            platform: .iMessage,
            senderName: "Lindsay",
            senderIdentifier: "+15551234567",
            content: "Review the budget deck",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            conversationContext: "Direct Message",
            triage: TriageResult(urgency: .urgent, reasoning: "From your manager"),
            originalMessageID: "imsg-001"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(message)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(InboxMessage.self, from: data)

        XCTAssertEqual(message, decoded)
    }

    func testTriageResultCodable() throws {
        let triage = TriageResult(urgency: .important, reasoning: "Deployment blocked")
        let data = try JSONEncoder().encode(triage)
        let decoded = try JSONDecoder().decode(TriageResult.self, from: data)
        XCTAssertEqual(triage, decoded)
    }

    func testMessagePlatformCodable() throws {
        for platform in MessagePlatform.allCases {
            let data = try JSONEncoder().encode(platform)
            let decoded = try JSONDecoder().decode(MessagePlatform.self, from: data)
            XCTAssertEqual(platform, decoded)
        }
    }

    func testUrgencyLevelCodable() throws {
        for level in UrgencyLevel.allCases {
            let data = try JSONEncoder().encode(level)
            let decoded = try JSONDecoder().decode(UrgencyLevel.self, from: data)
            XCTAssertEqual(level, decoded)
        }
    }

    // MARK: - Urgency Sorting

    func testUrgencyLevelComparable() {
        XCTAssertTrue(UrgencyLevel.urgent < .important)
        XCTAssertTrue(UrgencyLevel.important < .informational)
        XCTAssertTrue(UrgencyLevel.informational < .low)
        XCTAssertFalse(UrgencyLevel.low < .urgent)
    }

    func testSortingMessagesByUrgency() {
        let messages = [
            makeMessage(urgency: .low),
            makeMessage(urgency: .urgent),
            makeMessage(urgency: .informational),
            makeMessage(urgency: .important),
        ]

        let sorted = messages.sorted { $0.triage.urgency < $1.triage.urgency }

        XCTAssertEqual(sorted[0].triage.urgency, .urgent)
        XCTAssertEqual(sorted[1].triage.urgency, .important)
        XCTAssertEqual(sorted[2].triage.urgency, .informational)
        XCTAssertEqual(sorted[3].triage.urgency, .low)
    }

    // MARK: - Deduplication

    func testDeduplicationByOriginalMessageID() {
        let msg1 = makeMessage(originalID: "slack-001", content: "First version")
        let msg2 = makeMessage(originalID: "slack-001", content: "Updated version")
        let msg3 = makeMessage(originalID: "slack-002", content: "Different message")

        let all = [msg1, msg2, msg3]

        // Dedup by keeping the last occurrence of each originalMessageID.
        var seen = Set<String>()
        let deduped = all.reversed().filter { seen.insert($0.originalMessageID).inserted }.reversed()

        XCTAssertEqual(Array(deduped).count, 2)
        XCTAssertEqual(Array(deduped)[0].content, "Updated version")
        XCTAssertEqual(Array(deduped)[1].content, "Different message")
    }

    // MARK: - Preview Truncation

    func testPreviewShortContent() {
        let msg = makeMessage(content: "Short message")
        XCTAssertEqual(msg.preview, "Short message")
    }

    func testPreviewLongContent() {
        let longContent = String(repeating: "A", count: 200)
        let msg = makeMessage(content: longContent)
        XCTAssertTrue(msg.preview.hasSuffix("..."))
        XCTAssertEqual(msg.preview.count, 123) // 120 chars + "..."
    }

    // MARK: - Helpers

    private func makeMessage(
        urgency: UrgencyLevel = .informational,
        originalID: String = UUID().uuidString,
        content: String = "Test content"
    ) -> InboxMessage {
        InboxMessage(
            platform: .slack,
            senderName: "Test",
            senderIdentifier: "test@test.com",
            content: content,
            triage: TriageResult(urgency: urgency, reasoning: "Test"),
            originalMessageID: originalID
        )
    }
}

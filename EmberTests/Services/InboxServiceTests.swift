import XCTest
@testable import Ember

final class InboxServiceTests: XCTestCase {

    // MARK: - Protocol Parsing Tests

    /// Verifies that `inbox_messages` JSON payloads are correctly parsed into `InboxMessage` arrays.
    func testParseInboxMessagesPayload() throws {
        let json = """
        {
            "type": "inbox_messages",
            "messages": [
                {
                    "id": "11111111-1111-1111-1111-111111111111",
                    "platform": "iMessage",
                    "senderName": "Lindsay",
                    "senderIdentifier": "+15551234567",
                    "content": "Hey, review the budget deck",
                    "timestamp": "2024-11-14T12:00:00Z",
                    "conversationContext": "Direct Message",
                    "triage": { "urgency": "urgent", "reasoning": "From your manager" },
                    "isRead": false,
                    "originalMessageID": "imsg-001"
                }
            ]
        }
        """

        let data = Data(json.utf8)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["type"] as? String, "inbox_messages")

        let messagesData = try JSONSerialization.data(withJSONObject: parsed["messages"]!)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let messages = try decoder.decode([InboxMessage].self, from: messagesData)

        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].platform, .iMessage)
        XCTAssertEqual(messages[0].senderName, "Lindsay")
        XCTAssertEqual(messages[0].triage.urgency, .urgent)
        XCTAssertFalse(messages[0].isRead)
    }

    /// Verifies that `inbox_update` payloads parse into a single `InboxMessage`.
    func testParseInboxUpdatePayload() throws {
        let json = """
        {
            "type": "inbox_update",
            "message": {
                "id": "22222222-2222-2222-2222-222222222222",
                "platform": "slack",
                "senderName": "Daniel",
                "senderIdentifier": "U12345",
                "content": "Staging is blocked",
                "timestamp": "2024-11-14T12:30:00Z",
                "conversationContext": "#engineering",
                "triage": { "urgency": "important", "reasoning": "Deployment blocked" },
                "isRead": false,
                "originalMessageID": "slack-001"
            }
        }
        """

        let data = Data(json.utf8)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["type"] as? String, "inbox_update")

        let messageData = try JSONSerialization.data(withJSONObject: parsed["message"]!)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let message = try decoder.decode(InboxMessage.self, from: messageData)

        XCTAssertEqual(message.platform, .slack)
        XCTAssertEqual(message.triage.urgency, .important)
    }

    /// Verifies that `inbox_read_confirmed` payloads are correctly extracted.
    func testParseInboxReadConfirmedPayload() throws {
        let json = """
        {"type": "inbox_read_confirmed", "messageId": "imsg-001"}
        """

        let data = Data(json.utf8)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["type"] as? String, "inbox_read_confirmed")
        XCTAssertEqual(parsed["messageId"] as? String, "imsg-001")
    }

    /// Verifies client → gateway message format for `inbox_subscribe`.
    func testBuildSubscribePayload() throws {
        let payload: [String: Any] = ["type": "inbox_subscribe"]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: String]

        XCTAssertEqual(parsed["type"], "inbox_subscribe")
    }

    /// Verifies client → gateway message format for `inbox_refresh`.
    func testBuildRefreshPayload() throws {
        let payload: [String: Any] = ["type": "inbox_refresh"]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: String]

        XCTAssertEqual(parsed["type"], "inbox_refresh")
    }

    /// Verifies client → gateway message format for `inbox_read`.
    func testBuildMarkAsReadPayload() throws {
        let payload: [String: Any] = ["type": "inbox_read", "messageId": "slack-001"]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["type"] as? String, "inbox_read")
        XCTAssertEqual(parsed["messageId"] as? String, "slack-001")
    }

    /// Verifies client → gateway message format for `inbox_config`.
    func testBuildConfigPayload() throws {
        let vips = ["Lindsay", "Daniel"]
        let topics = ["budget", "deployment"]
        let payload: [String: Any] = ["type": "inbox_config", "vips": vips, "topics": topics]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["type"] as? String, "inbox_config")
        XCTAssertEqual(parsed["vips"] as? [String], vips)
        XCTAssertEqual(parsed["topics"] as? [String], topics)
    }

    // MARK: - Mock Service Tests

    func testMockServiceYieldsSampleMessages() async throws {
        let mock = MockInboxService()

        var receivedMessages: [InboxMessage] = []
        for try await event in mock.subscribe() {
            if case .messages(let messages) = event {
                receivedMessages = messages
            }
        }

        XCTAssertEqual(receivedMessages.count, 4)
        XCTAssertEqual(mock.subscribeCallCount, 1)
    }

    func testMockServiceTracksMarkAsRead() async throws {
        let mock = MockInboxService()
        try await mock.markAsRead(messageID: "imsg-001")
        try await mock.markAsRead(messageID: "slack-001")

        XCTAssertEqual(mock.markAsReadIDs, ["imsg-001", "slack-001"])
    }

    func testMockServiceTracksRefresh() async throws {
        let mock = MockInboxService()
        try await mock.requestRefresh()
        try await mock.requestRefresh()

        XCTAssertEqual(mock.refreshCallCount, 2)
    }

    func testMockServiceTracksConfig() async throws {
        let mock = MockInboxService()
        try await mock.sendConfig(vips: ["Lindsay"], topics: ["budget"])

        XCTAssertEqual(mock.sentVIPs, ["Lindsay"])
        XCTAssertEqual(mock.sentTopics, ["budget"])
    }
}

import XCTest
@testable import Ember

final class InboxServiceTests: XCTestCase {

    // MARK: - Inbox Protocol Parsing Tests

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

    // MARK: - Memory Protocol Parsing Tests

    /// Verifies that `memory_list` payloads parse into `[Memory]`.
    func testParseMemoryListPayload() throws {
        let json = """
        {
            "type": "memory_list",
            "memories": [
                {
                    "id": "mem-001",
                    "category": "preference",
                    "content": "Prefers bullet points",
                    "source": "conversation",
                    "createdAt": "2024-11-14T12:00:00Z",
                    "updatedAt": "2024-11-14T12:00:00Z"
                },
                {
                    "id": "mem-002",
                    "category": "fact",
                    "content": "Works at Incendo AI",
                    "source": "conversation",
                    "createdAt": "2024-11-14T12:00:00Z",
                    "updatedAt": "2024-11-14T12:00:00Z"
                }
            ]
        }
        """

        let data = Data(json.utf8)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["type"] as? String, "memory_list")

        let memoriesData = try JSONSerialization.data(withJSONObject: parsed["memories"]!)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let memories = try decoder.decode([Memory].self, from: memoriesData)

        XCTAssertEqual(memories.count, 2)
        XCTAssertEqual(memories[0].id, "mem-001")
        XCTAssertEqual(memories[0].category, .preference)
        XCTAssertEqual(memories[1].category, .fact)
    }

    /// Verifies that `memory_created` payloads parse into a single `Memory`.
    func testParseMemoryCreatedPayload() throws {
        let json = """
        {
            "type": "memory_created",
            "memory": {
                "id": "mem-003",
                "category": "correction",
                "content": "Name is Lindsay not Lindsey",
                "source": "conversation",
                "createdAt": "2024-11-14T13:00:00Z",
                "updatedAt": "2024-11-14T13:00:00Z"
            }
        }
        """

        let data = Data(json.utf8)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["type"] as? String, "memory_created")

        let memoryData = try JSONSerialization.data(withJSONObject: parsed["memory"]!)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let memory = try decoder.decode(Memory.self, from: memoryData)

        XCTAssertEqual(memory.id, "mem-003")
        XCTAssertEqual(memory.category, .correction)
    }

    /// Verifies that `memory_updated` payloads parse into a single `Memory`.
    func testParseMemoryUpdatedPayload() throws {
        let json = """
        {
            "type": "memory_updated",
            "memory": {
                "id": "mem-001",
                "category": "preference",
                "content": "Prefers detailed bullet points with examples",
                "source": "conversation",
                "createdAt": "2024-11-14T12:00:00Z",
                "updatedAt": "2024-11-14T14:00:00Z"
            }
        }
        """

        let data = Data(json.utf8)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["type"] as? String, "memory_updated")

        let memoryData = try JSONSerialization.data(withJSONObject: parsed["memory"]!)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let memory = try decoder.decode(Memory.self, from: memoryData)

        XCTAssertEqual(memory.id, "mem-001")
        XCTAssertEqual(memory.content, "Prefers detailed bullet points with examples")
    }

    /// Verifies that `memory_deleted` payloads extract the memoryId.
    func testParseMemoryDeletedPayload() throws {
        let json = """
        {"type": "memory_deleted", "memoryId": "mem-001"}
        """

        let data = Data(json.utf8)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["type"] as? String, "memory_deleted")
        XCTAssertEqual(parsed["memoryId"] as? String, "mem-001")
    }

    // MARK: - Briefing Protocol Parsing Tests

    /// Verifies that `briefing` payloads parse into a `Briefing`.
    func testParseBriefingPayload() throws {
        let json = """
        {
            "type": "briefing",
            "briefing": {
                "id": "brief-001",
                "title": "Your Morning Briefing",
                "summary": "You have 12 messages overnight.",
                "date": "2024-11-14T07:00:00Z",
                "actionItems": ["Review budget", "Reply to Lindsay"],
                "sourceMessages": ["imsg-001"],
                "messageCount": 12,
                "urgentCount": 3
            }
        }
        """

        let data = Data(json.utf8)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["type"] as? String, "briefing")

        let briefingData = try JSONSerialization.data(withJSONObject: parsed["briefing"]!)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let briefing = try decoder.decode(Briefing.self, from: briefingData)

        XCTAssertEqual(briefing.id, "brief-001")
        XCTAssertEqual(briefing.title, "Your Morning Briefing")
        XCTAssertEqual(briefing.actionItems.count, 2)
        XCTAssertEqual(briefing.messageCount, 12)
    }

    // MARK: - Push Protocol Parsing Tests

    /// Verifies that `device_token_confirmed` payloads are recognized.
    func testParseDeviceTokenConfirmedPayload() throws {
        let json = """
        {"type": "device_token_confirmed"}
        """

        let data = Data(json.utf8)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["type"] as? String, "device_token_confirmed")
    }

    // MARK: - New Client → Gateway Payload Tests

    /// Verifies client → gateway format for `device_token`.
    func testBuildDeviceTokenPayload() throws {
        let payload: [String: Any] = ["type": "device_token", "token": "abc123hex", "platform": "ios"]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["type"] as? String, "device_token")
        XCTAssertEqual(parsed["token"] as? String, "abc123hex")
        XCTAssertEqual(parsed["platform"] as? String, "ios")
    }

    /// Verifies client → gateway format for `memory_sync`.
    func testBuildMemorySyncPayload() throws {
        let payload: [String: Any] = ["type": "memory_sync"]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: String]

        XCTAssertEqual(parsed["type"], "memory_sync")
    }

    /// Verifies client → gateway format for `memory_delete`.
    func testBuildMemoryDeletePayload() throws {
        let payload: [String: Any] = ["type": "memory_delete", "memoryId": "mem-001"]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["type"] as? String, "memory_delete")
        XCTAssertEqual(parsed["memoryId"] as? String, "mem-001")
    }

    /// Verifies client → gateway format for `briefing_config`.
    func testBuildBriefingConfigPayload() throws {
        let payload: [String: Any] = [
            "type": "briefing_config",
            "enabled": true,
            "time": "07:00",
            "timezone": "America/New_York",
            "sources": ["iMessage", "slack", "teams"]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["type"] as? String, "briefing_config")
        XCTAssertEqual(parsed["enabled"] as? Bool, true)
        XCTAssertEqual(parsed["time"] as? String, "07:00")
        XCTAssertEqual(parsed["timezone"] as? String, "America/New_York")
        XCTAssertEqual(parsed["sources"] as? [String], ["iMessage", "slack", "teams"])
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

    func testMockServiceTracksDeviceToken() async throws {
        let mock = MockInboxService()
        try await mock.sendDeviceToken("abc123")

        XCTAssertEqual(mock.sentDeviceToken, "abc123")
    }

    func testMockServiceTracksMemorySync() async throws {
        let mock = MockInboxService()
        try await mock.requestMemorySync()

        XCTAssertEqual(mock.memorySyncCallCount, 1)
    }

    func testMockServiceTracksMemoryDelete() async throws {
        let mock = MockInboxService()
        try await mock.deleteMemory(id: "mem-001")
        try await mock.deleteMemory(id: "mem-002")

        XCTAssertEqual(mock.deletedMemoryIDs, ["mem-001", "mem-002"])
    }

    func testMockServiceTracksBriefingConfig() async throws {
        let mock = MockInboxService()
        try await mock.sendBriefingConfig(enabled: true, time: "08:00", timezone: "US/Pacific", sources: ["slack"])

        XCTAssertNotNil(mock.sentBriefingConfig)
        XCTAssertEqual(mock.sentBriefingConfig?.enabled, true)
        XCTAssertEqual(mock.sentBriefingConfig?.time, "08:00")
        XCTAssertEqual(mock.sentBriefingConfig?.timezone, "US/Pacific")
        XCTAssertEqual(mock.sentBriefingConfig?.sources, ["slack"])
    }
}

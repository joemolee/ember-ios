import Foundation
@testable import Ember

// MARK: - MockInboxService

/// A mock `InboxServiceProtocol` that yields a deterministic set of triaged messages.
/// Used in unit tests and SwiftUI previews.
final class MockInboxService: InboxServiceProtocol, @unchecked Sendable {

    // MARK: - Test Hooks

    var subscribeCallCount = 0
    var refreshCallCount = 0
    var markAsReadIDs: [String] = []
    var sentVIPs: [String] = []
    var sentTopics: [String] = []
    var unsubscribeCallCount = 0
    var sentDeviceToken: String?
    var memorySyncCallCount = 0
    var deletedMemoryIDs: [String] = []
    var sentBriefingConfig: (enabled: Bool, time: String, timezone: String, sources: [String])?

    /// Override to inject custom events into the stream.
    var eventsToEmit: [GatewayEvent] = [.messages(MockInboxService.sampleMessages)]

    // MARK: - InboxServiceProtocol

    func subscribe() -> AsyncThrowingStream<GatewayEvent, Error> {
        subscribeCallCount += 1
        let events = eventsToEmit
        return AsyncThrowingStream { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }
    }

    func requestRefresh() async throws {
        refreshCallCount += 1
    }

    func markAsRead(messageID: String) async throws {
        markAsReadIDs.append(messageID)
    }

    func sendConfig(vips: [String], topics: [String]) async throws {
        sentVIPs = vips
        sentTopics = topics
    }

    func sendDeviceToken(_ token: String) async throws {
        sentDeviceToken = token
    }

    func requestMemorySync() async throws {
        memorySyncCallCount += 1
    }

    func deleteMemory(id: String) async throws {
        deletedMemoryIDs.append(id)
    }

    func sendBriefingConfig(enabled: Bool, time: String, timezone: String, sources: [String]) async throws {
        sentBriefingConfig = (enabled: enabled, time: time, timezone: timezone, sources: sources)
    }

    func unsubscribe() {
        unsubscribeCallCount += 1
    }

    // MARK: - Sample Data

    static let sampleMessages: [InboxMessage] = [
        InboxMessage(
            platform: .iMessage,
            senderName: "Lindsay",
            senderIdentifier: "+15551234567",
            content: "Hey, can you review the Q3 budget deck before the 3pm meeting? Need your sign-off.",
            timestamp: Date().addingTimeInterval(-300),
            conversationContext: "Direct Message",
            triage: TriageResult(urgency: .urgent, reasoning: "From your manager, time-sensitive request before upcoming meeting"),
            originalMessageID: "imsg-001"
        ),
        InboxMessage(
            platform: .slack,
            senderName: "Daniel Henderson",
            senderIdentifier: "U12345",
            content: "The staging deploy is blocked on a failing integration test in the auth module. Can someone take a look?",
            timestamp: Date().addingTimeInterval(-900),
            conversationContext: "#engineering",
            triage: TriageResult(urgency: .important, reasoning: "Staging deployment blocked, relevant to your team"),
            originalMessageID: "slack-001"
        ),
        InboxMessage(
            platform: .teams,
            senderName: "Sarah Chen",
            senderIdentifier: "sarah@company.com",
            content: "Reminder: Product sync moved to Thursday this week due to the company all-hands on Wednesday.",
            timestamp: Date().addingTimeInterval(-1800),
            conversationContext: "Product Team Chat",
            triage: TriageResult(urgency: .informational, reasoning: "Schedule change notification, not time-critical"),
            originalMessageID: "teams-001"
        ),
        InboxMessage(
            platform: .slack,
            senderName: "Bot: GitHub",
            senderIdentifier: "B99999",
            content: "PR #847 merged: Update dependency versions for security patches",
            timestamp: Date().addingTimeInterval(-3600),
            conversationContext: "#ci-notifications",
            triage: TriageResult(urgency: .low, reasoning: "Automated notification, routine dependency update"),
            originalMessageID: "slack-002"
        ),
    ]

    static let sampleMemories: [Memory] = [
        Memory(
            id: "mem-001",
            category: .preference,
            content: "Prefers concise, bullet-point summaries over long paragraphs",
            source: .conversation
        ),
        Memory(
            id: "mem-002",
            category: .fact,
            content: "Works at Incendo AI as a product manager",
            source: .conversation
        ),
        Memory(
            id: "mem-003",
            category: .correction,
            content: "Name is spelled 'Lindsay' not 'Lindsey'",
            source: .conversation
        ),
    ]
}

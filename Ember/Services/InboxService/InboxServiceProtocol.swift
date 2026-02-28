import Foundation

// MARK: - GatewayEvent

/// Events emitted by the Gateway WebSocket connection.
/// Carries inbox, memory, briefing, and push notification events.
enum GatewayEvent: Sendable {
    // Inbox events
    /// A batch of triaged messages (initial load or refresh).
    case messages([InboxMessage])
    /// A single message was added or updated.
    case update(InboxMessage)
    /// Server confirmed a message was marked as read.
    case readConfirmed(messageID: String)

    // Memory events
    /// Full list of memories from the gateway (sync response).
    case memoryList([Memory])
    /// A new memory was created by the AI.
    case memoryCreated(Memory)
    /// An existing memory was updated.
    case memoryUpdated(Memory)
    /// A memory was deleted (by user request or gateway cleanup).
    case memoryDeleted(memoryId: String)

    // Briefing events
    /// A morning briefing was generated and delivered.
    case briefing(Briefing)

    // Push events
    /// Gateway confirmed receipt of the APNs device token.
    case deviceTokenConfirmed

    // Connection events
    /// The connection was lost; the UI may show a reconnect indicator.
    case disconnected
    /// Successfully (re)connected to the gateway.
    case connected
}

// MARK: - InboxServiceProtocol

/// Abstraction over the WebSocket connection to the OpenClaw Gateway.
/// Carries inbox, memory, briefing, and push notification events.
/// The mock implementation yields canned events for previews and tests.
protocol InboxServiceProtocol: Sendable {
    /// Subscribes to all gateway events.
    /// The stream stays open until `unsubscribe()` is called or the task is cancelled.
    func subscribe() -> AsyncThrowingStream<GatewayEvent, Error>

    /// Asks the gateway to re-poll all sources and push fresh triaged messages.
    func requestRefresh() async throws

    /// Tells the gateway a message has been read (so it can update cross-device state).
    func markAsRead(messageID: String) async throws

    /// Sends the user's current VIP list and priority topics to the gateway.
    func sendConfig(vips: [String], topics: [String]) async throws

    /// Sends the APNs device token to the gateway for push notifications.
    func sendDeviceToken(_ token: String) async throws

    /// Requests a full sync of all memories from the gateway.
    func requestMemorySync() async throws

    /// Requests deletion of a memory by its gateway-assigned ID.
    func deleteMemory(id: String) async throws

    /// Sends the user's briefing configuration to the gateway.
    func sendBriefingConfig(enabled: Bool, time: String, timezone: String, sources: [String]) async throws

    /// Tears down the WebSocket connection.
    func unsubscribe()
}

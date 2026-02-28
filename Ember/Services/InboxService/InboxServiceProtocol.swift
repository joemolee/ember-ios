import Foundation

// MARK: - InboxEvent

/// Events emitted by `InboxService` to the subscribing view model.
enum InboxEvent: Sendable {
    /// A batch of triaged messages (initial load or refresh).
    case messages([InboxMessage])
    /// A single message was added or updated.
    case update(InboxMessage)
    /// Server confirmed a message was marked as read.
    case readConfirmed(messageID: String)
    /// The connection was lost; the UI may show a reconnect indicator.
    case disconnected
    /// Successfully (re)connected to the gateway.
    case connected
}

// MARK: - InboxServiceProtocol

/// Abstraction over the inbox WebSocket connection to the OpenClaw Gateway.
/// The mock implementation yields canned events for previews and tests.
protocol InboxServiceProtocol: Sendable {
    /// Subscribes to inbox events from the gateway.
    /// The stream stays open until `unsubscribe()` is called or the task is cancelled.
    func subscribe() -> AsyncThrowingStream<InboxEvent, Error>

    /// Asks the gateway to re-poll all sources and push fresh triaged messages.
    func requestRefresh() async throws

    /// Tells the gateway a message has been read (so it can update cross-device state).
    func markAsRead(messageID: String) async throws

    /// Sends the user's current VIP list and priority topics to the gateway.
    func sendConfig(vips: [String], topics: [String]) async throws

    /// Tears down the WebSocket connection.
    func unsubscribe()
}

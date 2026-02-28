import XCTest
@testable import Ember

final class SSEStreamParserTests: XCTestCase {

    // The system under test. Re-created before every test so state never leaks.
    private var parser: SSEStreamParser!

    override func setUp() {
        super.setUp()
        parser = SSEStreamParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - 1. Single complete SSE event

    /// A well-formed SSE block with an `event:` line, a `data:` line, and the
    /// mandatory blank-line terminator must produce exactly one event with the
    /// correct event type and data payload.
    func test_parse_singleCompleteEvent_returnsOneEvent() {
        let chunk = "event: content_block_delta\ndata: {\"type\":\"content_block_delta\"}\n\n"

        let events = parser.parse(chunk)

        XCTAssertEqual(events.count, 1, "Expected exactly one parsed event")
        XCTAssertEqual(events[0].event, "content_block_delta")
        XCTAssertEqual(events[0].data, "{\"type\":\"content_block_delta\"}")
    }

    // MARK: - 2. Multiple events in a single chunk

    /// Two complete SSE events delivered in a single `parse` call must each be
    /// returned as a separate `SSEEvent`.
    func test_parse_multipleEventsInOneChunk_returnsAllEvents() {
        let chunk = """
        event: message_start
        data: {"type":"message_start"}

        event: content_block_start
        data: {"type":"content_block_start","index":0}

        """

        let events = parser.parse(chunk)

        XCTAssertEqual(events.count, 2, "Expected two events from a chunk containing two SSE blocks")
        XCTAssertEqual(events[0].event, "message_start")
        XCTAssertEqual(events[1].event, "content_block_start")
    }

    // MARK: - 3. Partial chunks — data split across two calls

    /// An SSE event whose bytes arrive across two separate calls must not be
    /// emitted until the terminating blank line has been received.  Only after
    /// the second call, which completes the event, should one event be returned.
    func test_parse_partialChunks_buffersUntilEventComplete() {
        let firstHalf  = "event: content_block_delta\ndata: {\"delta\":{\"type\":\"text_delta\",\"text\":\"Hi\"}}"
        let secondHalf = "\n\n"

        let eventsAfterFirstHalf = parser.parse(firstHalf)
        XCTAssertEqual(eventsAfterFirstHalf.count, 0, "Incomplete event must not be emitted yet")

        let eventsAfterSecondHalf = parser.parse(secondHalf)
        XCTAssertEqual(eventsAfterSecondHalf.count, 1, "Complete event must be emitted after the blank-line delimiter arrives")
        XCTAssertEqual(eventsAfterSecondHalf[0].event, "content_block_delta")
    }

    // MARK: - 4. extractTextDelta — happy path

    /// `extractTextDelta` must return the string value of `delta.text` from a
    /// correctly shaped `content_block_delta` JSON payload.
    func test_extractTextDelta_validEvent_returnsText() {
        let json = "{\"type\":\"content_block_delta\",\"index\":0,\"delta\":{\"type\":\"text_delta\",\"text\":\"Hello \"}}"
        let event = SSEEvent(event: "content_block_delta", data: json)

        let text = parser.extractTextDelta(from: event)

        XCTAssertEqual(text, "Hello ", "extractTextDelta must return the exact text from delta.text")
    }

    // MARK: - 5. extractTextDelta — wrong event type returns nil

    /// `extractTextDelta` must return `nil` when the `event` field is anything
    /// other than `"content_block_delta"` — even if the JSON payload would
    /// otherwise be valid.
    func test_extractTextDelta_wrongEventType_returnsNil() {
        let json = "{\"delta\":{\"type\":\"text_delta\",\"text\":\"should not appear\"}}"
        let event = SSEEvent(event: "message_start", data: json)

        let text = parser.extractTextDelta(from: event)

        XCTAssertNil(text, "extractTextDelta must return nil for non-content_block_delta events")
    }

    // MARK: - 6. isMessageStop

    /// `isMessageStop` must return `true` only for events whose `event` field
    /// is exactly `"message_stop"`.
    func test_isMessageStop_messageStopEvent_returnsTrue() {
        let stopEvent  = SSEEvent(event: "message_stop", data: "{\"type\":\"message_stop\"}")
        let otherEvent = SSEEvent(event: "content_block_delta", data: "{}")

        XCTAssertTrue(parser.isMessageStop(stopEvent),  "isMessageStop must return true for message_stop")
        XCTAssertFalse(parser.isMessageStop(otherEvent), "isMessageStop must return false for other event types")
    }

    // MARK: - 7. extractError — API error event

    /// When the server sends an `error` event whose JSON contains
    /// `error.message`, `extractError` must return that message string.
    func test_extractError_validErrorEvent_returnsMessage() {
        let json  = "{\"type\":\"error\",\"error\":{\"type\":\"overloaded_error\",\"message\":\"Overloaded\"}}"
        let event = SSEEvent(event: "error", data: json)

        let message = parser.extractError(from: event)

        XCTAssertEqual(message, "Overloaded", "extractError must return the value of error.message")
    }

    // MARK: - 8. extractError — non-error event returns nil

    /// `extractError` must return `nil` for any event that is not of type `"error"`.
    func test_extractError_nonErrorEvent_returnsNil() {
        let json  = "{\"error\":{\"message\":\"ghost message\"}}"
        let event = SSEEvent(event: "content_block_delta", data: json)

        let message = parser.extractError(from: event)

        XCTAssertNil(message, "extractError must return nil when the event type is not 'error'")
    }

    // MARK: - 9. Empty / malformed data lines

    /// A chunk with no `data:` or `event:` lines must produce an event with
    /// both fields `nil` — and the parser must not crash or emit that event
    /// (the implementation filters out events where both fields are nil).
    func test_parse_emptyDataChunk_producesNoEvents() {
        // A blank SSE block — just the double newline terminator with no content.
        let chunk = "\n\n"

        let events = parser.parse(chunk)

        XCTAssertEqual(events.count, 0, "A blank SSE block with no event or data lines must not produce an event")
    }

    // MARK: - 10. reset() clears the internal buffer

    /// After `reset()`, previously buffered partial data must be discarded so
    /// that subsequent `parse` calls start clean.
    func test_reset_clearsBuffer() {
        // Feed a partial event (no terminating blank line) to prime the buffer.
        _ = parser.parse("event: content_block_delta\ndata: {\"partial\":true}")

        // Reset must clear that buffered content.
        parser.reset()

        // Supplying just the terminator without preceding content must yield nothing.
        let eventsAfterReset = parser.parse("\n\n")

        XCTAssertEqual(eventsAfterReset.count, 0, "After reset(), the buffer must be empty; no stale partial event should be emitted")
    }

    // MARK: - 11. Full round-trip: parse then extractTextDelta

    /// Verifies that the output of `parse` can be fed directly into
    /// `extractTextDelta`, testing the two functions working together.
    func test_roundTrip_parseAndExtractTextDelta() {
        let text = "Swift is great"
        let json = "{\"type\":\"content_block_delta\",\"index\":0,\"delta\":{\"type\":\"text_delta\",\"text\":\"\(text)\"}}"
        let chunk = "event: content_block_delta\ndata: \(json)\n\n"

        let events = parser.parse(chunk)
        XCTAssertEqual(events.count, 1)

        let extracted = parser.extractTextDelta(from: events[0])
        XCTAssertEqual(extracted, text, "Round-trip through parse then extractTextDelta must recover the original text")
    }

    // MARK: - 12. Data-only event (no event: line)

    /// SSE allows `data:`-only blocks without an `event:` line.
    /// The parser must return such an event with `event == nil` and `data` set.
    func test_parse_dataOnlyEvent_returnsEventWithNilEventType() {
        let chunk = "data: raw payload\n\n"

        let events = parser.parse(chunk)

        XCTAssertEqual(events.count, 1)
        XCTAssertNil(events[0].event,       "data-only SSE block must have a nil event type")
        XCTAssertEqual(events[0].data, "raw payload")
    }
}

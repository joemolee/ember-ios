import Foundation

struct SSEEvent {
    let event: String?
    let data: String?
}

final class SSEStreamParser {

    private var buffer = ""

    /// Parse a chunk of raw SSE text, handling partial lines by buffering.
    /// Returns fully parsed events from the accumulated buffer.
    func parse(_ chunk: String) -> [SSEEvent] {
        buffer.append(chunk)

        var events: [SSEEvent] = []
        // SSE events are separated by double newlines
        while let range = buffer.range(of: "\n\n") {
            let rawEvent = String(buffer[buffer.startIndex..<range.lowerBound])
            buffer = String(buffer[range.upperBound...])

            let parsed = parseRawEvent(rawEvent)
            if parsed.event != nil || parsed.data != nil {
                events.append(parsed)
            }
        }

        return events
    }

    /// Extract the text delta from a content_block_delta event.
    func extractTextDelta(from event: SSEEvent) -> String? {
        guard event.event == "content_block_delta",
              let data = event.data,
              let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let delta = json["delta"] as? [String: Any],
              let text = delta["text"] as? String
        else {
            return nil
        }
        return text
    }

    /// Check if the event signals an error from the API.
    func extractError(from event: SSEEvent) -> String? {
        guard event.event == "error",
              let data = event.data,
              let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String
        else {
            return nil
        }
        return message
    }

    /// Check if the event signals the end of the message stream.
    func isMessageStop(_ event: SSEEvent) -> Bool {
        event.event == "message_stop"
    }

    /// Reset the internal buffer for reuse.
    func reset() {
        buffer = ""
    }

    // MARK: - Private

    private func parseRawEvent(_ raw: String) -> SSEEvent {
        var eventType: String?
        var dataLines: [String] = []

        let lines = raw.components(separatedBy: "\n")

        for line in lines {
            if line.hasPrefix("event:") {
                let value = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
                eventType = value
            } else if line.hasPrefix("data:") {
                let value = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                dataLines.append(value)
            }
            // Ignore "id:", "retry:", and comment lines starting with ":"
        }

        let data = dataLines.isEmpty ? nil : dataLines.joined(separator: "\n")
        return SSEEvent(event: eventType, data: data)
    }
}

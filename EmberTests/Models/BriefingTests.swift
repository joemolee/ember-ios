import XCTest
@testable import Ember

final class BriefingTests: XCTestCase {

    // MARK: - Codable Round-Trip

    func testBriefingCodableRoundTrip() throws {
        let briefing = Briefing(
            id: "brief-001",
            title: "Morning Briefing",
            summary: "You have 5 urgent messages and 3 action items.",
            date: Date(timeIntervalSince1970: 1700000000),
            actionItems: ["Review budget deck", "Respond to Lindsay"],
            sourceMessages: ["imsg-001", "slack-001"],
            messageCount: 12,
            urgentCount: 5
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(briefing)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Briefing.self, from: data)

        XCTAssertEqual(briefing, decoded)
        XCTAssertEqual(decoded.id, "brief-001")
        XCTAssertEqual(decoded.title, "Morning Briefing")
        XCTAssertEqual(decoded.actionItems.count, 2)
        XCTAssertEqual(decoded.messageCount, 12)
        XCTAssertEqual(decoded.urgentCount, 5)
    }

    func testBriefingArrayCodableRoundTrip() throws {
        let briefings = [
            Briefing(id: "1", title: "Monday", summary: "Summary 1", date: Date(), messageCount: 5, urgentCount: 1),
            Briefing(id: "2", title: "Tuesday", summary: "Summary 2", date: Date().addingTimeInterval(-86400), messageCount: 3, urgentCount: 0),
        ]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(briefings)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([Briefing].self, from: data)

        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].title, "Monday")
        XCTAssertEqual(decoded[1].title, "Tuesday")
    }

    // MARK: - Defaults

    func testBriefingDefaultValues() {
        let briefing = Briefing(title: "Test", summary: "Summary")

        XCTAssertFalse(briefing.id.isEmpty)
        XCTAssertEqual(briefing.actionItems, [])
        XCTAssertEqual(briefing.sourceMessages, [])
        XCTAssertEqual(briefing.messageCount, 0)
        XCTAssertEqual(briefing.urgentCount, 0)
    }

    // MARK: - Equatable

    func testBriefingEquatable() {
        let date = Date()
        let a = Briefing(id: "same", title: "T", summary: "S", date: date, messageCount: 1, urgentCount: 0)
        let b = Briefing(id: "same", title: "T", summary: "S", date: date, messageCount: 1, urgentCount: 0)
        let c = Briefing(id: "different", title: "T", summary: "S", date: date, messageCount: 1, urgentCount: 0)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - JSON Parse (Gateway Format)

    func testParseBriefingFromGatewayJSON() throws {
        let json = """
        {
            "id": "brief-gateway-001",
            "title": "Your Morning Briefing",
            "summary": "You received 15 messages overnight. 3 are urgent.",
            "date": "2024-11-14T07:00:00Z",
            "actionItems": ["Reply to Lindsay about budget", "Review staging fix"],
            "sourceMessages": ["imsg-001", "slack-001", "teams-001"],
            "messageCount": 15,
            "urgentCount": 3
        }
        """

        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let briefing = try decoder.decode(Briefing.self, from: data)

        XCTAssertEqual(briefing.id, "brief-gateway-001")
        XCTAssertEqual(briefing.title, "Your Morning Briefing")
        XCTAssertEqual(briefing.actionItems.count, 2)
        XCTAssertEqual(briefing.sourceMessages.count, 3)
        XCTAssertEqual(briefing.messageCount, 15)
        XCTAssertEqual(briefing.urgentCount, 3)
    }
}

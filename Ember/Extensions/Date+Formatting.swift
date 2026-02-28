import Foundation

// MARK: - Date Formatting Helpers

extension Date {

    /// Returns a human-readable relative time string.
    /// Examples: "Just now", "2m ago", "1h ago", "Yesterday", "3d ago", "Feb 15"
    var timeAgo: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        // Future dates or essentially now
        guard interval >= 0 else { return "Just now" }

        let seconds = Int(interval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24

        if seconds < 60 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days)d ago"
        } else {
            return Self.timeAgoDateFormatter.string(from: self)
        }
    }

    /// Returns a timestamp formatted for chat messages.
    /// - Today: "2:34 PM"
    /// - Yesterday: "Yesterday 2:34 PM"
    /// - This year: "Feb 15, 2:34 PM"
    /// - Older: "Feb 15, 2025"
    var chatTimestamp: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(self) {
            return Self.timeOnlyFormatter.string(from: self)
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday \(Self.timeOnlyFormatter.string(from: self))"
        } else if calendar.component(.year, from: self) == calendar.component(.year, from: now) {
            return Self.monthDayTimeFormatter.string(from: self)
        } else {
            return Self.monthDayYearFormatter.string(from: self)
        }
    }

    // MARK: - Private Formatters (cached for performance)

    private static let timeAgoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let monthDayTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()

    private static let monthDayYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

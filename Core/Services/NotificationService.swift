import Foundation

public enum NotificationKind: String, CaseIterable, Sendable, Hashable {
    case tdSundayDigest
    case certExpiring
    case attendanceReminder
    case gradingScheduled
    case tournamentRegistration
    case liveMatchAlert

    public var labelKey: String { "notif.kind.\(rawValue)" }
    public var preferenceKey: String { "notif.\(rawValue).enabled" }
}

public protocol NotificationScheduler: Sendable {
    func requestAuthorization() async -> Bool
    func scheduleLocal(id: String, title: String, body: String, fireAt: Date) async throws
    func cancel(id: String) async
}

public struct SundayDigest: Sendable, Hashable {
    public let scoresAvg: Double
    public let watchListCount: Int
    public let certsExpiring: Int
    public let fireAt: Date

    public init(scoresAvg: Double, watchListCount: Int, certsExpiring: Int, fireAt: Date) {
        self.scoresAvg = scoresAvg
        self.watchListCount = watchListCount
        self.certsExpiring = certsExpiring
        self.fireAt = fireAt
    }
}

public enum DigestBuilder {

    /// Compute the next Sunday at 08:00 local time strictly after `from`.
    public static func nextSunday8am(from: Date) -> Date {
        let cal = Calendar.current
        var components = DateComponents()
        components.weekday = 1 // Sunday in Calendar.current (Gregorian)
        components.hour = 8
        components.minute = 0
        components.second = 0
        return cal.nextDate(after: from, matching: components, matchingPolicy: .nextTime) ?? from.addingTimeInterval(7 * 24 * 3600)
    }

    public static func buildSundayDigest(
        date: Date,
        scoresAvg: Double,
        watchListCount: Int,
        certsExpiring: Int
    ) -> SundayDigest {
        SundayDigest(
            scoresAvg: scoresAvg,
            watchListCount: watchListCount,
            certsExpiring: certsExpiring,
            fireAt: nextSunday8am(from: date)
        )
    }
}

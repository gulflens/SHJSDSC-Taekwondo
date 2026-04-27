import Foundation

public enum DayOfWeek: Int, Codable, CaseIterable, Sendable, Hashable {
    case sun = 1, mon, tue, wed, thu, fri, sat

    public var labelKey: String { "day.\(self)" }
}

public struct DayHours: Codable, Hashable, Sendable {
    public var day: DayOfWeek
    public var isOpen: Bool
    public var opensAt: String?    // "06:00" 24h format
    public var closesAt: String?   // "23:00"

    public init(day: DayOfWeek, isOpen: Bool, opensAt: String? = nil, closesAt: String? = nil) {
        self.day = day
        self.isOpen = isOpen
        self.opensAt = opensAt
        self.closesAt = closesAt
    }
}

public struct BranchHours: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var branchID: EntityID
    public var regular: [DayHours]
    public var ramadan: [DayHours]?
    public var ramadanStart: Date?
    public var ramadanEnd: Date?
    public var holidayClosures: [Date]
    public var termBreaks: [DateInterval]

    public init(
        id: EntityID = UUID(),
        branchID: EntityID,
        regular: [DayHours],
        ramadan: [DayHours]? = nil,
        ramadanStart: Date? = nil,
        ramadanEnd: Date? = nil,
        holidayClosures: [Date] = [],
        termBreaks: [DateInterval] = []
    ) {
        self.id = id
        self.branchID = branchID
        self.regular = regular
        self.ramadan = ramadan
        self.ramadanStart = ramadanStart
        self.ramadanEnd = ramadanEnd
        self.holidayClosures = holidayClosures
        self.termBreaks = termBreaks
    }

    /// True when `now` falls inside the configured Ramadan window.
    public func isRamadanActive(now: Date = Date()) -> Bool {
        guard let start = ramadanStart, let end = ramadanEnd else { return false }
        return now >= start && now <= end
    }

    /// Currently-applicable hours table — Ramadan overrides regular when active.
    public func currentSchedule(now: Date = Date()) -> [DayHours] {
        if isRamadanActive(now: now), let r = ramadan { return r }
        return regular
    }

    /// Today's hours entry (or nil if the schedule is missing it).
    public func today(now: Date = Date()) -> DayHours? {
        let cal = Calendar(identifier: .gregorian)
        let weekday = cal.component(.weekday, from: now)   // 1 = Sunday
        return currentSchedule(now: now).first { $0.day.rawValue == weekday }
    }

    /// Whether the branch is currently within its open hours. Falls back to
    /// false on any parse failure (callers can show a neutral state).
    public func isOpenNow(now: Date = Date()) -> Bool {
        guard let today = today(now: now), today.isOpen,
              let opens = today.opensAt, let closes = today.closesAt else { return false }
        let cal = Calendar(identifier: .gregorian)
        let parts = cal.dateComponents([.hour, .minute], from: now)
        let nowMinutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        let openMins = parseHHmm(opens) ?? 0
        let closeMins = parseHHmm(closes) ?? 0
        if closeMins >= openMins {
            return nowMinutes >= openMins && nowMinutes < closeMins
        } else {
            // Late-night close that wraps past midnight (Ramadan: 21:00–01:00)
            return nowMinutes >= openMins || nowMinutes < closeMins
        }
    }

    private func parseHHmm(_ s: String) -> Int? {
        let parts = s.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return h * 60 + m
    }
}

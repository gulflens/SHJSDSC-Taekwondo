import Foundation

public enum GoalStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case active, completed, abandoned

    public var labelKey: String { "goal.status.\(rawValue)" }
}

public struct Goal: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var athleteID: EntityID
    public var title: String
    public var targetDate: Date?
    public var status: GoalStatus
    public var createdAt: Date
    public var completedAt: Date?
    public var notes: String?

    public init(
        id: EntityID = UUID(),
        athleteID: EntityID,
        title: String,
        targetDate: Date? = nil,
        status: GoalStatus = .active,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.athleteID = athleteID
        self.title = title
        self.targetDate = targetDate
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.notes = notes
    }

    public var isOverdue: Bool {
        guard status == .active, let target = targetDate else { return false }
        return target < Date()
    }
}

public extension Array where Element == Goal {
    /// Goal completion rate over goals that have reached a terminal state.
    /// Active goals don't count for or against. Returns nil when there are
    /// no completed-or-abandoned entries.
    var completionRate: Double? {
        let terminal = self.filter { $0.status != .active }
        guard !terminal.isEmpty else { return nil }
        let completed = terminal.filter { $0.status == .completed }.count
        return Double(completed) / Double(terminal.count)
    }
}

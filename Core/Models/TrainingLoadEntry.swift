import Foundation

public enum SessionType: String, Codable, CaseIterable, Sendable, Hashable {
    case technique, sparring, fitness, poomsae, mixed

    public var labelKey: String { "session_type.\(rawValue)" }

    public var systemIcon: String {
        switch self {
        case .technique: "figure.kickboxing"
        case .sparring: "figure.boxing"
        case .fitness: "figure.strengthtraining.traditional"
        case .poomsae: "figure.taichi"
        case .mixed: "circle.grid.2x2"
        }
    }
}

public struct TrainingLoadEntry: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var athleteID: EntityID
    /// Optional link to a `ClassSession` row when the entry corresponds to a
    /// scheduled session. Standalone entries (home practice, supplementary
    /// work) leave this nil.
    public var sessionID: EntityID?
    public var recordedAt: Date
    public var sessionType: SessionType
    public var durationMinutes: Int
    /// 1...10 — Borg-style perceived exertion.
    public var rpe: Int
    public var notes: String?

    public init(
        id: EntityID = UUID(),
        athleteID: EntityID,
        sessionID: EntityID? = nil,
        recordedAt: Date,
        sessionType: SessionType,
        durationMinutes: Int,
        rpe: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.athleteID = athleteID
        self.sessionID = sessionID
        self.recordedAt = recordedAt
        self.sessionType = sessionType
        self.durationMinutes = max(0, durationMinutes)
        self.rpe = max(1, min(10, rpe))
        self.notes = notes
    }

    /// Foster's session-RPE: duration (min) × RPE → arbitrary units (AU).
    public var sessionLoad: Double {
        Double(durationMinutes) * Double(rpe)
    }
}

/// Risk classification from the acute:chronic workload ratio (ACWR). The
/// commonly cited "sweet spot" is 0.8–1.3; >1.5 is the user-defined danger
/// zone. Below 0.8 indicates undertraining (deconditioning risk).
public enum LoadRisk: String, Sendable, Hashable {
    case undertrained, sweet, elevated, danger, unknown

    public var labelKey: String { "load_risk.\(rawValue)" }
}

public extension Array where Element == TrainingLoadEntry {

    /// Sum of session loads in the last `days` days (default 7), ending at `asOf`.
    func acuteLoad(asOf date: Date = Date(), days: Int = 7) -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: date) ?? date
        return self.filter { $0.recordedAt > cutoff && $0.recordedAt <= date }
            .map(\.sessionLoad)
            .reduce(0, +)
    }

    /// Sum of session loads in the last `days` days (default 28).
    func chronicLoad(asOf date: Date = Date(), days: Int = 28) -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: date) ?? date
        return self.filter { $0.recordedAt > cutoff && $0.recordedAt <= date }
            .map(\.sessionLoad)
            .reduce(0, +)
    }

    /// ACWR = (7-day weekly average) / (28-day weekly average)
    ///       = (7-day sum / 1) / (28-day sum / 4)
    /// Returns nil when chronic load is zero (insufficient history).
    func acwr(asOf date: Date = Date()) -> Double? {
        let acute = acuteLoad(asOf: date)
        let chronicWeekly = chronicLoad(asOf: date) / 4.0
        guard chronicWeekly > 0 else { return nil }
        return acute / chronicWeekly
    }

    func loadRisk(asOf date: Date = Date()) -> LoadRisk {
        guard let r = acwr(asOf: date) else { return .unknown }
        switch r {
        case ..<0.8: return .undertrained
        case 0.8..<1.3: return .sweet
        case 1.3..<1.5: return .elevated
        default: return .danger
        }
    }
}

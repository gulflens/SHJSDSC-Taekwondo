import Foundation

public struct WellnessEntry: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var athleteID: EntityID
    public var recordedAt: Date
    public var sleepHours: Double
    /// 1...10 — higher = better mood.
    public var mood: Int
    /// 1...10 — higher = more sore.
    public var soreness: Int
    /// 1...10 — higher = more motivated.
    public var motivation: Int
    /// 1...10 — higher = more stressed.
    public var stress: Int
    /// 1...10 — Borg-style RPE for the most recent training session.
    public var rpePreviousSession: Int
    public var notes: String?

    public init(
        id: EntityID = UUID(),
        athleteID: EntityID,
        recordedAt: Date,
        sleepHours: Double,
        mood: Int,
        soreness: Int,
        motivation: Int = 5,
        stress: Int = 5,
        rpePreviousSession: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.athleteID = athleteID
        self.recordedAt = recordedAt
        self.sleepHours = sleepHours
        self.mood = max(1, min(10, mood))
        self.soreness = max(1, min(10, soreness))
        self.motivation = max(1, min(10, motivation))
        self.stress = max(1, min(10, stress))
        self.rpePreviousSession = max(1, min(10, rpePreviousSession))
        self.notes = notes
    }

    // Decoding fallback so rows pre-Pillar-5 (no motivation/stress columns)
    // still load.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(EntityID.self, forKey: .id)
        self.athleteID = try c.decode(EntityID.self, forKey: .athleteID)
        self.recordedAt = try c.decode(Date.self, forKey: .recordedAt)
        self.sleepHours = try c.decode(Double.self, forKey: .sleepHours)
        self.mood = try c.decode(Int.self, forKey: .mood)
        self.soreness = try c.decode(Int.self, forKey: .soreness)
        self.motivation = try c.decodeIfPresent(Int.self, forKey: .motivation) ?? 5
        self.stress = try c.decodeIfPresent(Int.self, forKey: .stress) ?? 5
        self.rpePreviousSession = try c.decode(Int.self, forKey: .rpePreviousSession)
        self.notes = try c.decodeIfPresent(String.self, forKey: .notes)
    }
}

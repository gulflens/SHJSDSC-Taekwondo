import Foundation

// Profile-detail types layered onto Athlete. Kept in a sibling file so the
// core Athlete model stays readable.

public enum BloodType: String, Codable, CaseIterable, Sendable, Hashable {
    case aPositive = "A+"
    case aNegative = "A-"
    case bPositive = "B+"
    case bNegative = "B-"
    case oPositive = "O+"
    case oNegative = "O-"
    case abPositive = "AB+"
    case abNegative = "AB-"
    case unknown

    public var labelKey: String { "blood.\(rawValue)" }
    public var display: String { self == .unknown ? "?" : rawValue }
}

public enum Stance: String, Codable, CaseIterable, Sendable, Hashable {
    case orthodox, southpaw, switchStance

    public var labelKey: String { "stance.\(rawValue)" }
}

public enum KyorugiTier: String, Codable, CaseIterable, Sendable, Hashable {
    case recreational, competitive, elite

    public var labelKey: String { "kyorugi_tier.\(rawValue)" }
}

public enum InjurySeverity: String, Codable, CaseIterable, Sendable, Hashable {
    case minor, moderate, severe

    public var labelKey: String { "injury_severity.\(rawValue)" }
}

public struct EmergencyContact: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var name: String
    public var relationship: String
    public var phone: String

    public init(id: EntityID = UUID(), name: String, relationship: String, phone: String) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.phone = phone
    }
}

public struct WeightEntry: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var recordedAt: Date
    public var weightKg: Double

    public init(id: EntityID = UUID(), recordedAt: Date = Date(), weightKg: Double) {
        self.id = id
        self.recordedAt = recordedAt
        self.weightKg = weightKg
    }
}

public struct InjuryEntry: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var recordedAt: Date
    public var description: String
    public var severity: InjurySeverity
    public var returnToTrainAt: Date?
    public var notes: String?

    public init(
        id: EntityID = UUID(),
        recordedAt: Date = Date(),
        description: String,
        severity: InjurySeverity,
        returnToTrainAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.description = description
        self.severity = severity
        self.returnToTrainAt = returnToTrainAt
        self.notes = notes
    }
}

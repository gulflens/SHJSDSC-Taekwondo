import Foundation

public struct PhysicalTest: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var athleteID: EntityID
    public var recordedAt: Date
    public var recordedByCoachID: EntityID
    public var beepTestStage: Double
    public var verticalJumpCm: Double
    public var sprint30mSec: Double
    public var agility4x10Sec: Double
    public var pushUps1Min: Int
    public var notes: String?

    public init(
        id: EntityID = UUID(),
        athleteID: EntityID,
        recordedAt: Date,
        recordedByCoachID: EntityID,
        beepTestStage: Double,
        verticalJumpCm: Double,
        sprint30mSec: Double,
        agility4x10Sec: Double,
        pushUps1Min: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.athleteID = athleteID
        self.recordedAt = recordedAt
        self.recordedByCoachID = recordedByCoachID
        self.beepTestStage = beepTestStage
        self.verticalJumpCm = verticalJumpCm
        self.sprint30mSec = sprint30mSec
        self.agility4x10Sec = agility4x10Sec
        self.pushUps1Min = pushUps1Min
        self.notes = notes
    }
}

public struct TechnicalAssessment: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var athleteID: EntityID
    public var recordedAt: Date
    public var recordedByCoachID: EntityID
    public var poomsaeForm: String
    public var power: Int
    public var accuracy: Int
    public var rhythm: Int
    public var balance: Int
    public var expression: Int
    public var notes: String?

    public init(
        id: EntityID = UUID(),
        athleteID: EntityID,
        recordedAt: Date,
        recordedByCoachID: EntityID,
        poomsaeForm: String,
        power: Int,
        accuracy: Int,
        rhythm: Int,
        balance: Int,
        expression: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.athleteID = athleteID
        self.recordedAt = recordedAt
        self.recordedByCoachID = recordedByCoachID
        self.poomsaeForm = poomsaeForm
        self.power = power
        self.accuracy = accuracy
        self.rhythm = rhythm
        self.balance = balance
        self.expression = expression
        self.notes = notes
    }

    public var average: Double {
        Double(power + accuracy + rhythm + balance + expression) / 5.0
    }
}

public struct WellnessEntry: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var athleteID: EntityID
    public var recordedAt: Date
    public var sleepHours: Double
    public var mood: Int
    public var soreness: Int
    public var rpePreviousSession: Int
    public var notes: String?

    public init(
        id: EntityID = UUID(),
        athleteID: EntityID,
        recordedAt: Date,
        sleepHours: Double,
        mood: Int,
        soreness: Int,
        rpePreviousSession: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.athleteID = athleteID
        self.recordedAt = recordedAt
        self.sleepHours = sleepHours
        self.mood = mood
        self.soreness = soreness
        self.rpePreviousSession = rpePreviousSession
        self.notes = notes
    }
}

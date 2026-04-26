import Foundation

public struct GradingEligibility: Codable, Hashable, Sendable {
    public let athleteID: EntityID
    public let currentBelt: Belt
    public let targetBelt: Belt
    public let monthsAtCurrent: Int
    public let attendancePct: Double
    public let latestTechnicalAvg: Double
    public let latestPhysicalComposite: Double
    public let isEligible: Bool
    public let blockingReasons: [String]

    public init(
        athleteID: EntityID,
        currentBelt: Belt,
        targetBelt: Belt,
        monthsAtCurrent: Int,
        attendancePct: Double,
        latestTechnicalAvg: Double,
        latestPhysicalComposite: Double,
        isEligible: Bool,
        blockingReasons: [String]
    ) {
        self.athleteID = athleteID
        self.currentBelt = currentBelt
        self.targetBelt = targetBelt
        self.monthsAtCurrent = monthsAtCurrent
        self.attendancePct = attendancePct
        self.latestTechnicalAvg = latestTechnicalAvg
        self.latestPhysicalComposite = latestPhysicalComposite
        self.isEligible = isEligible
        self.blockingReasons = blockingReasons
    }
}

public enum GradingSessionStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case scheduled, inProgress, completed, cancelled

    public var labelKey: String { "grading.status.\(rawValue)" }
}

public struct GradingSession: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var scheduledAt: Date
    public var branchID: EntityID
    public var examinerCoachIDs: [EntityID]
    public var candidateAthleteIDs: [EntityID]
    public var status: GradingSessionStatus

    public init(
        id: EntityID = UUID(),
        scheduledAt: Date,
        branchID: EntityID,
        examinerCoachIDs: [EntityID],
        candidateAthleteIDs: [EntityID],
        status: GradingSessionStatus = .scheduled
    ) {
        self.id = id
        self.scheduledAt = scheduledAt
        self.branchID = branchID
        self.examinerCoachIDs = examinerCoachIDs
        self.candidateAthleteIDs = candidateAthleteIDs
        self.status = status
    }
}

public enum GradingDecision: String, Codable, CaseIterable, Sendable, Hashable {
    case pass, fail, retry

    public var labelKey: String { "grading.decision.\(rawValue)" }
}

public struct GradingScore: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var sessionID: EntityID
    public var athleteID: EntityID
    public var examinerID: EntityID
    public var poomsae: Int
    public var kyorugi: Int
    public var kibon: Int
    public var breaking: Int
    public var notes: String?
    public var decision: GradingDecision

    public init(
        id: EntityID = UUID(),
        sessionID: EntityID,
        athleteID: EntityID,
        examinerID: EntityID,
        poomsae: Int,
        kyorugi: Int,
        kibon: Int,
        breaking: Int,
        notes: String? = nil,
        decision: GradingDecision
    ) {
        self.id = id
        self.sessionID = sessionID
        self.athleteID = athleteID
        self.examinerID = examinerID
        self.poomsae = poomsae
        self.kyorugi = kyorugi
        self.kibon = kibon
        self.breaking = breaking
        self.notes = notes
        self.decision = decision
    }

    public var total: Int { poomsae + kyorugi + kibon + breaking }
}

public struct GradingCertificate: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var athleteID: EntityID
    public var fromBelt: Belt
    public var toBelt: Belt
    public var awardedAt: Date
    public var sessionID: EntityID
    public var signedByCoachIDs: [EntityID]

    public init(
        id: EntityID = UUID(),
        athleteID: EntityID,
        fromBelt: Belt,
        toBelt: Belt,
        awardedAt: Date,
        sessionID: EntityID,
        signedByCoachIDs: [EntityID]
    ) {
        self.id = id
        self.athleteID = athleteID
        self.fromBelt = fromBelt
        self.toBelt = toBelt
        self.awardedAt = awardedAt
        self.sessionID = sessionID
        self.signedByCoachIDs = signedByCoachIDs
    }
}

import Foundation

public enum SquadPurpose: String, Codable, CaseIterable, Sendable, Hashable {
    case competition, trainingCamp, grading, notification, custom

    public var labelKey: String { "squad.purpose.\(rawValue)" }
}

public struct AthleteGroup: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var name: String
    public var nameAr: String?
    public var purpose: SquadPurpose
    public var createdByCoachID: EntityID
    public var athleteIDs: [EntityID]
    public var createdAt: Date
    public var expiresAt: Date?
    public var linkedTournamentID: EntityID?
    public var isArchived: Bool
    public var nationalityFilter: String?
    public var ageGroupFilter: AgeGroup?
    public var genderFilter: Gender?
    public var notes: String?

    public init(
        id: EntityID = UUID(),
        name: String,
        nameAr: String? = nil,
        purpose: SquadPurpose = .custom,
        createdByCoachID: EntityID,
        athleteIDs: [EntityID] = [],
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        linkedTournamentID: EntityID? = nil,
        isArchived: Bool = false,
        nationalityFilter: String? = nil,
        ageGroupFilter: AgeGroup? = nil,
        genderFilter: Gender? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.nameAr = nameAr
        self.purpose = purpose
        self.createdByCoachID = createdByCoachID
        self.athleteIDs = athleteIDs
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.linkedTournamentID = linkedTournamentID
        self.isArchived = isArchived
        self.nationalityFilter = nationalityFilter
        self.ageGroupFilter = ageGroupFilter
        self.genderFilter = genderFilter
        self.notes = notes
    }

    public var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }
}

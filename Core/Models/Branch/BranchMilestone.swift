import Foundation

public enum MilestoneCategory: String, Codable, Sendable, CaseIterable, Hashable {
    case founded, championshipWon, alumniAchievement, renovation
    case staffMilestone, recordSet, partnership

    public var labelKey: String { "milestone.\(self)" }
}

public struct BranchMilestone: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var branchID: EntityID
    public var occurredAt: Date
    public var titleEn: String
    public var titleAr: String
    public var descriptionEn: String?
    public var descriptionAr: String?
    public var category: MilestoneCategory

    public init(
        id: EntityID = UUID(),
        branchID: EntityID,
        occurredAt: Date,
        titleEn: String,
        titleAr: String,
        descriptionEn: String? = nil,
        descriptionAr: String? = nil,
        category: MilestoneCategory
    ) {
        self.id = id
        self.branchID = branchID
        self.occurredAt = occurredAt
        self.titleEn = titleEn
        self.titleAr = titleAr
        self.descriptionEn = descriptionEn
        self.descriptionAr = descriptionAr
        self.category = category
    }
}

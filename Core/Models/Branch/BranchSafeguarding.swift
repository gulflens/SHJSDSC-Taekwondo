import Foundation

public struct BranchSafeguarding: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var branchID: EntityID
    public var safeguardingOfficerCoachID: EntityID?
    public var lastTeamTrainingAt: Date?
    public var policyDocumentURL: String?
    /// 0..1, computed by the store from Coach safeguarding-cert validity.
    /// Stored as a snapshot so dashboards don't have to recompute on render.
    public var staffCheckCurrentPct: Double
    public var openIncidentCount: Int
    public var lastIncidentAt: Date?

    public init(
        id: EntityID = UUID(),
        branchID: EntityID,
        safeguardingOfficerCoachID: EntityID? = nil,
        lastTeamTrainingAt: Date? = nil,
        policyDocumentURL: String? = nil,
        staffCheckCurrentPct: Double = 0,
        openIncidentCount: Int = 0,
        lastIncidentAt: Date? = nil
    ) {
        self.id = id
        self.branchID = branchID
        self.safeguardingOfficerCoachID = safeguardingOfficerCoachID
        self.lastTeamTrainingAt = lastTeamTrainingAt
        self.policyDocumentURL = policyDocumentURL
        self.staffCheckCurrentPct = staffCheckCurrentPct
        self.openIncidentCount = openIncidentCount
        self.lastIncidentAt = lastIncidentAt
    }
}

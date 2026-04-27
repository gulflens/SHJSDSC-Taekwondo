import Foundation

public enum ComplianceStatus: String, Codable, Sendable, Hashable {
    case ok, expiring, expired

    public var labelKey: String { "compliance.\(self)" }
}

public struct BranchCompliance: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var branchID: EntityID
    public var civilDefenceCertNumber: String?
    public var civilDefenceExpiry: Date?
    public var sharjahSportsCouncilRegNumber: String?
    public var sharjahSportsCouncilExpiry: Date?
    public var insurancePolicyNumber: String?
    public var insuranceProvider: String?
    public var insuranceExpiry: Date?
    public var lastHealthSafetyInspectionAt: Date?
    public var lastEmergencyPlanReviewAt: Date?
    public var hasAED: Bool
    public var aedLastServiceAt: Date?
    public var firstAidKitLastCheckedAt: Date?

    public init(
        id: EntityID = UUID(),
        branchID: EntityID,
        civilDefenceCertNumber: String? = nil,
        civilDefenceExpiry: Date? = nil,
        sharjahSportsCouncilRegNumber: String? = nil,
        sharjahSportsCouncilExpiry: Date? = nil,
        insurancePolicyNumber: String? = nil,
        insuranceProvider: String? = nil,
        insuranceExpiry: Date? = nil,
        lastHealthSafetyInspectionAt: Date? = nil,
        lastEmergencyPlanReviewAt: Date? = nil,
        hasAED: Bool = false,
        aedLastServiceAt: Date? = nil,
        firstAidKitLastCheckedAt: Date? = nil
    ) {
        self.id = id
        self.branchID = branchID
        self.civilDefenceCertNumber = civilDefenceCertNumber
        self.civilDefenceExpiry = civilDefenceExpiry
        self.sharjahSportsCouncilRegNumber = sharjahSportsCouncilRegNumber
        self.sharjahSportsCouncilExpiry = sharjahSportsCouncilExpiry
        self.insurancePolicyNumber = insurancePolicyNumber
        self.insuranceProvider = insuranceProvider
        self.insuranceExpiry = insuranceExpiry
        self.lastHealthSafetyInspectionAt = lastHealthSafetyInspectionAt
        self.lastEmergencyPlanReviewAt = lastEmergencyPlanReviewAt
        self.hasAED = hasAED
        self.aedLastServiceAt = aedLastServiceAt
        self.firstAidKitLastCheckedAt = firstAidKitLastCheckedAt
    }

    /// Aggregated severity across all tracked expiries. Any expired/missing
    /// required cert dominates "expiring", which dominates "ok".
    public func status(now: Date = Date()) -> ComplianceStatus {
        let required: [Date?] = [civilDefenceExpiry, sharjahSportsCouncilExpiry, insuranceExpiry]
        var anyExpired = false
        var anyExpiring = false
        for date in required {
            guard let date else { anyExpired = true; continue }
            let days = Calendar(identifier: .gregorian).dateComponents([.day], from: now, to: date).day ?? 0
            if days < 0 { anyExpired = true }
            else if days <= 30 { anyExpiring = true }
        }
        if anyExpired { return .expired }
        if anyExpiring { return .expiring }
        return .ok
    }
}

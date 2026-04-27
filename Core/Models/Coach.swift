import Foundation

public enum ContractType: String, Codable, CaseIterable, Sendable, Hashable {
    case fullTime, partTime, contractor

    public var labelKey: String { "contract.\(rawValue)" }
}

public struct Coach: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var fullName: String
    public var fullNameAr: String
    public var primaryBranchID: EntityID
    public var secondaryBranchIDs: [EntityID]
    public var danRank: Int
    public var wtCoachLicenceLevel: Int
    public var firstAidExpiry: Date
    public var safeguardingExpiry: Date
    public var contractType: ContractType
    public var hiredAt: Date
    public var avatarSeed: String
    public var avatarURL: String?

    // === Credentials ===
    public var kukkiwonCertNumber: String?
    public var kukkiwonIssuedAt: Date?
    public var wtCoachLicenceExpiry: Date?
    public var poomsaeRefereeLevel: Int?
    public var poomsaeRefereeExpiry: Date?
    public var kyorugiRefereeLevel: Int?
    public var kyorugiRefereeExpiry: Date?
    public var antiDopingExpiry: Date?

    // === Assignment ===
    public var weeklyHoursTarget: Int?
    public var onCall: Bool
    public var bio: String?
    public var bioAr: String?

    // === Performance (snapshot) ===
    public var cpdHoursThisYear: Double
    public var parentSatisfactionAvg: Double?
    public var peerReviewAvg: Double?

    public init(
        id: EntityID = UUID(),
        fullName: String,
        fullNameAr: String,
        primaryBranchID: EntityID,
        secondaryBranchIDs: [EntityID] = [],
        danRank: Int,
        wtCoachLicenceLevel: Int,
        firstAidExpiry: Date,
        safeguardingExpiry: Date,
        contractType: ContractType,
        hiredAt: Date,
        avatarSeed: String,
        avatarURL: String? = nil,
        kukkiwonCertNumber: String? = nil,
        kukkiwonIssuedAt: Date? = nil,
        wtCoachLicenceExpiry: Date? = nil,
        poomsaeRefereeLevel: Int? = nil,
        poomsaeRefereeExpiry: Date? = nil,
        kyorugiRefereeLevel: Int? = nil,
        kyorugiRefereeExpiry: Date? = nil,
        antiDopingExpiry: Date? = nil,
        weeklyHoursTarget: Int? = nil,
        onCall: Bool = false,
        bio: String? = nil,
        bioAr: String? = nil,
        cpdHoursThisYear: Double = 0,
        parentSatisfactionAvg: Double? = nil,
        peerReviewAvg: Double? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.fullNameAr = fullNameAr
        self.primaryBranchID = primaryBranchID
        self.secondaryBranchIDs = secondaryBranchIDs
        self.danRank = danRank
        self.wtCoachLicenceLevel = wtCoachLicenceLevel
        self.firstAidExpiry = firstAidExpiry
        self.safeguardingExpiry = safeguardingExpiry
        self.contractType = contractType
        self.hiredAt = hiredAt
        self.avatarSeed = avatarSeed
        self.avatarURL = avatarURL
        self.kukkiwonCertNumber = kukkiwonCertNumber
        self.kukkiwonIssuedAt = kukkiwonIssuedAt
        self.wtCoachLicenceExpiry = wtCoachLicenceExpiry
        self.poomsaeRefereeLevel = poomsaeRefereeLevel
        self.poomsaeRefereeExpiry = poomsaeRefereeExpiry
        self.kyorugiRefereeLevel = kyorugiRefereeLevel
        self.kyorugiRefereeExpiry = kyorugiRefereeExpiry
        self.antiDopingExpiry = antiDopingExpiry
        self.weeklyHoursTarget = weeklyHoursTarget
        self.onCall = onCall
        self.bio = bio
        self.bioAr = bioAr
        self.cpdHoursThisYear = cpdHoursThisYear
        self.parentSatisfactionAvg = parentSatisfactionAvg
        self.peerReviewAvg = peerReviewAvg
    }

    public var initials: String {
        let parts = fullName.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }

    /// Localization keys for fields HQ recommends but a coach may be missing.
    /// Empty result = profile is "complete enough". Drives the warning banner
    /// in CoachDetailView (mirrors Athlete.missingProfileFields).
    public var missingProfileFields: [String] {
        var missing: [String] = []
        if (kukkiwonCertNumber ?? "").isEmpty { missing.append("coach.missing.kukkiwon") }
        if wtCoachLicenceExpiry == nil { missing.append("coach.missing.wt_licence_expiry") }
        if poomsaeRefereeLevel == nil { missing.append("coach.missing.poomsae_referee") }
        if kyorugiRefereeLevel == nil { missing.append("coach.missing.kyorugi_referee") }
        if antiDopingExpiry == nil { missing.append("coach.missing.anti_doping") }
        if weeklyHoursTarget == nil { missing.append("coach.missing.weekly_hours") }
        if (bio ?? "").isEmpty { missing.append("coach.missing.bio") }
        if (avatarURL ?? "").isEmpty { missing.append("coach.missing.photo") }
        return missing
    }

    /// 0...1, equally weighted across recommended fields.
    public var profileCompleteness: Double {
        let totalChecked = 8.0
        let missingCount = Double(missingProfileFields.count)
        return max(0, min(1, (totalChecked - missingCount) / totalChecked))
    }

    /// Earliest expiry across the coach's certifications. Nil if no certs.
    /// Used by list/detail views to surface "expiring soon" cues.
    public var nextCertificationExpiry: Date? {
        let dates: [Date?] = [
            firstAidExpiry, safeguardingExpiry,
            wtCoachLicenceExpiry, antiDopingExpiry,
            poomsaeRefereeExpiry, kyorugiRefereeExpiry
        ]
        return dates.compactMap { $0 }.min()
    }
}

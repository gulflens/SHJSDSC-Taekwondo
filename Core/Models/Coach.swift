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

    // === Identity (Stage 1.6) ===
    public var dateOfBirth: Date?
    public var gender: Gender?
    public var nationality: String
    public var mobileNumber: String?
    public var email: String?
    public var emiratesID: String?
    public var passportNumber: String?
    public var bloodType: BloodType?
    /// UAE Taekwondo Federation coach ID.
    public var federationCoachID: String?
    /// World Taekwondo coach licence ID (distinct from `wtCoachLicenceLevel`).
    public var worldTaekwondoCoachID: String?

    // === Coaching role + status (Stage 1.6) ===
    public var coachLevel: CoachLevel?
    public var licenseLevel: CoachLicenseLevel?
    public var specialisation: CoachSpecialisation?
    public var employmentStatus: CoachEmploymentStatus
    public var nationalTeamStatus: CoachProgramStatus
    public var olympicProgramStatus: CoachProgramStatus

    // === Discipline-specific competency (Stage 1.6) ===
    /// 1...5 self-or-HQ-rated competency in each pillar. nil = not rated.
    public var technicalLevel: Int?
    public var sparringLevel: Int?
    public var poomsaeLevel: Int?
    public var fitnessLevel: Int?

    // === Profile dossier (Stage 1.6) ===
    /// Coach-on-coach notes (peer reviews, HQ feedback, mentorship log).
    /// Reuses the same `CoachNote` type as Athlete — semantics differ by
    /// context, not by shape.
    public var coachNotes: [CoachNote]
    /// Latest ranking snapshot across club / UAE / WT.
    public var ranking: CoachRanking?

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
        peerReviewAvg: Double? = nil,
        dateOfBirth: Date? = nil,
        gender: Gender? = nil,
        nationality: String = "AE",
        mobileNumber: String? = nil,
        email: String? = nil,
        emiratesID: String? = nil,
        passportNumber: String? = nil,
        bloodType: BloodType? = nil,
        federationCoachID: String? = nil,
        worldTaekwondoCoachID: String? = nil,
        coachLevel: CoachLevel? = nil,
        licenseLevel: CoachLicenseLevel? = nil,
        specialisation: CoachSpecialisation? = nil,
        employmentStatus: CoachEmploymentStatus = .active,
        nationalTeamStatus: CoachProgramStatus = .none,
        olympicProgramStatus: CoachProgramStatus = .none,
        technicalLevel: Int? = nil,
        sparringLevel: Int? = nil,
        poomsaeLevel: Int? = nil,
        fitnessLevel: Int? = nil,
        coachNotes: [CoachNote] = [],
        ranking: CoachRanking? = nil
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
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.nationality = nationality
        self.mobileNumber = mobileNumber
        self.email = email
        self.emiratesID = emiratesID
        self.passportNumber = passportNumber
        self.bloodType = bloodType
        self.federationCoachID = federationCoachID
        self.worldTaekwondoCoachID = worldTaekwondoCoachID
        self.coachLevel = coachLevel
        self.licenseLevel = licenseLevel
        self.specialisation = specialisation
        self.employmentStatus = employmentStatus
        self.nationalTeamStatus = nationalTeamStatus
        self.olympicProgramStatus = olympicProgramStatus
        self.technicalLevel = technicalLevel.map { max(1, min(5, $0)) }
        self.sparringLevel = sparringLevel.map { max(1, min(5, $0)) }
        self.poomsaeLevel = poomsaeLevel.map { max(1, min(5, $0)) }
        self.fitnessLevel = fitnessLevel.map { max(1, min(5, $0)) }
        self.coachNotes = coachNotes
        self.ranking = ranking
    }

    /// Whole years from `hiredAt` to today — used for the "Years of experience"
    /// chip in the new profile header.
    public var yearsOfExperience: Int {
        Calendar.current.dateComponents([.year], from: hiredAt, to: Date()).year ?? 0
    }

    public var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
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

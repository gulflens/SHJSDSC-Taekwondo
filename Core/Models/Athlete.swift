import Foundation

public enum Gender: String, Codable, CaseIterable, Sendable, Hashable {
    case male, female
}

public enum AgeGroup: String, Codable, CaseIterable, Sendable, Hashable {
    case cubs, kids, cadets, juniors, seniors, masters

    public var labelKey: String { "age.\(rawValue)" }

    public static func from(age: Int) -> AgeGroup {
        switch age {
        case ..<10: .cubs
        case 10...11: .kids
        case 12...14: .cadets
        case 15...17: .juniors
        case 18...39: .seniors
        default: .masters
        }
    }
}

public enum AthleteStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case competitionTeam, readyToGrade, watch, rest, active

    public var labelKey: String { "status.\(rawValue)" }
}

public struct Athlete: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var memberNumber: Int
    public var fullName: String
    public var fullNameAr: String
    public var dateOfBirth: Date
    public var gender: Gender
    public var nationality: String
    public var emiratesID: String?
    public var branchID: EntityID
    public var primaryCoachID: EntityID?
    public var joinedAt: Date
    public var currentBelt: Belt
    public var beltHistory: [Belt]
    public var weightKg: Double
    public var status: AthleteStatus
    public var avatarSeed: String
    public var avatarURL: String?

    // === Identity ===
    public var passportNumber: String?
    public var bloodType: BloodType?
    public var federationLicenceNumber: String?
    /// World Taekwondo Federation athlete ID (GAL system). Distinct from the
    /// UAE federation licence number above.
    public var worldTaekwondoID: String?

    // === Family / consent ===
    public var parentUserIDs: [EntityID]
    public var emergencyContacts: [EmergencyContact]
    public var school: String?
    public var imageRightsConsent: Bool
    public var imageRightsConsentDate: Date?
    public var travelPermission: Bool
    public var travelPermissionDate: Date?

    // === Medical ===
    public var heightCm: Double?
    public var weightHistory: [WeightEntry]
    public var allergies: [String]
    public var medicalConditions: [String]
    public var medications: [String]
    public var fitToTrain: Bool
    public var injuries: [InjuryEntry]

    // === Technical ===
    public var weightClass: WeightCategory?
    public var dominantLeg: DominantLeg?
    public var dominantStance: Stance?
    public var specialty: Specialty?
    public var yearsTraining: Int?
    public var poomsaeSyllabus: String?
    public var kyorugiTier: KyorugiTier?
    public var trainingGroupID: EntityID?

    /// Repertoire — forms the athlete can perform. Mastery scores live on
    /// `PoomsaeAssessment`; this set tracks which forms are in the repertoire
    /// independent of how well they're performed.
    public var poomsaeKnown: Set<PoomsaeForm>

    // === Grading (Pillar 9) ===
    /// 1...5 — coach's subjective readiness rating for the next grading.
    public var gradingReadiness: Int?
    /// Planned date for the athlete's next belt-test.
    public var nextGradingTargetDate: Date?

    // === Profile dossier (Pillar 10) ===
    /// Threaded coach notes. Newest first by convention; the view layer sorts
    /// defensively anyway. Empty in the standard demo seed; populated for the
    /// "showcase" athletes in `SeedData.build()`.
    public var coachNotes: [CoachNote]
    /// Identity / consent / medical documents. Status is computed from the
    /// expiry date at render-time via `derivedStatus(asOf:)`.
    public var documents: [AthleteDocument]
    /// Latest ranking snapshot across club / UAE / WT / Olympic systems.
    /// Nil for non-competitive athletes — the Overview tab hides the
    /// Current Rankings card when this is nil.
    public var ranking: AthleteRanking?

    public init(
        id: EntityID = UUID(),
        memberNumber: Int,
        fullName: String,
        fullNameAr: String,
        dateOfBirth: Date,
        gender: Gender = .male,
        nationality: String = "AE",
        emiratesID: String? = nil,
        branchID: EntityID,
        primaryCoachID: EntityID? = nil,
        joinedAt: Date,
        currentBelt: Belt,
        beltHistory: [Belt] = [],
        weightKg: Double,
        status: AthleteStatus,
        avatarSeed: String,
        avatarURL: String? = nil,
        passportNumber: String? = nil,
        bloodType: BloodType? = nil,
        federationLicenceNumber: String? = nil,
        worldTaekwondoID: String? = nil,
        parentUserIDs: [EntityID] = [],
        emergencyContacts: [EmergencyContact] = [],
        school: String? = nil,
        imageRightsConsent: Bool = false,
        imageRightsConsentDate: Date? = nil,
        travelPermission: Bool = false,
        travelPermissionDate: Date? = nil,
        heightCm: Double? = nil,
        weightHistory: [WeightEntry] = [],
        allergies: [String] = [],
        medicalConditions: [String] = [],
        medications: [String] = [],
        fitToTrain: Bool = true,
        injuries: [InjuryEntry] = [],
        weightClass: WeightCategory? = nil,
        dominantLeg: DominantLeg? = nil,
        dominantStance: Stance? = nil,
        specialty: Specialty? = nil,
        yearsTraining: Int? = nil,
        poomsaeSyllabus: String? = nil,
        kyorugiTier: KyorugiTier? = nil,
        trainingGroupID: EntityID? = nil,
        poomsaeKnown: Set<PoomsaeForm> = [],
        gradingReadiness: Int? = nil,
        nextGradingTargetDate: Date? = nil,
        coachNotes: [CoachNote] = [],
        documents: [AthleteDocument] = [],
        ranking: AthleteRanking? = nil
    ) {
        self.id = id
        self.memberNumber = memberNumber
        self.fullName = fullName
        self.fullNameAr = fullNameAr
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.nationality = nationality
        self.emiratesID = emiratesID
        self.branchID = branchID
        self.primaryCoachID = primaryCoachID
        self.joinedAt = joinedAt
        self.currentBelt = currentBelt
        self.beltHistory = beltHistory
        self.weightKg = weightKg
        self.status = status
        self.avatarSeed = avatarSeed
        self.avatarURL = avatarURL
        self.passportNumber = passportNumber
        self.bloodType = bloodType
        self.federationLicenceNumber = federationLicenceNumber
        self.worldTaekwondoID = worldTaekwondoID
        self.parentUserIDs = parentUserIDs
        self.emergencyContacts = emergencyContacts
        self.school = school
        self.imageRightsConsent = imageRightsConsent
        self.imageRightsConsentDate = imageRightsConsentDate
        self.travelPermission = travelPermission
        self.travelPermissionDate = travelPermissionDate
        self.heightCm = heightCm
        self.weightHistory = weightHistory
        self.allergies = allergies
        self.medicalConditions = medicalConditions
        self.medications = medications
        self.fitToTrain = fitToTrain
        self.injuries = injuries
        self.weightClass = weightClass
        self.dominantLeg = dominantLeg
        self.dominantStance = dominantStance
        self.specialty = specialty
        self.yearsTraining = yearsTraining
        self.poomsaeSyllabus = poomsaeSyllabus
        self.kyorugiTier = kyorugiTier
        self.trainingGroupID = trainingGroupID
        self.poomsaeKnown = poomsaeKnown
        self.gradingReadiness = gradingReadiness.map { max(1, min(5, $0)) }
        self.nextGradingTargetDate = nextGradingTargetDate
        self.coachNotes = coachNotes
        self.documents = documents
        self.ranking = ranking
    }

    /// Whole months between when the current belt was awarded and now.
    public var monthsAtCurrentRank: Int {
        Calendar.current.dateComponents([.month], from: currentBelt.awardedAt, to: Date()).month ?? 0
    }

    public var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }

    public var ageGroup: AgeGroup { AgeGroup.from(age: age) }

    public var initials: String {
        let parts = fullName.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }

    /// Returns localization keys for fields that are recommended but missing.
    /// Empty result = profile is "complete enough". Used by the AthleteDetail
    /// warning banner to nudge the user without blocking creation.
    public var missingProfileFields: [String] {
        var missing: [String] = []
        if (emiratesID ?? "").isEmpty && (passportNumber ?? "").isEmpty {
            missing.append("athlete.missing.id_document")
        }
        if bloodType == nil { missing.append("athlete.missing.blood_type") }
        if (federationLicenceNumber ?? "").isEmpty { missing.append("athlete.missing.federation_licence") }
        if (avatarURL ?? "").isEmpty { missing.append("athlete.missing.photo") }
        if emergencyContacts.isEmpty { missing.append("athlete.missing.emergency_contact") }
        if (school ?? "").isEmpty { missing.append("athlete.missing.school") }
        if heightCm == nil { missing.append("athlete.missing.height") }
        if !imageRightsConsent { missing.append("athlete.missing.image_rights") }
        if !travelPermission { missing.append("athlete.missing.travel_permission") }
        return missing
    }

    /// 0...1, equally weighted across the recommended fields.
    public var profileCompleteness: Double {
        let totalChecked = 9.0
        let missingCount = Double(missingProfileFields.count)
        return max(0, min(1, (totalChecked - missingCount) / totalChecked))
    }
}

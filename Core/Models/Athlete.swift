import Foundation

public enum Gender: String, Codable, CaseIterable, Sendable, Hashable {
    case male, female
}

public enum AgeGroup: String, Codable, CaseIterable, Sendable, Hashable {
    case cubs, kids, cadets, juniors, seniors

    public var labelKey: String { "age.\(rawValue)" }

    public static func from(age: Int) -> AgeGroup {
        switch age {
        case ..<10: .cubs
        case 10...11: .kids
        case 12...14: .cadets
        case 15...17: .juniors
        default: .seniors
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
    public var dominantStance: Stance?
    public var poomsaeSyllabus: String?
    public var kyorugiTier: KyorugiTier?
    public var trainingGroupID: EntityID?

    public init(
        id: EntityID = UUID(),
        memberNumber: Int,
        fullName: String,
        fullNameAr: String,
        dateOfBirth: Date,
        gender: Gender,
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
        dominantStance: Stance? = nil,
        poomsaeSyllabus: String? = nil,
        kyorugiTier: KyorugiTier? = nil,
        trainingGroupID: EntityID? = nil
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
        self.dominantStance = dominantStance
        self.poomsaeSyllabus = poomsaeSyllabus
        self.kyorugiTier = kyorugiTier
        self.trainingGroupID = trainingGroupID
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

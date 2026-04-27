import Foundation

public struct BranchProgram: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var branchID: EntityID
    public var nameKey: String?
    public var customName: String?
    public var customNameAr: String?
    public var descriptionEn: String
    public var descriptionAr: String
    public var ageGroup: AgeGroup
    public var disciplines: [ClassDiscipline]
    public var schedulePattern: [DayOfWeek]
    public var startTime: String
    public var endTime: String
    public var capacity: Int
    public var currentEnrolment: Int
    public var monthlyFeeAED: Double
    public var trialClassFeeAED: Double?
    public var registrationFeeAED: Double?
    public var equipmentPackageFeeAED: Double?
    public var siblingDiscountPct: Double?
    public var annualPrepayDiscountPct: Double?
    public var isActive: Bool
    public var isWomenOnly: Bool

    public init(
        id: EntityID = UUID(),
        branchID: EntityID,
        nameKey: String? = nil,
        customName: String? = nil,
        customNameAr: String? = nil,
        descriptionEn: String,
        descriptionAr: String,
        ageGroup: AgeGroup,
        disciplines: [ClassDiscipline],
        schedulePattern: [DayOfWeek],
        startTime: String,
        endTime: String,
        capacity: Int,
        currentEnrolment: Int = 0,
        monthlyFeeAED: Double,
        trialClassFeeAED: Double? = nil,
        registrationFeeAED: Double? = nil,
        equipmentPackageFeeAED: Double? = nil,
        siblingDiscountPct: Double? = nil,
        annualPrepayDiscountPct: Double? = nil,
        isActive: Bool = true,
        isWomenOnly: Bool = false
    ) {
        self.id = id
        self.branchID = branchID
        self.nameKey = nameKey
        self.customName = customName
        self.customNameAr = customNameAr
        self.descriptionEn = descriptionEn
        self.descriptionAr = descriptionAr
        self.ageGroup = ageGroup
        self.disciplines = disciplines
        self.schedulePattern = schedulePattern
        self.startTime = startTime
        self.endTime = endTime
        self.capacity = capacity
        self.currentEnrolment = currentEnrolment
        self.monthlyFeeAED = monthlyFeeAED
        self.trialClassFeeAED = trialClassFeeAED
        self.registrationFeeAED = registrationFeeAED
        self.equipmentPackageFeeAED = equipmentPackageFeeAED
        self.siblingDiscountPct = siblingDiscountPct
        self.annualPrepayDiscountPct = annualPrepayDiscountPct
        self.isActive = isActive
        self.isWomenOnly = isWomenOnly
    }
}

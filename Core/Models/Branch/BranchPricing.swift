import Foundation

public struct Promotion: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var titleEn: String
    public var titleAr: String
    public var descriptionEn: String
    public var descriptionAr: String
    public var discountPct: Double?
    public var discountAED: Double?
    public var validFrom: Date
    public var validUntil: Date
    public var promoCode: String?

    public init(
        id: EntityID = UUID(),
        titleEn: String,
        titleAr: String,
        descriptionEn: String,
        descriptionAr: String,
        discountPct: Double? = nil,
        discountAED: Double? = nil,
        validFrom: Date,
        validUntil: Date,
        promoCode: String? = nil
    ) {
        self.id = id
        self.titleEn = titleEn
        self.titleAr = titleAr
        self.descriptionEn = descriptionEn
        self.descriptionAr = descriptionAr
        self.discountPct = discountPct
        self.discountAED = discountAED
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.promoCode = promoCode
    }
}

public struct BranchPricing: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var branchID: EntityID
    public var baseMonthlyFeeAED: Double
    public var trialClassFeeAED: Double
    public var registrationFeeAED: Double
    public var equipmentPackageFeeAED: Double
    public var siblingDiscountPct: Double
    public var annualPrepayDiscountPct: Double
    public var promotions: [Promotion]
    public var effectiveFrom: Date

    public init(
        id: EntityID = UUID(),
        branchID: EntityID,
        baseMonthlyFeeAED: Double,
        trialClassFeeAED: Double,
        registrationFeeAED: Double,
        equipmentPackageFeeAED: Double,
        siblingDiscountPct: Double = 0,
        annualPrepayDiscountPct: Double = 0,
        promotions: [Promotion] = [],
        effectiveFrom: Date = Date()
    ) {
        self.id = id
        self.branchID = branchID
        self.baseMonthlyFeeAED = baseMonthlyFeeAED
        self.trialClassFeeAED = trialClassFeeAED
        self.registrationFeeAED = registrationFeeAED
        self.equipmentPackageFeeAED = equipmentPackageFeeAED
        self.siblingDiscountPct = siblingDiscountPct
        self.annualPrepayDiscountPct = annualPrepayDiscountPct
        self.promotions = promotions
        self.effectiveFrom = effectiveFrom
    }
}

import Foundation

public struct BranchFinancials: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var branchID: EntityID
    public var month: Date    // first day of the calendar month
    public var revenueAED: Double
    public var rentAED: Double
    public var utilitiesAED: Double
    public var staffCostAED: Double
    public var equipmentAED: Double
    public var marketingAED: Double
    public var otherExpensesAED: Double
    public var outstandingFeesAED: Double
    public var activePaymentPlans: Int

    public init(
        id: EntityID = UUID(),
        branchID: EntityID,
        month: Date,
        revenueAED: Double,
        rentAED: Double,
        utilitiesAED: Double,
        staffCostAED: Double,
        equipmentAED: Double,
        marketingAED: Double,
        otherExpensesAED: Double,
        outstandingFeesAED: Double = 0,
        activePaymentPlans: Int = 0
    ) {
        self.id = id
        self.branchID = branchID
        self.month = month
        self.revenueAED = revenueAED
        self.rentAED = rentAED
        self.utilitiesAED = utilitiesAED
        self.staffCostAED = staffCostAED
        self.equipmentAED = equipmentAED
        self.marketingAED = marketingAED
        self.otherExpensesAED = otherExpensesAED
        self.outstandingFeesAED = outstandingFeesAED
        self.activePaymentPlans = activePaymentPlans
    }

    public var totalExpensesAED: Double {
        rentAED + utilitiesAED + staffCostAED + equipmentAED
        + marketingAED + otherExpensesAED
    }
    public var netContributionAED: Double { revenueAED - totalExpensesAED }
}

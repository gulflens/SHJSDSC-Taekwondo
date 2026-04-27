import Foundation

public enum ItemCategory: String, Codable, Sendable, CaseIterable, Hashable {
    case hogu, helmet, shinGuard, forearmGuard, mouthGuard, groinGuard
    case kickingPad, targetPad, breakingBoard, doboK, beltStock
    case mat, scoreboard, medkit, aed, other

    public var labelKey: String { "inventory.\(self)" }
}

public struct InventoryItem: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var category: ItemCategory
    public var labelKey: String
    public var size: String?
    public var quantity: Int
    public var conditionGood: Int
    public var conditionFair: Int
    public var conditionPoor: Int
    public var notes: String?

    public init(
        id: EntityID = UUID(),
        category: ItemCategory,
        labelKey: String,
        size: String? = nil,
        quantity: Int,
        conditionGood: Int = 0,
        conditionFair: Int = 0,
        conditionPoor: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.category = category
        self.labelKey = labelKey
        self.size = size
        self.quantity = quantity
        self.conditionGood = conditionGood
        self.conditionFair = conditionFair
        self.conditionPoor = conditionPoor
        self.notes = notes
    }
}

public struct BranchInventory: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var branchID: EntityID
    public var items: [InventoryItem]
    public var lastAuditAt: Date
    public var lastAuditByUserID: EntityID

    public init(
        id: EntityID = UUID(),
        branchID: EntityID,
        items: [InventoryItem] = [],
        lastAuditAt: Date,
        lastAuditByUserID: EntityID
    ) {
        self.id = id
        self.branchID = branchID
        self.items = items
        self.lastAuditAt = lastAuditAt
        self.lastAuditByUserID = lastAuditByUserID
    }
}

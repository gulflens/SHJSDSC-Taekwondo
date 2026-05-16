import Foundation

// MARK: - Drill dossier

/// One piece of equipment a drill needs, with an optional quantity note
/// ("2+", "1 per athlete"). Surfaced as a chip in the drill preview panel.
/// Pure data — no framework imports — so it ports straight to Kotlin.
public struct DrillEquipmentItem: Codable, Hashable, Sendable, Identifiable {
    public let id: EntityID
    public var name: String
    public var nameAr: String?
    public var quantityNote: String?
    public var systemIcon: String

    public init(
        id: EntityID = UUID(),
        name: String,
        nameAr: String? = nil,
        quantityNote: String? = nil,
        systemIcon: String = "shippingbox.fill"
    ) {
        self.id = id
        self.name = name
        self.nameAr = nameAr
        self.quantityNote = quantityNote
        self.systemIcon = systemIcon
    }
}

/// Operational numbers a coach reads at a glance — rendered as the pastel
/// metric cards in the drill detail panel. Every field is optional; only the
/// populated ones get a card.
public struct DrillMetrics: Codable, Hashable, Sendable {
    public var sets: Int?
    public var distance: String?
    public var rest: String?
    public var totalTime: String?
    public var spaceRequired: String?
    public var athleteLevelNote: String?

    public init(
        sets: Int? = nil,
        distance: String? = nil,
        rest: String? = nil,
        totalTime: String? = nil,
        spaceRequired: String? = nil,
        athleteLevelNote: String? = nil
    ) {
        self.sets = sets
        self.distance = distance
        self.rest = rest
        self.totalTime = totalTime
        self.spaceRequired = spaceRequired
        self.athleteLevelNote = athleteLevelNote
    }

    /// True when no metric is populated — lets the detail panel hide the
    /// whole section rather than show an empty grid.
    public var isEmpty: Bool {
        sets == nil && distance == nil && rest == nil
            && totalTime == nil && spaceRequired == nil && athleteLevelNote == nil
    }
}

/// A named progression or variation on the base drill (e.g. "Add resistance
/// band", "Partner-fed tempo"). Shown in the Variations tab.
public struct DrillVariation: Codable, Hashable, Sendable, Identifiable {
    public let id: EntityID
    public var title: String
    public var titleAr: String?
    public var detail: String

    public init(
        id: EntityID = UUID(),
        title: String,
        titleAr: String? = nil,
        detail: String
    ) {
        self.id = id
        self.title = title
        self.titleAr = titleAr
        self.detail = detail
    }
}

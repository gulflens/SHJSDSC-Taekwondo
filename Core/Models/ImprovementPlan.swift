import Foundation

// MARK: - Drill library

public enum DrillCategory: String, Codable, CaseIterable, Sendable, Hashable {
    case technique, sparring, flexibility, conditioning, poomsae, footwork, strength

    public var labelKey: String { "drill_category.\(rawValue)" }

    public var systemIcon: String {
        switch self {
        case .technique: "figure.kickboxing"
        case .sparring: "figure.boxing"
        case .flexibility: "figure.flexibility"
        case .conditioning: "figure.run"
        case .poomsae: "figure.taichi"
        case .footwork: "shoe.fill"
        case .strength: "dumbbell.fill"
        }
    }
}

public enum DrillDifficulty: String, Codable, CaseIterable, Sendable, Hashable {
    case beginner, intermediate, advanced

    public var labelKey: String { "drill_difficulty.\(rawValue)" }
}

public struct DrillLibraryEntry: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var name: String
    public var nameAr: String?
    public var category: DrillCategory
    public var summary: String
    public var videoURL: String?
    public var durationMinutes: Int?

    /// Tags this drill addresses — should match a metric/technique/poomsae
    /// raw value from Pillars 1–4 (e.g. `frontSplitCm`, `spinningHookKick`,
    /// `taegeuk4`) so the auto-flag pipeline can suggest drills for flagged
    /// weaknesses by exact-match.
    public var addressesWeaknessTags: [String]
    public var minBelt: BeltRank?
    public var maxBelt: BeltRank?
    public var equipmentRequired: [String]
    public var difficulty: DrillDifficulty?

    // MARK: Stage 1.8 — drill dossier
    /// Free-text descriptive tags shown as `#chips` on the drill row
    /// (e.g. "Conditioning", "Cardio"). Distinct from `addressesWeaknessTags`,
    /// which are exact enum raw values consumed by the auto-flag pipeline.
    public var tags: [String]
    /// Coach-facing effort rating, 1...5 — rendered as filled dots.
    public var intensity: Int?
    /// Ordered "How to perform" steps shown as numbered circles.
    public var instructions: [String]
    /// A single highlighted coaching cue shown in the tip card.
    public var coachingTip: String?
    /// Equipment with quantity notes — richer than `equipmentRequired`.
    public var equipment: [DrillEquipmentItem]
    /// Primary muscle groups worked — shown as pastel chips.
    public var muscleFocus: [String]
    /// Operational numbers for the metric-card grid.
    public var metrics: DrillMetrics?
    /// Named progressions on the base drill.
    public var variations: [DrillVariation]
    /// Free-form coaching notes shown in the Notes tab.
    public var notes: String?
    /// Other drills a coach commonly pairs with this one.
    public var relatedDrillIDs: [EntityID]
    /// Asset-catalog image name for the thumbnail / preview. `nil` falls back
    /// to a category gradient placeholder.
    public var imageAssetName: String?
    /// Length of the preview clip, used for the "0:45" overlay badge.
    public var videoDurationSeconds: Int?

    public init(
        id: EntityID = UUID(),
        name: String,
        nameAr: String? = nil,
        category: DrillCategory,
        summary: String,
        videoURL: String? = nil,
        durationMinutes: Int? = nil,
        addressesWeaknessTags: [String] = [],
        minBelt: BeltRank? = nil,
        maxBelt: BeltRank? = nil,
        equipmentRequired: [String] = [],
        difficulty: DrillDifficulty? = nil,
        tags: [String] = [],
        intensity: Int? = nil,
        instructions: [String] = [],
        coachingTip: String? = nil,
        equipment: [DrillEquipmentItem] = [],
        muscleFocus: [String] = [],
        metrics: DrillMetrics? = nil,
        variations: [DrillVariation] = [],
        notes: String? = nil,
        relatedDrillIDs: [EntityID] = [],
        imageAssetName: String? = nil,
        videoDurationSeconds: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.nameAr = nameAr
        self.category = category
        self.summary = summary
        self.videoURL = videoURL
        self.durationMinutes = durationMinutes
        self.addressesWeaknessTags = addressesWeaknessTags
        self.minBelt = minBelt
        self.maxBelt = maxBelt
        self.equipmentRequired = equipmentRequired
        self.difficulty = difficulty
        self.tags = tags
        self.intensity = intensity
        self.instructions = instructions
        self.coachingTip = coachingTip
        self.equipment = equipment
        self.muscleFocus = muscleFocus
        self.metrics = metrics
        self.variations = variations
        self.notes = notes
        self.relatedDrillIDs = relatedDrillIDs
        self.imageAssetName = imageAssetName
        self.videoDurationSeconds = videoDurationSeconds
    }

    /// Decoder fallback so pre-Pillar-11 rows (no new columns) still parse.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(EntityID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.nameAr = try c.decodeIfPresent(String.self, forKey: .nameAr)
        self.category = try c.decode(DrillCategory.self, forKey: .category)
        self.summary = try c.decodeIfPresent(String.self, forKey: .summary) ?? ""
        self.videoURL = try c.decodeIfPresent(String.self, forKey: .videoURL)
        self.durationMinutes = try c.decodeIfPresent(Int.self, forKey: .durationMinutes)
        self.addressesWeaknessTags = try c.decodeIfPresent([String].self, forKey: .addressesWeaknessTags) ?? []
        self.minBelt = try c.decodeIfPresent(BeltRank.self, forKey: .minBelt)
        self.maxBelt = try c.decodeIfPresent(BeltRank.self, forKey: .maxBelt)
        self.equipmentRequired = try c.decodeIfPresent([String].self, forKey: .equipmentRequired) ?? []
        self.difficulty = try c.decodeIfPresent(DrillDifficulty.self, forKey: .difficulty)
        // Stage 1.8 dossier columns — all optional so pre-1.8 rows still parse.
        self.tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.intensity = try c.decodeIfPresent(Int.self, forKey: .intensity)
        self.instructions = try c.decodeIfPresent([String].self, forKey: .instructions) ?? []
        self.coachingTip = try c.decodeIfPresent(String.self, forKey: .coachingTip)
        self.equipment = try c.decodeIfPresent([DrillEquipmentItem].self, forKey: .equipment) ?? []
        self.muscleFocus = try c.decodeIfPresent([String].self, forKey: .muscleFocus) ?? []
        self.metrics = try c.decodeIfPresent(DrillMetrics.self, forKey: .metrics)
        self.variations = try c.decodeIfPresent([DrillVariation].self, forKey: .variations) ?? []
        self.notes = try c.decodeIfPresent(String.self, forKey: .notes)
        self.relatedDrillIDs = try c.decodeIfPresent([EntityID].self, forKey: .relatedDrillIDs) ?? []
        self.imageAssetName = try c.decodeIfPresent(String.self, forKey: .imageAssetName)
        self.videoDurationSeconds = try c.decodeIfPresent(Int.self, forKey: .videoDurationSeconds)
    }

    /// True when `belt` falls within (minBelt, maxBelt) — either bound nil
    /// means the drill is unbounded on that side.
    public func isAvailable(at belt: Belt) -> Bool {
        let r = belt.rank
        if let min = minBelt, r < min { return false }
        if let max = maxBelt, r > max { return false }
        return true
    }
}

// MARK: - Weakness (value type, not persisted as a row — embedded in plans)

public enum WeaknessSeverity: String, Codable, CaseIterable, Sendable, Hashable {
    case low, medium, high
    public var labelKey: String { "weakness_severity.\(rawValue)" }
}

public enum WeaknessSource: String, Codable, Sendable, Hashable {
    case peer, manual
    public var labelKey: String { "weakness_source.\(rawValue)" }
}

public struct Weakness: Codable, Hashable, Sendable, Identifiable {
    public var id: String { "\(source.rawValue).\(kind)" }
    /// Stable identifier for the underlying signal (e.g. PhysicalMetricKind raw
    /// value, TechniqueKind raw value, or a free-form key for manual entries).
    public var kind: String
    /// Human-readable label key OR free-form text. Display layer chooses.
    public var label: String
    public var severity: WeaknessSeverity
    public var source: WeaknessSource

    public init(kind: String, label: String, severity: WeaknessSeverity, source: WeaknessSource) {
        self.kind = kind
        self.label = label
        self.severity = severity
        self.source = source
    }
}

// MARK: - Plan

public enum PlanStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case active, completed, archived
    public var labelKey: String { "plan_status.\(rawValue)" }
}

public struct ImprovementPlan: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var athleteID: EntityID
    public var createdAt: Date
    public var createdByCoachID: EntityID?
    public var weaknesses: [Weakness]
    public var recommendedDrillIDs: [EntityID]
    public var notes: String
    public var targetDate: Date?
    public var reviewDate: Date?
    public var status: PlanStatus

    public init(
        id: EntityID = UUID(),
        athleteID: EntityID,
        createdAt: Date = Date(),
        createdByCoachID: EntityID? = nil,
        weaknesses: [Weakness] = [],
        recommendedDrillIDs: [EntityID] = [],
        notes: String = "",
        targetDate: Date? = nil,
        reviewDate: Date? = nil,
        status: PlanStatus = .active
    ) {
        self.id = id
        self.athleteID = athleteID
        self.createdAt = createdAt
        self.createdByCoachID = createdByCoachID
        self.weaknesses = weaknesses
        self.recommendedDrillIDs = recommendedDrillIDs
        self.notes = notes
        self.targetDate = targetDate
        self.reviewDate = reviewDate
        self.status = status
    }

    public var isReviewDue: Bool {
        guard status == .active, let review = reviewDate else { return false }
        return review < Date()
    }
}

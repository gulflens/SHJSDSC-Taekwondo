import Foundation

/// Materialised cohort statistics for a single metric. One row per
/// (cohort definition, metric) tuple. Any cohort dimension left nil means
/// "across all values for that dimension" — so a benchmark with only
/// `ageDivision` set is the cohort of all athletes in that age group
/// regardless of belt or weight.
public struct PeerBenchmark: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var beltRank: BeltRank?
    public var ageDivision: AgeGroup?
    public var weightClass: WeightCategory?
    /// Canonical metric identifier. Typically a `PhysicalMetricKind` raw value.
    public var metricKey: String
    public var mean: Double
    public var standardDeviation: Double
    public var sampleSize: Int
    public var computedAt: Date

    public init(
        id: EntityID = UUID(),
        beltRank: BeltRank? = nil,
        ageDivision: AgeGroup? = nil,
        weightClass: WeightCategory? = nil,
        metricKey: String,
        mean: Double,
        standardDeviation: Double,
        sampleSize: Int,
        computedAt: Date = Date()
    ) {
        self.id = id
        self.beltRank = beltRank
        self.ageDivision = ageDivision
        self.weightClass = weightClass
        self.metricKey = metricKey
        self.mean = mean
        self.standardDeviation = standardDeviation
        self.sampleSize = sampleSize
        self.computedAt = computedAt
    }

    /// True when this benchmark applies to the given athlete (each cohort
    /// dimension either matches or is unconstrained on the benchmark).
    public func appliesTo(_ athlete: Athlete) -> Bool {
        if let rank = beltRank, rank != athlete.currentBelt.rank { return false }
        if let age = ageDivision, age != athlete.ageGroup { return false }
        if let cat = weightClass, cat != athlete.weightClass { return false }
        return true
    }

    /// z-score = (value − mean) / σ. Returns nil when σ is zero.
    public func zScore(for value: Double) -> Double? {
        guard standardDeviation > 0 else { return nil }
        return (value - mean) / standardDeviation
    }
}

public extension Array where Element == PeerBenchmark {
    /// Best-fit benchmark for the athlete + metric — prefer the most
    /// specific cohort match (more dimensions set), fall back to
    /// progressively broader cohorts. Returns nil when no benchmark exists
    /// for the metric at all.
    func best(for athlete: Athlete, metricKey: String) -> PeerBenchmark? {
        self
            .filter { $0.metricKey == metricKey && $0.appliesTo(athlete) }
            .max(by: { lhs, rhs in lhs.specificity < rhs.specificity })
    }
}

private extension PeerBenchmark {
    /// Number of cohort dimensions explicitly set. Used to pick the most
    /// specific applicable benchmark.
    var specificity: Int {
        var n = 0
        if beltRank != nil { n += 1 }
        if ageDivision != nil { n += 1 }
        if weightClass != nil { n += 1 }
        return n
    }
}

import Foundation

// MARK: - Branch analytics
//
// Stage 1.11 — Branch Performance Overview. Pure functions that turn the raw
// repository data (branches + performance scores + roster counts) into the
// executive analytics the dashboard renders. No framework imports — this is
// `Core/Services`, sibling to `ScoreEngine`.
//
// Composite, grade and the six metric scores are real averages of seeded
// `PerformanceScore` data. Growth %, the 12-week attendance trend and the
// coaching radar are demo-derived: deterministic functions of the branch's
// real scores + a stable per-branch seed, so the dashboard is populated and
// reproducible without a separate analytics table.

/// The six headline performance dimensions shown as metric rings.
public enum BranchMetricKind: String, CaseIterable, Sendable, Hashable {
    case competition, technique, fitness, attendance, progress, wellness

    public var labelKey: String { "branch.metric.\(rawValue)" }
}

/// The six coaching-effectiveness radar axes.
public enum BranchRadarAxis: String, CaseIterable, Sendable, Hashable {
    case athleteImprovement, technicalQuality, attendanceImpact
    case retentionRate, promotionSuccess, sessionQuality

    public var labelKey: String { "branch.radar.\(rawValue)" }
}

/// Direction-of-travel chip.
public enum BranchTrend: String, Sendable, Hashable {
    case improving, stable, declining

    public var labelKey: String { "branch.trend.\(rawValue)" }
}

public struct BranchMetricScore: Identifiable, Sendable, Hashable {
    public let kind: BranchMetricKind
    public var score: Double          // 0–100
    public var id: String { kind.rawValue }

    public init(kind: BranchMetricKind, score: Double) {
        self.kind = kind
        self.score = score
    }
}

public struct BranchRadarScore: Identifiable, Sendable, Hashable {
    public let axis: BranchRadarAxis
    public var score: Double          // 0–100
    public var id: String { axis.rawValue }

    public init(axis: BranchRadarAxis, score: Double) {
        self.axis = axis
        self.score = score
    }
}

/// Everything a branch ranking card + the bottom charts need.
public struct BranchAnalytics: Identifiable, Sendable, Hashable {
    public let id: EntityID
    public var branch: Branch
    public var rank: Int
    public var nationalRank: Int
    public var athleteCount: Int
    public var coachCount: Int
    public var sessionsPerWeek: Int
    public var compositeScore: Double          // 0–100
    public var grade: LetterGrade
    public var metrics: [BranchMetricScore]    // six, in `BranchMetricKind.allCases` order
    public var radar: [BranchRadarScore]       // six, in `BranchRadarAxis.allCases` order
    public var growthPct: Double               // 30-day, may be negative
    public var trend: BranchTrend
    public var attendanceTrend: [Double]        // 12 weekly values, 0–100

    public init(
        id: EntityID, branch: Branch, rank: Int, nationalRank: Int,
        athleteCount: Int, coachCount: Int, sessionsPerWeek: Int,
        compositeScore: Double, grade: LetterGrade,
        metrics: [BranchMetricScore], radar: [BranchRadarScore],
        growthPct: Double, trend: BranchTrend, attendanceTrend: [Double]
    ) {
        self.id = id
        self.branch = branch
        self.rank = rank
        self.nationalRank = nationalRank
        self.athleteCount = athleteCount
        self.coachCount = coachCount
        self.sessionsPerWeek = sessionsPerWeek
        self.compositeScore = compositeScore
        self.grade = grade
        self.metrics = metrics
        self.radar = radar
        self.growthPct = growthPct
        self.trend = trend
        self.attendanceTrend = attendanceTrend
    }

    public func metric(_ kind: BranchMetricKind) -> Double {
        metrics.first { $0.kind == kind }?.score ?? 0
    }
}

/// A single executive insight. The view formats the localized sentence from
/// these structured fields.
public struct BranchInsight: Identifiable, Sendable, Hashable {
    public enum Kind: String, Sendable, Hashable {
        case improvedAttendance, topCompetition, needsAttention, overallGrowth
    }
    public let id: EntityID
    public var kind: Kind
    public var branchName: String
    public var value: Double

    public init(id: EntityID = UUID(), kind: Kind, branchName: String, value: Double) {
        self.id = id
        self.kind = kind
        self.branchName = branchName
        self.value = value
    }
}

// MARK: - Engine

public enum BranchAnalyticsEngine {

    /// Raw per-branch inputs gathered from the repository.
    public struct Input: Sendable {
        public var branch: Branch
        public var scores: [PerformanceScore]
        public var athleteCount: Int
        public var coachCount: Int
        public var sessionsPerWeek: Int

        public init(branch: Branch, scores: [PerformanceScore],
                    athleteCount: Int, coachCount: Int, sessionsPerWeek: Int) {
            self.branch = branch
            self.scores = scores
            self.athleteCount = athleteCount
            self.coachCount = coachCount
            self.sessionsPerWeek = sessionsPerWeek
        }
    }

    /// Builds the full analytics set, sorted best-composite first and ranked.
    public static func analyze(_ inputs: [Input]) -> [BranchAnalytics] {
        let unranked = inputs.map { build($0) }
        let sorted = unranked.sorted { $0.compositeScore > $1.compositeScore }
        return sorted.enumerated().map { idx, a in
            var ranked = a
            ranked.rank = idx + 1
            ranked.nationalRank = idx + 1
            return ranked
        }
    }

    private static func build(_ input: Input) -> BranchAnalytics {
        let scores = input.scores
        func avg(_ kp: KeyPath<PerformanceScore, Double>) -> Double {
            guard !scores.isEmpty else { return 0 }
            return scores.reduce(0.0) { $0 + $1[keyPath: kp] } / Double(scores.count)
        }
        let metricPairs: [(BranchMetricKind, Double)] = [
            (.competition, avg(\.competition)),
            (.technique,   avg(\.technical)),
            (.fitness,     avg(\.physical)),
            (.attendance,  avg(\.adherence)),
            (.progress,    avg(\.beltProgression)),
            (.wellness,    avg(\.wellness)),
        ]
        let metrics = metricPairs.map { BranchMetricScore(kind: $0.0, score: $0.1) }
        let composite = scores.isEmpty ? 0 : ScoreEngine.branchComposite(scores)

        // Deterministic 30-day growth: a stable per-branch seed nudged toward
        // the branch's standing — strong branches trend up, weak ones down.
        let s = seed(input.branch.name)
        let growth = (((composite - 70) / 5) + (s * 18 - 7)).rounded(toPlaces: 1)
        let trend: BranchTrend = growth > 3 ? .improving : (growth < -1 ? .declining : .stable)

        // 12-week attendance trend around the attendance metric.
        let base = metricPairs.first { $0.0 == .attendance }?.1 ?? 80
        let trendSeries = (0..<12).map { week -> Double in
            let progress = Double(week) / 11.0
            let drift = (growth / 100) * 14 * (progress - 0.5)
            let wobble = (seed("\(input.branch.name)-w\(week)") - 0.5) * 6
            return min(100, max(40, base + drift + wobble))
        }

        // Coaching radar — six axes derived from the metrics + a small seed.
        let radar = BranchRadarAxis.allCases.map { axis -> BranchRadarScore in
            BranchRadarScore(axis: axis, score: radarScore(axis, metrics: metricPairs,
                                                           composite: composite, branch: input.branch.name))
        }

        return BranchAnalytics(
            id: input.branch.id, branch: input.branch, rank: 0, nationalRank: 0,
            athleteCount: input.athleteCount, coachCount: input.coachCount,
            sessionsPerWeek: input.sessionsPerWeek,
            compositeScore: composite, grade: LetterGrade.from(score: composite),
            metrics: metrics, radar: radar,
            growthPct: growth, trend: trend, attendanceTrend: trendSeries
        )
    }

    private static func radarScore(_ axis: BranchRadarAxis,
                                   metrics: [(BranchMetricKind, Double)],
                                   composite: Double, branch: String) -> Double {
        func m(_ k: BranchMetricKind) -> Double { metrics.first { $0.0 == k }?.1 ?? composite }
        let basis: Double
        switch axis {
        case .athleteImprovement: basis = m(.progress)
        case .technicalQuality:   basis = m(.technique)
        case .attendanceImpact:   basis = m(.attendance)
        case .retentionRate:      basis = (m(.wellness) + m(.attendance)) / 2
        case .promotionSuccess:   basis = (m(.progress) + m(.competition)) / 2
        case .sessionQuality:     basis = (m(.technique) + m(.fitness)) / 2
        }
        let jitter = (seed("\(branch)-\(axis.rawValue)") - 0.5) * 10
        return min(100, max(35, basis + jitter))
    }

    /// Top executive insights derived from the ranked analytics.
    public static func insights(_ analytics: [BranchAnalytics], overallGrowth: Double) -> [BranchInsight] {
        guard !analytics.isEmpty else { return [] }
        var out: [BranchInsight] = []

        if let improver = analytics.filter({ $0.growthPct > 0 }).max(by: { $0.growthPct < $1.growthPct }) {
            out.append(BranchInsight(kind: .improvedAttendance,
                                     branchName: improver.branch.name,
                                     value: improver.growthPct))
        }
        if let topComp = analytics.max(by: { $0.metric(.competition) < $1.metric(.competition) }) {
            out.append(BranchInsight(kind: .topCompetition,
                                     branchName: topComp.branch.name,
                                     value: topComp.metric(.competition)))
        }
        if let weakest = analytics.min(by: { $0.compositeScore < $1.compositeScore }) {
            out.append(BranchInsight(kind: .needsAttention,
                                     branchName: weakest.branch.name,
                                     value: weakest.compositeScore))
        }
        out.append(BranchInsight(kind: .overallGrowth, branchName: "", value: overallGrowth))
        return out
    }
}

// MARK: - Helpers

private extension BranchAnalyticsEngine {
    /// Stable 0–1 value derived from a string — a tiny FNV-1a hash so demo
    /// analytics are reproducible across launches (unlike `hashValue`).
    static func seed(_ string: String) -> Double {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return Double(hash % 1000) / 1000.0
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}

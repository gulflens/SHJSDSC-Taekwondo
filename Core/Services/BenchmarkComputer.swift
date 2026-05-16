import Foundation

/// Compute peer benchmarks (mean + σ + n) across cohort slices. Pure
/// function — caller is responsible for fetching `athletes` and the matching
/// physical metrics. Output is a flat array of `PeerBenchmark` rows that the
/// caller upserts into the repository, replacing any existing rows for the
/// same (cohort, metric) tuples.
public enum BenchmarkComputer {

    /// Slices to compute by default. Each slice produces one benchmark per
    /// metric kind that has at least `minSampleSize` data points.
    public enum Slice {
        case ageDivision
        case beltRank
        case ageDivisionAndBelt
        case weightClass
    }

    public static let defaultSlices: [Slice] = [.ageDivision, .beltRank, .ageDivisionAndBelt]
    public static let defaultMinSampleSize = 5

    /// Compute benchmarks across the configured slices for every
    /// `PhysicalMetricKind` that has enough samples.
    ///
    /// - Parameters:
    ///   - athletes: cohort source — every athlete contributes their most
    ///     recent value per metric.
    ///   - metrics: all physical metrics for the athletes (any window —
    ///     latest-per-(athlete, kind) is selected internally).
    ///   - slices: cohort slices to materialise.
    ///   - minSampleSize: skip cohorts with fewer than this many athletes.
    public static func compute(
        athletes: [Athlete],
        metrics: [PhysicalMetric],
        slices: [Slice] = defaultSlices,
        minSampleSize: Int = defaultMinSampleSize,
        now: Date = Date()
    ) -> [PeerBenchmark] {
        // Latest value per (athleteID, kind) — pass-fail kinds excluded.
        let metricsByAthlete = Dictionary(grouping: metrics) { $0.athleteID }
        var latestByAthleteAndKind: [EntityID: [PhysicalMetricKind: Double]] = [:]
        for (athleteID, ms) in metricsByAthlete {
            var byKind: [PhysicalMetricKind: Double] = [:]
            for m in ms.latestPerKind() where !m.kind.isPassFail && m.leg == nil {
                byKind[m.kind] = m.value
            }
            latestByAthleteAndKind[athleteID] = byKind
        }

        var out: [PeerBenchmark] = []
        for slice in slices {
            for (cohortKey, group) in groupAthletes(athletes, slice: slice) {
                guard group.count >= minSampleSize else { continue }
                for kind in PhysicalMetricKind.allCases where !kind.isPassFail {
                    let values: [Double] = group.compactMap {
                        latestByAthleteAndKind[$0.id]?[kind]
                    }
                    guard values.count >= minSampleSize else { continue }
                    let stats = stats(of: values)
                    out.append(PeerBenchmark(
                        beltRank: cohortKey.beltRank,
                        ageDivision: cohortKey.ageDivision,
                        weightClass: cohortKey.weightClass,
                        metricKey: kind.rawValue,
                        mean: stats.mean,
                        standardDeviation: stats.stdDev,
                        sampleSize: values.count,
                        computedAt: now
                    ))
                }
            }
        }
        return out
    }

    // MARK: - Helpers

    private struct CohortKey: Hashable {
        var beltRank: BeltRank?
        var ageDivision: AgeGroup?
        var weightClass: WeightCategory?
    }

    private static func groupAthletes(_ athletes: [Athlete], slice: Slice) -> [CohortKey: [Athlete]] {
        var out: [CohortKey: [Athlete]] = [:]
        for a in athletes {
            let key: CohortKey = switch slice {
            case .ageDivision:
                CohortKey(ageDivision: a.ageGroup)
            case .beltRank:
                CohortKey(beltRank: a.currentBelt.rank)
            case .ageDivisionAndBelt:
                CohortKey(beltRank: a.currentBelt.rank, ageDivision: a.ageGroup)
            case .weightClass:
                CohortKey(weightClass: a.weightClass)
            }
            // Skip cohorts that need a category that's missing on the athlete.
            if slice == .weightClass && a.weightClass == nil { continue }
            out[key, default: []].append(a)
        }
        return out
    }

    private static func stats(of values: [Double]) -> (mean: Double, stdDev: Double) {
        guard !values.isEmpty else { return (0, 0) }
        let n = Double(values.count)
        let mean = values.reduce(0, +) / n
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / n
        return (mean, sqrt(variance))
    }
}

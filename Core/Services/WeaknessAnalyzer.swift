import Foundation

/// Auto-flag weaknesses by comparing one athlete's latest physical metrics
/// against a peer cohort. The cohort is supplied by the caller — typically
/// athletes in the same age group, optionally same gender — so the engine
/// itself stays a pure function with no repository dependencies.
public enum WeaknessAnalyzer {

    /// Returns up to `maxWeaknesses` flagged signals where the athlete's
    /// latest captured value sits at or below `cutoffPercentile` (default 25th)
    /// of the cohort distribution.
    ///
    /// Severity bands:
    ///   - high   when percentile ≤ 10
    ///   - medium when 10 < percentile ≤ 20
    ///   - low    otherwise
    public static func flag(
        athleteID: EntityID,
        athleteMetrics: [PhysicalMetric],
        cohortMetrics: [PhysicalMetric],
        cutoffPercentile: Double = 25,
        maxWeaknesses: Int = 3,
        labelFor: (PhysicalMetricKind) -> String
    ) -> [Weakness] {
        let athleteLatest = athleteMetrics.latestPerKind()
        let cohortLatest = Dictionary(grouping: cohortMetrics) { $0.athleteID }
            .mapValues { $0.latestPerKind() }

        // For each kind the athlete has captured, compute the cohort percentile.
        struct Scored { let kind: PhysicalMetricKind; let percentile: Double }
        var scored: [Scored] = []
        for entry in athleteLatest where !entry.kind.isPassFail {
            let kind = entry.kind
            // Peer values for the same kind (one per peer athlete).
            let peerValues: [Double] = cohortLatest.compactMap { (id, list) in
                guard id != athleteID else { return nil }
                return list.first(where: { $0.kind == kind })?.value
            }
            guard peerValues.count >= 3 else { continue }   // not enough data
            let pct = percentile(of: entry.value, in: peerValues, higherIsBetter: kind.higherIsBetter)
            if pct <= cutoffPercentile {
                scored.append(.init(kind: kind, percentile: pct))
            }
        }

        return scored
            .sorted { $0.percentile < $1.percentile }
            .prefix(maxWeaknesses)
            .map { s in
                Weakness(
                    kind: s.kind.rawValue,
                    label: labelFor(s.kind),
                    severity: severityBand(percentile: s.percentile),
                    source: .peer
                )
            }
    }

    /// Percentile of `value` against `peers`. When higher-is-better is true
    /// the percentile == fraction of peers worse than the value × 100; when
    /// lower-is-better it's inverted so a low percentile always means "the
    /// athlete sits in the worse end of the distribution".
    private static func percentile(
        of value: Double,
        in peers: [Double],
        higherIsBetter: Bool
    ) -> Double {
        guard !peers.isEmpty else { return 50 }
        let worseCount: Int = peers.reduce(0) { acc, peer in
            higherIsBetter ? (peer < value ? acc + 1 : acc)
                           : (peer > value ? acc + 1 : acc)
        }
        return Double(worseCount) / Double(peers.count) * 100
    }

    private static func severityBand(percentile: Double) -> WeaknessSeverity {
        switch percentile {
        case ..<10: .high
        case 10..<20: .medium
        default: .low
        }
    }
}

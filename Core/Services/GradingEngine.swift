import Foundation

public enum GradingEngine {

    /// Kukkiwon ladder. Past 9th Dan returns the same belt.
    public static func nextBelt(after current: Belt) -> Belt {
        let now = Date()
        switch (current.color, current.kind, current.number) {
        case (.white, .gup, 10): return Belt(color: .white, kind: .gup, number: 9, awardedAt: now)
        case (.white, .gup, 9): return Belt(color: .yellow, kind: .gup, number: 8, awardedAt: now)
        case (.yellow, .gup, 8): return Belt(color: .yellow, kind: .gup, number: 7, awardedAt: now)
        case (.yellow, .gup, 7): return Belt(color: .green, kind: .gup, number: 6, awardedAt: now)
        case (.green, .gup, 6): return Belt(color: .green, kind: .gup, number: 5, awardedAt: now)
        case (.green, .gup, 5): return Belt(color: .blue, kind: .gup, number: 4, awardedAt: now)
        case (.blue, .gup, 4): return Belt(color: .blue, kind: .gup, number: 3, awardedAt: now)
        case (.blue, .gup, 3): return Belt(color: .red, kind: .gup, number: 2, awardedAt: now)
        case (.red, .gup, 2): return Belt(color: .red, kind: .gup, number: 1, awardedAt: now)
        case (.red, .gup, 1): return Belt(color: .black, kind: .poom, number: 1, awardedAt: now)
        case (.black, .poom, let n) where n < 4: return Belt(color: .black, kind: .poom, number: n + 1, awardedAt: now)
        case (.black, .poom, _): return Belt(color: .black, kind: .dan, number: 1, awardedAt: now)
        case (.black, .dan, let n) where n < 9: return Belt(color: .black, kind: .dan, number: n + 1, awardedAt: now)
        default: return current
        }
    }

    public static func evaluateEligibility(
        athlete: Athlete,
        attendance: [AttendanceRecord],
        technical: [TechnicalSkill],
        physical: [PhysicalMetric]
    ) -> GradingEligibility {
        let target = nextBelt(after: athlete.currentBelt)
        let cal = Calendar.current
        let monthsAtCurrent = cal.dateComponents([.month], from: athlete.currentBelt.awardedAt, to: Date()).month ?? 0

        let last90 = Date().addingTimeInterval(-90 * 24 * 3600)
        let recent = attendance.filter { $0.recordedAt >= last90 }
        let attended = recent.filter { $0.state == .present || $0.state == .late }.count
        let attendancePct = recent.isEmpty ? 0 : Double(attended) / Double(recent.count)

        let technicalAvg = technical.latestAverageScore

        let physicalComposite = physicalCompositeScore(physical)

        let requiredMonths = athlete.currentBelt.kind == .gup ? 3 : 6
        var blocking: [String] = []
        if monthsAtCurrent < requiredMonths { blocking.append("grading.blocking.months_at_rank") }
        if attendancePct < 0.75 { blocking.append("grading.blocking.attendance") }
        if technicalAvg < 6.5 { blocking.append("grading.blocking.technical") }
        if physicalComposite < 60 { blocking.append("grading.blocking.physical") }

        return GradingEligibility(
            athleteID: athlete.id,
            currentBelt: athlete.currentBelt,
            targetBelt: target,
            monthsAtCurrent: monthsAtCurrent,
            attendancePct: attendancePct,
            latestTechnicalAvg: technicalAvg,
            latestPhysicalComposite: physicalComposite,
            isEligible: blocking.isEmpty,
            blockingReasons: blocking
        )
    }

    /// 0..100 composite from the latest measurement of each captured kind.
    /// Each metric self-normalises against its `inputRange`. Categories that
    /// have any captured kind contribute their average; missing categories are
    /// not penalised so an athlete with only flexibility data still scores.
    public static func physicalCompositeScore(_ metrics: [PhysicalMetric]) -> Double {
        guard !metrics.isEmpty else { return 0 }
        let latest = metrics.latestPerKind()
        let byCategory = Dictionary(grouping: latest) { $0.kind.category }
        let categoryScores = byCategory.values.map { entries -> Double in
            let normalised = entries.map { $0.kind.normalized($0.value) }
            return normalised.reduce(0, +) / Double(normalised.count)
        }
        guard !categoryScores.isEmpty else { return 0 }
        return (categoryScores.reduce(0, +) / Double(categoryScores.count)) * 100
    }

    public static func decideOutcome(score: GradingScore) -> GradingDecision {
        let total = score.total
        if total >= 70 { return .pass }
        if total >= 60 { return .retry }
        return .fail
    }
}

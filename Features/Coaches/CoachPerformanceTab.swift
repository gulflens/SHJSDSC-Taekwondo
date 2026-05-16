import SwiftUI

/// Coach performance analytics — win rate, athlete improvement, medal count,
/// promotion success, attendance impact, parent satisfaction, peer review.
/// Bars + KPI tiles, no charts library — values rendered via `RatingBarRow`.
public struct CoachPerformanceTab: View {
    public let coach: Coach
    public let assignedAthletes: [Athlete]
    public let coachMatches: [Match]
    public let isWide: Bool

    public init(coach: Coach, assignedAthletes: [Athlete], coachMatches: [Match], isWide: Bool) {
        self.coach = coach
        self.assignedAthletes = assignedAthletes
        self.coachMatches = coachMatches
        self.isWide = isWide
    }

    public var body: some View {
        VStack(spacing: 14) {
            kpiStrip
            performanceCard
            disciplineCard
        }
    }

    private var kpiStrip: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 4 : 2),
            spacing: 12
        ) {
            KPITile(title: "coach.kpi.win_rate", value: String(format: "%.0f%%", winRate * 100), icon: "chart.bar.fill")
            KPITile(title: "coach.kpi.medals", value: "\(medalCount)", icon: "medal.fill")
            KPITile(title: "coach.kpi.athletes", value: "\(assignedAthletes.count)", icon: "person.3.fill")
            KPITile(title: "coach.kpi.cpd_hours", value: String(format: "%.0fh", coach.cpdHoursThisYear), icon: "graduationcap.fill")
        }
    }

    private var performanceCard: some View {
        SectionCard("coach.card.performance_analytics", icon: "chart.line.uptrend.xyaxis") {
            VStack(spacing: 14) {
                RatingBarRow(icon: "trophy.fill", labelKey: "coach.metric.win_rate", value: winRate * 100)
                RatingBarRow(icon: "arrow.up.right.circle.fill", labelKey: "coach.metric.improvement", value: improvementRate * 100)
                RatingBarRow(icon: "checkmark.seal.fill", labelKey: "coach.metric.promotion_success", value: promotionRate * 100)
                RatingBarRow(icon: "calendar.badge.checkmark", labelKey: "coach.metric.attendance_impact", value: attendanceImpact * 100)
                RatingBarRow(icon: "heart.fill", labelKey: "coach.metric.parent_satisfaction", value: (coach.parentSatisfactionAvg ?? 0) * 20, maxValue: 100)
                RatingBarRow(icon: "person.2.fill", labelKey: "coach.metric.peer_review", value: (coach.peerReviewAvg ?? 0) * 20, maxValue: 100)
            }
        }
    }

    private var disciplineCard: some View {
        SectionCard("coach.card.discipline_competency", icon: "figure.taichi") {
            VStack(spacing: 12) {
                RatingBarRow(
                    icon: "figure.taichi",
                    labelKey: "coach.competency.technical",
                    value: Double(coach.technicalLevel ?? 0),
                    maxValue: 5
                )
                RatingBarRow(
                    icon: "figure.boxing",
                    labelKey: "coach.competency.sparring",
                    value: Double(coach.sparringLevel ?? 0),
                    maxValue: 5
                )
                RatingBarRow(
                    icon: "figure.mind.and.body",
                    labelKey: "coach.competency.poomsae",
                    value: Double(coach.poomsaeLevel ?? 0),
                    maxValue: 5
                )
                RatingBarRow(
                    icon: "figure.run",
                    labelKey: "coach.competency.fitness",
                    value: Double(coach.fitnessLevel ?? 0),
                    maxValue: 5
                )
            }
        }
    }

    // MARK: - Derived

    private var winRate: Double {
        guard !coachMatches.isEmpty else { return 0 }
        let wins = coachMatches.filter { $0.effectiveOutcome == .win }.count
        return Double(wins) / Double(coachMatches.count)
    }

    private var medalCount: Int {
        coachMatches.filter { $0.medal != .none }.count
    }

    /// Proxy: fraction of athletes that are readyToGrade OR competitionTeam.
    /// In Stage 5 this gets replaced with real period-over-period composite
    /// deltas from PerformanceScore.scoreHistory.
    private var improvementRate: Double {
        guard !assignedAthletes.isEmpty else { return 0 }
        let progressing = assignedAthletes.filter {
            $0.status == .readyToGrade || $0.status == .competitionTeam
        }.count
        return Double(progressing) / Double(assignedAthletes.count)
    }

    /// Proxy from belt history depth — proper grading-cert lookup is a
    /// follow-up.
    private var promotionRate: Double {
        guard !assignedAthletes.isEmpty else { return 0 }
        let advanced = assignedAthletes.filter { $0.beltHistory.count > 1 }.count
        return Double(advanced) / Double(assignedAthletes.count)
    }

    /// Proxy: 1 - (injuredOrResting / total). Real metric is a longitudinal
    /// attendance-rate average; this is the stop-gap.
    private var attendanceImpact: Double {
        guard !assignedAthletes.isEmpty else { return 0 }
        let activeCount = assignedAthletes.filter { $0.fitToTrain && $0.status != .rest }.count
        return Double(activeCount) / Double(assignedAthletes.count)
    }
}

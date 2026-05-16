import SwiftUI

/// Premium Overview tab — matches the reference design: Athlete Summary +
/// Progress ring (paired), Training This Week, Latest Performance, Upcoming
/// Event, Current Rankings, Recent Achievements.
public struct AthleteOverviewTab: View {
    public let athlete: Athlete
    public let branchName: String?
    public let coachName: String?
    public let score: PerformanceScore?
    public let scoreHistory: [PerformanceScore]
    public let physicalMetrics: [PhysicalMetric]
    public let attendance: [AttendanceRecord]
    public let trainingLoad: [TrainingLoadEntry]
    public let matches: [Match]
    public let registrations: [TournamentRegistration]
    public let tournaments: [EntityID: Tournament]
    public let isWide: Bool

    public init(
        athlete: Athlete,
        branchName: String?,
        coachName: String?,
        score: PerformanceScore?,
        scoreHistory: [PerformanceScore],
        physicalMetrics: [PhysicalMetric],
        attendance: [AttendanceRecord],
        trainingLoad: [TrainingLoadEntry],
        matches: [Match],
        registrations: [TournamentRegistration],
        tournaments: [EntityID: Tournament],
        isWide: Bool
    ) {
        self.athlete = athlete
        self.branchName = branchName
        self.coachName = coachName
        self.score = score
        self.scoreHistory = scoreHistory
        self.physicalMetrics = physicalMetrics
        self.attendance = attendance
        self.trainingLoad = trainingLoad
        self.matches = matches
        self.registrations = registrations
        self.tournaments = tournaments
        self.isWide = isWide
    }

    public var body: some View {
        if isWide {
            wideLayout
        } else {
            compactLayout
        }
    }

    // MARK: - Layouts

    private var compactLayout: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                summaryCard
                progressCard
            }
            trainingThisWeekCard
            latestPerformanceCard
            upcomingEventCard
            currentRankingsCard
            recentAchievementsCard
        }
    }

    private var wideLayout: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                summaryCard.frame(maxWidth: .infinity)
                progressCard.frame(width: 260)
                VStack(spacing: 14) {
                    trainingThisWeekCard
                }
                .frame(maxWidth: .infinity)
            }
            HStack(alignment: .top, spacing: 14) {
                latestPerformanceCard.frame(maxWidth: .infinity)
                VStack(spacing: 14) {
                    upcomingEventCard
                    currentRankingsCard
                }
                .frame(maxWidth: .infinity)
            }
            recentAchievementsCard
        }
    }

    // MARK: - Cards

    private var summaryCard: some View {
        SectionCard("athlete.card.summary", icon: "person.text.rectangle.fill") {
            VStack(spacing: 6) {
                AthleteSummaryRow(
                    icon: "circle.hexagongrid.fill",
                    labelKey: "athlete.field.current_belt",
                    value: NSLocalizedString(athlete.currentBelt.color.labelKey, comment: "")
                        + " · " + NSLocalizedString(athlete.currentBelt.label, comment: "")
                )
                AthleteSummaryRow(
                    icon: "calendar",
                    labelKey: "athlete.field.age_category",
                    value: NSLocalizedString(athlete.ageGroup.labelKey, comment: "")
                )
                if let weightClass = athlete.weightClass {
                    AthleteSummaryRow(
                        icon: "scalemass.fill",
                        labelKey: "athlete.field.weight_category",
                        value: NSLocalizedString(weightClass.labelKey, comment: "")
                    )
                }
                if let leg = athlete.dominantLeg {
                    AthleteSummaryRow(
                        icon: "figure.kickboxing",
                        labelKey: "athlete.field.dominant_leg",
                        value: NSLocalizedString(leg.labelKey, comment: "")
                    )
                }
                AthleteSummaryRow(
                    icon: "building.2.fill",
                    labelKey: "athlete.field.club",
                    value: branchName ?? "—"
                )
                if let coachName {
                    AthleteSummaryRow(
                        icon: "person.fill",
                        labelKey: "athlete.field.coach",
                        value: coachName
                    )
                }
            }
        }
    }

    private var progressCard: some View {
        SectionCard {
            VStack(spacing: 10) {
                ProgressRing(
                    value: overallProgress,
                    size: 132,
                    centerLabelKey: "athlete.overall_progress",
                    delta: progressDelta
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var trainingThisWeekCard: some View {
        SectionCard("athlete.card.training_this_week", icon: "figure.run") {
            VStack(spacing: 12) {
                TrainingStatRow(
                    icon: "calendar.badge.checkmark",
                    labelKey: "athlete.training.sessions",
                    value: Double(sessionsThisWeek),
                    target: 10
                )
                TrainingStatRow(
                    icon: "clock.fill",
                    labelKey: "athlete.training.hours",
                    value: trainingHoursThisWeek,
                    target: 15,
                    unitSuffix: "h"
                )
                TrainingStatRow(
                    icon: "figure.martial.arts",
                    labelKey: "athlete.training.sparring_rounds",
                    value: Double(sparringRoundsThisWeek),
                    target: 30
                )
                TrainingStatRow(
                    icon: "bolt.heart.fill",
                    labelKey: "athlete.training.fitness_score",
                    value: fitnessScore,
                    target: 100,
                    unitSuffix: "%"
                )
            }
        }
    }

    private var latestPerformanceCard: some View {
        SectionCard("athlete.card.latest_performance", icon: "chart.bar.xaxis") {
            VStack(spacing: 12) {
                RatingBarRow(icon: "bolt.heart.fill", labelKey: "perf.fitness", value: fitnessScore)
                RatingBarRow(icon: "hare.fill", labelKey: "perf.speed", value: ratingForCategory(.speed))
                RatingBarRow(icon: "bolt.fill", labelKey: "perf.power", value: ratingForCategory(.power))
                RatingBarRow(icon: "lungs.fill", labelKey: "perf.endurance", value: ratingForCategory(.endurance))
                RatingBarRow(icon: "scope", labelKey: "perf.accuracy", value: kickAccuracyAvg)
                RatingBarRow(icon: "figure.flexibility", labelKey: "perf.flexibility", value: ratingForCategory(.flexibility))
            }
        }
    }

    @ViewBuilder
    private var upcomingEventCard: some View {
        if let upcoming = nextUpcomingRegistration {
            SectionCard("athlete.card.upcoming_event", icon: "calendar.badge.clock") {
                if let tournament = tournaments[upcoming.tournamentID] {
                    UpcomingEventCard(
                        date: tournament.startsAt,
                        title: tournament.name,
                        subtitle: tournament.location,
                        footnoteKey: "registration.confirmed"
                    )
                }
            }
        } else {
            SectionCard("athlete.card.upcoming_event", icon: "calendar.badge.clock") {
                EmptyStateCard(
                    icon: "calendar",
                    titleKey: "athlete.no_upcoming_event",
                    messageKey: "athlete.no_upcoming_event.message"
                )
            }
        }
    }

    private var currentRankingsCard: some View {
        SectionCard("athlete.card.current_rankings", icon: "trophy.fill") {
            VStack(spacing: 8) {
                RankingRow(labelKey: "ranking.club", icon: "building.2.fill", rank: athlete.ranking?.club)
                RankingRow(labelKey: "ranking.uae", icon: "flag.fill", rank: athlete.ranking?.uae)
                RankingRow(labelKey: "ranking.world_taekwondo", icon: "globe", rank: athlete.ranking?.world)
                RankingRow(labelKey: "ranking.olympic", icon: "rosette", rank: athlete.ranking?.olympic)
            }
        }
    }

    private var recentAchievementsCard: some View {
        let medals = matches.filter { $0.medal != .none }.prefix(6)
        return SectionCard("athlete.card.recent_achievements", icon: "medal.fill") {
            if medals.isEmpty {
                EmptyStateCard(
                    icon: "medal",
                    titleKey: "athlete.no_achievements",
                    messageKey: "athlete.no_achievements.message"
                )
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 6 : 3),
                    spacing: 12
                ) {
                    ForEach(Array(medals)) { match in
                        AchievementMedalCard(
                            medal: match.medal,
                            tournamentName: match.tournamentName,
                            date: match.date,
                            categoryDescription: nil
                        )
                    }
                }
            }
        }
    }

    // MARK: - Derived data

    /// 0...1 overall progress from the composite performance score.
    private var overallProgress: Double {
        guard let score else { return 0 }
        let weights: ScoreWeights = athlete.status == .competitionTeam
            ? .competitionTeam
            : (athlete.ageGroup == .cubs ? .cubs : .standard)
        return min(1, max(0, ScoreEngine.composite(score, weights: weights) / 100))
    }

    /// Delta vs. the previous calculated score (most recent in history).
    private var progressDelta: Double? {
        guard scoreHistory.count >= 2, let score else { return nil }
        let sorted = scoreHistory.sorted { $0.calculatedAt > $1.calculatedAt }
        guard let previous = sorted.dropFirst().first else { return nil }
        let weights: ScoreWeights = athlete.status == .competitionTeam
            ? .competitionTeam
            : (athlete.ageGroup == .cubs ? .cubs : .standard)
        let current = ScoreEngine.composite(score, weights: weights) / 100
        let prev = ScoreEngine.composite(previous, weights: weights) / 100
        return current - prev
    }

    private var weekInterval: DateInterval {
        let cal = Calendar.current
        let now = Date()
        let weekStart = cal.date(byAdding: .day, value: -7, to: now) ?? now
        return DateInterval(start: weekStart, end: now)
    }

    private var sessionsThisWeek: Int {
        attendance.filter { weekInterval.contains($0.recordedAt) && $0.state == .present }.count
    }

    private var trainingHoursThisWeek: Double {
        let totalMinutes = trainingLoad
            .filter { weekInterval.contains($0.recordedAt) }
            .reduce(0) { $0 + $1.durationMinutes }
        return Double(totalMinutes) / 60.0
    }

    private var sparringRoundsThisWeek: Int {
        matches
            .filter { weekInterval.contains($0.date) }
            .reduce(0) { $0 + $1.rounds }
    }

    private var fitnessScore: Double {
        guard let score else { return 0 }
        return score.physical * 100
    }

    private var kickAccuracyAvg: Double {
        let accuracies = matches.compactMap { $0.kickAccuracy }
        guard !accuracies.isEmpty else { return 0 }
        return accuracies.reduce(0, +) / Double(accuracies.count)
    }

    /// Returns a 0...100 normalised score for the requested physical category
    /// by averaging the latest entry per kind in that category.
    private func ratingForCategory(_ category: PhysicalCategory) -> Double {
        let latest = physicalMetrics.latestPerKind().filter { $0.kind.category == category }
        guard !latest.isEmpty else { return 0 }
        let normalised = latest.map { $0.kind.normalized($0.value) }
        let avg = normalised.reduce(0, +) / Double(normalised.count)
        return avg * 100
    }

    private var nextUpcomingRegistration: TournamentRegistration? {
        let now = Date()
        return registrations
            .filter { r in
                guard let t = tournaments[r.tournamentID] else { return false }
                return t.startsAt > now && r.status == .registered
            }
            .sorted { a, b in
                let ta = tournaments[a.tournamentID]?.startsAt ?? .distantFuture
                let tb = tournaments[b.tournamentID]?.startsAt ?? .distantFuture
                return ta < tb
            }
            .first
    }
}

import SwiftUI

/// Premium Coach Overview tab — Coach Summary + Coaching Performance ring +
/// Team Overview + Upcoming Events + Certifications + Recent Achievements +
/// Coach Rankings. Visual rhythm matches AthleteOverviewTab so the two
/// modules feel like one ecosystem.
public struct CoachOverviewTab: View {
    public let coach: Coach
    public let primaryBranchName: String?
    public let assignedAthletes: [Athlete]
    public let coachMatches: [Match]
    public let certifications: [Certification]
    public let upcomingTournaments: [Tournament]
    public let isWide: Bool

    public init(
        coach: Coach,
        primaryBranchName: String?,
        assignedAthletes: [Athlete],
        coachMatches: [Match],
        certifications: [Certification],
        upcomingTournaments: [Tournament],
        isWide: Bool
    ) {
        self.coach = coach
        self.primaryBranchName = primaryBranchName
        self.assignedAthletes = assignedAthletes
        self.coachMatches = coachMatches
        self.certifications = certifications
        self.upcomingTournaments = upcomingTournaments
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
                performanceRingCard
            }
            teamOverviewCard
            certificationsCard
            upcomingEventsCard
            currentRankingsCard
            recentAchievementsCard
        }
    }

    private var wideLayout: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                summaryCard.frame(maxWidth: .infinity)
                performanceRingCard.frame(width: 260)
                teamOverviewCard.frame(maxWidth: .infinity)
            }
            HStack(alignment: .top, spacing: 14) {
                certificationsCard.frame(maxWidth: .infinity)
                upcomingEventsCard.frame(maxWidth: .infinity)
                currentRankingsCard.frame(maxWidth: .infinity)
            }
            recentAchievementsCard
        }
    }

    // MARK: - Cards

    private var summaryCard: some View {
        SectionCard("coach.card.summary", icon: "person.text.rectangle.fill") {
            VStack(spacing: 6) {
                if let level = coach.coachLevel {
                    AthleteSummaryRow(
                        icon: "rosette",
                        labelKey: "coach.field.level",
                        value: NSLocalizedString(level.labelKey, comment: "")
                    )
                }
                AthleteSummaryRow(
                    icon: "calendar",
                    labelKey: "coach.field.experience",
                    value: "\(coach.yearsOfExperience) yr"
                )
                AthleteSummaryRow(
                    icon: "building.2.fill",
                    labelKey: "coach.field.branch",
                    value: primaryBranchName ?? "—"
                )
                if let spec = coach.specialisation {
                    AthleteSummaryRow(
                        icon: spec.systemIcon,
                        labelKey: "coach.field.specialisation",
                        value: NSLocalizedString(spec.labelKey, comment: "")
                    )
                }
                AthleteSummaryRow(
                    icon: "person.3.fill",
                    labelKey: "coach.field.active_athletes",
                    value: "\(assignedAthletes.count)"
                )
                AthleteSummaryRow(
                    icon: "checkmark.seal.fill",
                    labelKey: "coach.field.active_certifications",
                    value: "\(activeCertCount)"
                )
                AthleteSummaryRow(
                    icon: "briefcase.fill",
                    labelKey: "coach.field.contract",
                    value: NSLocalizedString(coach.contractType.labelKey, comment: "")
                )
            }
        }
    }

    private var performanceRingCard: some View {
        SectionCard {
            VStack(spacing: 10) {
                ProgressRing(
                    value: performanceScore,
                    size: 132,
                    centerLabelKey: "coach.performance.composite",
                    delta: nil
                )
                Text("coach.performance.composite_caption")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var teamOverviewCard: some View {
        SectionCard("coach.card.team_overview", icon: "person.3.sequence.fill") {
            VStack(spacing: 10) {
                TrainingStatRow(
                    icon: "person.3.fill",
                    labelKey: "coach.team.total",
                    value: Double(assignedAthletes.count),
                    target: 0
                )
                TrainingStatRow(
                    icon: "flame.fill",
                    labelKey: "coach.team.elite",
                    value: Double(eliteCount),
                    target: Double(max(assignedAthletes.count, 1))
                )
                TrainingStatRow(
                    icon: "flag.fill",
                    labelKey: "coach.team.national",
                    value: Double(nationalCount),
                    target: Double(max(assignedAthletes.count, 1))
                )
                TrainingStatRow(
                    icon: "bandage.fill",
                    labelKey: "coach.team.injured",
                    value: Double(injuredCount),
                    target: Double(max(assignedAthletes.count, 1))
                )
            }
        }
    }

    private var certificationsCard: some View {
        SectionCard("coach.card.certifications", icon: "checkmark.seal.fill") {
            VStack(spacing: 6) {
                AthleteSummaryRow(
                    icon: "checkmark.circle.fill",
                    labelKey: "coach.certifications.active",
                    value: "\(activeCertCount)",
                    valueColor: .green
                )
                AthleteSummaryRow(
                    icon: "exclamationmark.circle.fill",
                    labelKey: "coach.certifications.expiring",
                    value: "\(expiringCertCount)",
                    valueColor: expiringCertCount > 0 ? .orange : .secondary
                )
                AthleteSummaryRow(
                    icon: "xmark.circle.fill",
                    labelKey: "coach.certifications.expired",
                    value: "\(expiredCertCount)",
                    valueColor: expiredCertCount > 0 ? .red : .secondary
                )
                if let next = certifications.min(by: { $0.expiresAt < $1.expiresAt }) {
                    Divider().padding(.vertical, 2)
                    AthleteSummaryRow(
                        icon: "clock.fill",
                        labelKey: "coach.certifications.next_renewal",
                        value: dateString(next.expiresAt)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var upcomingEventsCard: some View {
        if let next = upcomingTournaments.sorted(by: { $0.startsAt < $1.startsAt }).first {
            SectionCard("coach.card.upcoming_events", icon: "calendar.badge.clock") {
                UpcomingEventCard(
                    date: next.startsAt,
                    title: next.name,
                    subtitle: next.location,
                    footnoteKey: "coach.events.team_competing"
                )
            }
        } else {
            SectionCard("coach.card.upcoming_events", icon: "calendar.badge.clock") {
                EmptyStateCard(
                    icon: "calendar",
                    titleKey: "coach.events.empty.title",
                    messageKey: "coach.events.empty.message"
                )
            }
        }
    }

    private var currentRankingsCard: some View {
        SectionCard("coach.card.rankings", icon: "trophy.fill") {
            VStack(spacing: 8) {
                RankingRow(labelKey: "ranking.club", icon: "building.2.fill", rank: coach.ranking?.club)
                RankingRow(labelKey: "ranking.uae", icon: "flag.fill", rank: coach.ranking?.uae)
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .scaledFont(.subheadline)
                        .foregroundStyle(.tint)
                        .frame(width: 22)
                    Text("coach.ranking.wt_tier")
                        .scaledFont(.footnote)
                    Spacer(minLength: 8)
                    Text(verbatim: coach.ranking?.worldTier ?? "—")
                        .scaledFont(.footnote, weight: .bold)
                        .foregroundStyle(coach.ranking?.worldTier == nil ? .secondary : .primary)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var recentAchievementsCard: some View {
        let medals = coachMatches.filter { $0.medal != .none }
            .sorted(by: { $0.date > $1.date })
            .prefix(6)
        return SectionCard("coach.card.recent_achievements", icon: "medal.fill") {
            if medals.isEmpty {
                EmptyStateCard(
                    icon: "medal",
                    titleKey: "coach.achievements.empty.title",
                    messageKey: "coach.achievements.empty.message"
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
                            date: match.date
                        )
                    }
                }
            }
        }
    }

    // MARK: - Derived

    private var eliteCount: Int {
        assignedAthletes.filter { $0.status == .competitionTeam }.count
    }

    private var nationalCount: Int {
        // Proxy: kyorugi tier elite OR member of competition team in seniors/juniors
        assignedAthletes.filter { athlete in
            athlete.kyorugiTier == .elite
                && (athlete.ageGroup == .seniors || athlete.ageGroup == .juniors)
        }.count
    }

    private var injuredCount: Int {
        assignedAthletes.filter { !$0.fitToTrain }.count
    }

    private var activeCertCount: Int {
        certifications.filter { $0.severity == .ok }.count
    }

    private var expiringCertCount: Int {
        certifications.filter { $0.severity == .expiring }.count
    }

    private var expiredCertCount: Int {
        certifications.filter { $0.severity == .expired }.count
    }

    /// 0...1 composite of: win-rate of coached athletes, certification health,
    /// parent satisfaction, peer review. Renders nil-safe with a 0 baseline.
    private var performanceScore: Double {
        let winRate: Double = {
            guard !coachMatches.isEmpty else { return 0 }
            let wins = coachMatches.filter { $0.effectiveOutcome == .win }.count
            return Double(wins) / Double(coachMatches.count)
        }()
        let certHealth: Double = {
            guard !certifications.isEmpty else { return 0 }
            return Double(activeCertCount) / Double(certifications.count)
        }()
        let parent = (coach.parentSatisfactionAvg ?? 3.0) / 5.0
        let peer = (coach.peerReviewAvg ?? 3.0) / 5.0
        return max(0, min(1, (winRate + certHealth + parent + peer) / 4.0))
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

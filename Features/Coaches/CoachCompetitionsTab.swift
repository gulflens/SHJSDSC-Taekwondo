import SwiftUI

/// Coach competitions surface — medal breakdown KPI tiles, win-rate analytics,
/// and the table of tournaments where this coach's athletes competed.
public struct CoachCompetitionsTab: View {
    public let coach: Coach
    public let coachMatches: [Match]
    public let tournaments: [EntityID: Tournament]
    public let isWide: Bool

    public init(coach: Coach, coachMatches: [Match], tournaments: [EntityID: Tournament], isWide: Bool) {
        self.coach = coach
        self.coachMatches = coachMatches
        self.tournaments = tournaments
        self.isWide = isWide
    }

    public var body: some View {
        VStack(spacing: 14) {
            kpiStrip
            medalsBreakdownCard
            tournamentsManagedCard
        }
    }

    private var kpiStrip: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 6 : 2),
            spacing: 12
        ) {
            KPITile(title: "coach.competition.tournaments", value: "\(tournamentsManagedCount)", icon: "flag.checkered")
            KPITile(title: "coach.competition.athletes_competed", value: "\(athletesCompetedCount)", icon: "person.3.fill")
            KPITile(title: "coach.competition.matches", value: "\(coachMatches.count)", icon: "figure.boxing")
            KPITile(title: "coach.competition.gold", value: "\(medalCount(.gold))", icon: "medal.fill")
            KPITile(title: "coach.competition.silver", value: "\(medalCount(.silver))", icon: "medal.fill")
            KPITile(title: "coach.competition.bronze", value: "\(medalCount(.bronze))", icon: "medal.fill")
        }
    }

    private var medalsBreakdownCard: some View {
        SectionCard("coach.competition.medal_breakdown", icon: "trophy.fill") {
            VStack(spacing: 10) {
                medalBar(.gold, color: Color(red: 0.86, green: 0.65, blue: 0.13))
                medalBar(.silver, color: Color(white: 0.55))
                medalBar(.bronze, color: Color(red: 0.72, green: 0.45, blue: 0.20))
                Divider().padding(.vertical, 2)
                HStack {
                    Text("coach.competition.total_medals")
                        .scaledFont(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Text(verbatim: "\(totalMedals)")
                        .scaledFont(.title3, weight: .bold, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
        }
    }

    private func medalBar(_ medal: MedalType, color: Color) -> some View {
        let count = medalCount(medal)
        let max = Swift.max(1, [medalCount(.gold), medalCount(.silver), medalCount(.bronze)].max() ?? 1)
        return VStack(spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "medal.fill")
                        .foregroundStyle(color)
                    Text(localizedKey: medal.labelKey)
                        .scaledFont(.caption, weight: .semibold)
                }
                Spacer(minLength: 0)
                Text(verbatim: "\(count)")
                    .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                    .environment(\.layoutDirection, .leftToRight)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.12))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max > 0 ? geo.size.width * Double(count) / Double(max) : 0)
                }
            }
            .frame(height: 6)
        }
    }

    private var tournamentsManagedCard: some View {
        SectionCard("coach.competition.tournaments_managed", icon: "list.bullet.rectangle") {
            if uniqueTournaments.isEmpty {
                EmptyStateCard(
                    icon: "trophy",
                    titleKey: "coach.competition.empty.title",
                    messageKey: "coach.competition.empty.message"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(uniqueTournaments) { tournament in
                        tournamentRow(tournament)
                        if tournament.id != uniqueTournaments.last?.id {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
    }

    private func tournamentRow(_ tournament: Tournament) -> some View {
        let related = coachMatches.filter { $0.tournamentID == tournament.id }
        let golds = related.filter { $0.medal == .gold }.count
        let silvers = related.filter { $0.medal == .silver }.count
        let bronzes = related.filter { $0.medal == .bronze }.count
        return HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(tournament.startsAt, format: .dateTime.month(.abbreviated))
                    .scaledFont(.caption, weight: .bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                    .background(Color.accentColor)
                Text(tournament.startsAt, format: .dateTime.day())
                    .scaledFont(.title3, weight: .bold, monospacedDigit: true)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(width: 54)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: tournament.name)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                Text(verbatim: tournament.location)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                medalCount(golds, color: Color(red: 0.86, green: 0.65, blue: 0.13))
                medalCount(silvers, color: Color(white: 0.55))
                medalCount(bronzes, color: Color(red: 0.72, green: 0.45, blue: 0.20))
            }
        }
        .padding(.vertical, 4)
    }

    private func medalCount(_ count: Int, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "medal.fill")
                .scaledFont(.caption2)
                .foregroundStyle(count > 0 ? color : Color.secondary.opacity(0.3))
            Text(verbatim: "\(count)")
                .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                .foregroundStyle(count > 0 ? .primary : .secondary)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private func medalCount(_ medal: MedalType) -> Int {
        coachMatches.filter { $0.medal == medal }.count
    }

    private var totalMedals: Int { coachMatches.filter { $0.medal != .none }.count }

    private var athletesCompetedCount: Int {
        Set(coachMatches.map { $0.ourAthleteID }).count
    }

    private var tournamentsManagedCount: Int { uniqueTournaments.count }

    private var uniqueTournaments: [Tournament] {
        var seen: Set<EntityID> = []
        var out: [Tournament] = []
        for m in coachMatches {
            guard let tid = m.tournamentID, let t = tournaments[tid], !seen.contains(tid) else { continue }
            seen.insert(tid)
            out.append(t)
        }
        return out.sorted { $0.startsAt > $1.startsAt }
    }
}

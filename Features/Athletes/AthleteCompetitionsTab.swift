import SwiftUI

/// Competitions tab — premium table on iPad with Tournament/Date/Location/
/// Weight/Result/Medal/Points columns; iPhone collapses to card rows.
public struct AthleteCompetitionsTab: View {
    public let athlete: Athlete
    public let matches: [Match]
    public let registrations: [TournamentRegistration]
    public let tournaments: [EntityID: Tournament]
    public let isWide: Bool
    public let onOpenSparring: (Match?) -> Void

    public init(
        athlete: Athlete,
        matches: [Match],
        registrations: [TournamentRegistration],
        tournaments: [EntityID: Tournament],
        isWide: Bool,
        onOpenSparring: @escaping (Match?) -> Void
    ) {
        self.athlete = athlete
        self.matches = matches
        self.registrations = registrations
        self.tournaments = tournaments
        self.isWide = isWide
        self.onOpenSparring = onOpenSparring
    }

    public var body: some View {
        VStack(spacing: 14) {
            kpiStrip
            CompetitionHistoryCard(athleteID: athlete.id, matches: matches)
            historyTableCard
        }
    }

    // MARK: - KPI strip

    private var kpiStrip: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 5 : 2),
            spacing: 12
        ) {
            KPITile(title: "competition.medals", value: "\(medalsCount)", icon: "medal.fill")
            KPITile(title: "competition.matches", value: "\(matches.count)", icon: "flag.checkered")
            KPITile(title: "competition.wins", value: "\(wins)", icon: "checkmark.seal.fill")
            KPITile(title: "competition.win_rate", value: String(format: "%.0f%%", winRate * 100), icon: "chart.bar.fill")
            KPITile(title: "competition.ranking_points", value: "\(rankingPointsTotal)", icon: "rosette")
        }
    }

    // MARK: - History "table" on iPad / card list on iPhone

    private var historyTableCard: some View {
        SectionCard("competition.history_title", icon: "list.bullet.rectangle") {
            if matches.isEmpty {
                EmptyStateCard(
                    icon: "trophy",
                    titleKey: "competition.empty.title",
                    messageKey: "competition.empty.message"
                )
            } else if isWide {
                tableHeader
                Divider().opacity(0.4)
                VStack(spacing: 0) {
                    ForEach(Array(matches.sorted { $0.date > $1.date }.prefix(20))) { match in
                        tableRow(match)
                        Divider().opacity(0.4)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(matches.sorted { $0.date > $1.date }.prefix(10))) { match in
                        cardRow(match)
                    }
                }
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 12) {
            tableCell("competition.col.tournament", weight: 3, alignment: .leading)
            tableCell("competition.col.date", weight: 1.4, alignment: .leading)
            tableCell("competition.col.location", weight: 2, alignment: .leading)
            tableCell("competition.col.weight", weight: 1, alignment: .center)
            tableCell("competition.col.result", weight: 1.4, alignment: .center)
            tableCell("competition.col.medal", weight: 1, alignment: .center)
            tableCell("competition.col.points", weight: 1, alignment: .trailing)
        }
        .scaledFont(.caption2, weight: .semibold)
        .foregroundStyle(.secondary)
        .padding(.vertical, 6)
    }

    private func tableCell(_ key: LocalizedStringKey, weight: CGFloat, alignment: Alignment) -> some View {
        Text(key)
            .frame(maxWidth: .infinity, alignment: alignment)
            .layoutPriority(weight)
    }

    private func tableRow(_ match: Match) -> some View {
        Button {
            onOpenSparring(match)
        } label: {
            HStack(spacing: 12) {
                cellText(match.tournamentName, weight: 3, alignment: .leading)
                cellDate(match.date, weight: 1.4)
                cellText(tournaments[match.tournamentID ?? UUID()]?.location ?? "—", weight: 2, alignment: .leading)
                cellText(String(format: "%.0fkg", match.weightClassKg), weight: 1, alignment: .center).monospacedDigit()
                resultCell(match).frame(maxWidth: .infinity, alignment: .center).layoutPriority(1.4)
                medalCell(match).frame(maxWidth: .infinity, alignment: .center).layoutPriority(1)
                cellText("\(rankingPoints(match))", weight: 1, alignment: .trailing).monospacedDigit()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func cellText(_ text: String, weight: CGFloat, alignment: Alignment) -> some View {
        Text(verbatim: text)
            .scaledFont(.footnote)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: alignment)
            .layoutPriority(weight)
    }

    private func cellDate(_ date: Date, weight: CGFloat) -> some View {
        Text(date, format: .dateTime.day().month(.abbreviated).year())
            .scaledFont(.footnote, monospacedDigit: true)
            .environment(\.layoutDirection, .leftToRight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(weight)
    }

    private func resultCell(_ match: Match) -> some View {
        let outcome = match.effectiveOutcome
        let color: Color = switch outcome {
        case .win: .green
        case .loss: .red
        case .draw: .secondary
        }
        return HStack(spacing: 4) {
            Text(localizedKey: outcome.labelKey)
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(color)
            Text(verbatim: "\(match.ourScore)–\(match.opponentScore)")
                .scaledFont(.caption, monospacedDigit: true)
                .foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private func medalCell(_ match: Match) -> some View {
        Group {
            if match.medal == .none {
                Text(verbatim: "—")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "medal.fill")
                    .scaledFont(.subheadline)
                    .foregroundStyle(medalColor(match.medal))
            }
        }
    }

    private func medalColor(_ medal: MedalType) -> Color {
        switch medal {
        case .gold: Color(red: 0.86, green: 0.65, blue: 0.13)
        case .silver: Color(white: 0.55)
        case .bronze: Color(red: 0.72, green: 0.45, blue: 0.20)
        case .none: .secondary
        }
    }

    private func cardRow(_ match: Match) -> some View {
        Button {
            onOpenSparring(match)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                medalCell(match)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: match.tournamentName)
                        .scaledFont(.subheadline, weight: .semibold)
                    HStack(spacing: 6) {
                        Text(match.date, format: .dateTime.day().month(.abbreviated).year())
                            .environment(\.layoutDirection, .leftToRight)
                        Text(verbatim: "·")
                        Text(verbatim: String(format: "%.0fkg", match.weightClassKg))
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                resultCell(match)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Derived

    private var medalsCount: Int { matches.filter { $0.medal != .none }.count }
    private var wins: Int { matches.filter { $0.effectiveOutcome == .win }.count }
    private var winRate: Double {
        guard !matches.isEmpty else { return 0 }
        return Double(wins) / Double(matches.count)
    }

    /// Rough proxy for federation ranking points: 50 / 25 / 10 / 5 by medal,
    /// + 1 per win. Replace with the actual federation tariff when wired.
    private func rankingPoints(_ match: Match) -> Int {
        let base = switch match.medal {
        case .gold: 50
        case .silver: 25
        case .bronze: 10
        case .none: 0
        }
        return base + (match.effectiveOutcome == .win ? 1 : 0)
    }

    private var rankingPointsTotal: Int { matches.reduce(0) { $0 + rankingPoints($1) } }
}

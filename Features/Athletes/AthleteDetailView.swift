import SwiftUI

public struct AthleteDetailView: View {
    @Environment(AppSession.self) private var session
    public let athlete: Athlete
    @State private var matches: [Match] = []
    @State private var score: PerformanceScore?
    @State private var registrations: [TournamentRegistration] = []
    @State private var tournamentLookup: [EntityID: Tournament] = [:]

    public init(athlete: Athlete) { self.athlete = athlete }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                BeltStrip(belt: athlete.currentBelt, history: athlete.beltHistory)
                statsGrid
                entryActions
                PerformanceTrendView(athlete: athlete)
                tournamentsSection
                beltJourney
                recentMatches
            }
            .padding()
        }
        .navigationTitle(Text(verbatim: athlete.fullName))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await load() }
    }

    private var hero: some View {
        HStack(spacing: 16) {
            Avatar(seed: athlete.avatarSeed, label: athlete.initials, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: athlete.fullName).font(.title2.bold())
                Text(verbatim: athlete.fullNameAr).font(.body).foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    StatusPill(status: athlete.status)
                    Text(LocalizedStringKey(athlete.ageGroup.labelKey)).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var statsGrid: some View {
        let weights: ScoreWeights = athlete.status == .competitionTeam
            ? .competitionTeam
            : (athlete.ageGroup == .cubs ? .cubs : .standard)
        let composite = score.map { ScoreEngine.composite($0, weights: weights) } ?? 0
        let medals = matches.filter { $0.medal != .none }.count
        let wins = matches.filter { $0.won }.count
        let winRate = matches.isEmpty ? 0 : Double(wins) / Double(matches.count)
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            KPITile(title: "kpi.composite", value: String(format: "%.0f", composite), icon: "star.fill")
            KPITile(title: "kpi.medals", value: "\(medals)", icon: "medal.fill")
            KPITile(title: "kpi.win_rate", value: String(format: "%.0f%%", winRate * 100), icon: "chart.bar.fill")
            KPITile(title: "kpi.weight", value: String(format: "%.0fkg", athlete.weightKg), icon: "scalemass.fill")
        }
    }

    private var entryActions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("heading.entries").font(.headline)
            HStack(spacing: 8) {
                NavigationLink(destination: PhysicalTestEntryView(athlete: athlete)) {
                    Label("physical.add", systemImage: "figure.strengthtraining.traditional")
                }
                .buttonStyle(.bordered)
                NavigationLink(destination: TechnicalAssessmentEntryView(athlete: athlete)) {
                    Label("assessment.add", systemImage: "figure.taichi")
                }
                .buttonStyle(.bordered)
                NavigationLink(destination: WellnessCheckInView(athlete: athlete)) {
                    Label("wellness.add", systemImage: "heart.text.square.fill")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var beltJourney: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("heading.belt_journey").font(.headline)
            ForEach(athlete.beltHistory.indices, id: \.self) { i in
                let b = athlete.beltHistory[i]
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(b.color.swiftUIColor)
                        .frame(width: 24, height: 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                    Text(LocalizedStringKey(b.label))
                    Spacer()
                    Text(b.awardedAt, style: .date)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
    }

    private var tournamentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("tab.tournaments").font(.headline)
            if registrations.isEmpty {
                Text("empty.no_tournaments").foregroundStyle(.secondary)
            } else {
                ForEach(registrations) { r in
                    let t = tournamentLookup[r.tournamentID]
                    HStack(spacing: 8) {
                        Image(systemName: "rosette").foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: t?.name ?? "—").font(.subheadline)
                            HStack(spacing: 4) {
                                Text(verbatim: r.weightCategory.shortLabel).font(.caption2)
                                Text(verbatim: "·").font(.caption2)
                                Text(LocalizedStringKey(r.status.labelKey)).font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let date = t?.startsAt {
                            Text(date, style: .date).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var recentMatches: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("heading.recent_matches").font(.headline)
            if matches.isEmpty {
                Text("empty.no_matches_yet").foregroundStyle(.secondary)
            } else {
                ForEach(Array(matches.prefix(5))) { m in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: m.tournamentName).font(.subheadline)
                            Text(m.date, style: .date).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(verbatim: "\(m.ourScore) - \(m.opponentScore)")
                            .font(.callout.monospacedDigit())
                            .environment(\.layoutDirection, .leftToRight)
                        if m.medal != .none {
                            Image(systemName: "medal.fill").foregroundStyle(medalColor(m.medal))
                        }
                    }
                }
            }
        }
    }

    private func medalColor(_ medal: MedalType) -> Color {
        switch medal {
        case .gold: .yellow
        case .silver: .gray
        case .bronze: .orange
        case .none: .gray
        }
    }

    private func load() async {
        do {
            matches = try await session.repository.matches(athleteID: athlete.id)
            score = try await session.repository.score(athleteID: athlete.id)
            registrations = try await session.repository.registrations(athleteID: athlete.id)
            var lookup: [EntityID: Tournament] = [:]
            for r in registrations {
                if lookup[r.tournamentID] == nil,
                   let t = try await session.repository.tournament(id: r.tournamentID) {
                    lookup[r.tournamentID] = t
                }
            }
            tournamentLookup = lookup
        } catch {
            print("AthleteDetailView.load:", error)
        }
    }
}

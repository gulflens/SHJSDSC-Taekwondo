import SwiftUI

public struct TournamentDetailView: View {
    @Environment(AppSession.self) private var session

    public let tournamentID: EntityID

    @State private var tournament: Tournament?
    @State private var registrations: [TournamentRegistration] = []
    @State private var athleteLookup: [EntityID: Athlete] = [:]
    @State private var brackets: [Bracket] = []
    @State private var bracketMatches: [EntityID: [BracketMatch]] = [:]
    @State private var showRegister = false
    @State private var generating = false

    public init(tournamentID: EntityID) { self.tournamentID = tournamentID }

    public var body: some View {
        Group {
            if let tournament {
                content(tournament: tournament)
            } else {
                ProgressView()
            }
        }
        .subviewChrome(Text(verbatim: tournament?.name ?? "")) {
            if let role = session.currentUser?.role,
               PermissionMatrix.allowed(role: role, permission: .createTournament) {
                Button {
                    showRegister = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
                .accessibilityLabel(Text("tournament.register"))
            }
            if let t = tournament, !registrations.isEmpty {
                ExportButton(
                    baseFilename: "tournament-\(t.name.replacingOccurrences(of: " ", with: "_"))",
                    csvProvider: {
                        CSVReportExporter().exportTournamentResults(
                            tournament: t,
                            registrations: registrations,
                            athletes: Array(athleteLookup.values),
                            matches: [],
                            format: .csv
                        )
                    }
                )
            }
        }
        .sheet(isPresented: $showRegister) {
            NavigationStack {
                RegisterAthleteView(tournamentID: tournamentID) { _ in
                    Task { await reload() }
                }
            }
        }
        .task { await reload() }
    }

    @ViewBuilder
    private func content(tournament t: Tournament) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                infoCard(tournament: t)
                registrationsSection
                bracketsSection(tournament: t)
            }
            .padding()
        }
    }

    private func infoCard(tournament t: Tournament) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: t.isOfficial ? "checkmark.seal.fill" : "rosette")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading) {
                    Text(verbatim: t.name).scaledFont(.title3, weight: .bold)
                    if let nameAr = t.nameAr {
                        Text(verbatim: nameAr).scaledFont(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            HStack {
                Image(systemName: "calendar").scaledFont(.caption2)
                Text(t.startsAt, style: .date).scaledFont(.caption)
                Text(verbatim: "→")
                Text(t.endsAt, style: .date).scaledFont(.caption)
            }
            .foregroundStyle(.secondary)
            HStack {
                Image(systemName: "mappin.and.ellipse").scaledFont(.caption2)
                Text(verbatim: t.location).scaledFont(.caption)
                if let locAr = t.locationAr {
                    Text(verbatim: "·")
                    Text(verbatim: locAr).scaledFont(.caption)
                }
            }
            .foregroundStyle(.secondary)
            HStack {
                Text(localizedKey: t.hostingFederation.labelKey)
                    .scaledFont(.caption, weight: .bold)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var registrationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("grading.candidates").scaledFont(.headline)
            if registrations.isEmpty {
                Text("empty.no_registrations").foregroundStyle(.secondary)
            } else {
                ForEach(registrations) { r in
                    if let a = athleteLookup[r.athleteID] {
                        HStack(spacing: 10) {
                            Avatar(seed: a.avatarSeed, label: a.initials, size: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: a.fullName)
                                Text(verbatim: r.weightCategory.shortLabel)
                                    .scaledFont(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let seed = r.seedRank {
                                Text(verbatim: "#\(seed)")
                                    .scaledFont(.caption, weight: .bold)
                                    .foregroundStyle(.secondary)
                                    .environment(\.layoutDirection, .leftToRight)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func bracketsSection(tournament t: Tournament) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("tournament.bracket").scaledFont(.headline)
                Spacer()
                if let role = session.currentUser?.role,
                   PermissionMatrix.allowed(role: role, permission: .createTournament) {
                    Button {
                        Task { await generateBrackets(tournament: t) }
                    } label: {
                        if generating {
                            ProgressView()
                        } else {
                            Label("tournament.generate_bracket", systemImage: "wand.and.rays")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(generating || registrations.isEmpty)
                }
            }
            if brackets.isEmpty {
                Text("empty.no_brackets").foregroundStyle(.secondary)
            } else {
                ForEach(brackets) { b in
                    NavigationLink(destination: BracketView(bracketID: b.id)) {
                        HStack {
                            Text(verbatim: b.weightCategory.shortLabel).scaledFont(.subheadline, weight: .bold)
                            Spacer()
                            let matchCount = bracketMatches[b.id]?.count ?? 0
                            Text(verbatim: "\(matchCount)")
                                .scaledFont(.caption, monospacedDigit: true)
                                .foregroundStyle(.secondary)
                                .environment(\.layoutDirection, .leftToRight)
                            Image(systemName: "chevron.right").scaledFont(.caption).foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func reload() async {
        do {
            tournament = try await session.repository.tournament(id: tournamentID)
            registrations = try await session.repository.registrations(tournamentID: tournamentID)
            let athleteIDs = Set(registrations.map { $0.athleteID })
            var lookup: [EntityID: Athlete] = [:]
            for id in athleteIDs {
                if let a = try await session.repository.athlete(id: id) { lookup[id] = a }
            }
            athleteLookup = lookup
            brackets = try await session.repository.brackets(tournamentID: tournamentID)
            var bm: [EntityID: [BracketMatch]] = [:]
            for b in brackets {
                bm[b.id] = try await session.repository.bracketMatches(bracketID: b.id)
            }
            bracketMatches = bm
        } catch {
            print("TournamentDetailView.reload:", error)
        }
    }

    private func generateBrackets(tournament t: Tournament) async {
        generating = true
        defer { generating = false }
        // Group registrations by weight category, build a bracket per category with >= 2 entrants.
        let byCategory = Dictionary(grouping: registrations, by: { $0.weightCategory })
        do {
            for (cat, regs) in byCategory where regs.count >= 2 {
                let seeds = regs
                    .sorted { ($0.seedRank ?? Int.max) < ($1.seedRank ?? Int.max) }
                    .map { $0.athleteID }
                let bracket = Bracket(tournamentID: t.id, weightCategory: cat, seeds: seeds)
                try await session.repository.upsert(bracket: bracket)
                let matches = BracketEngine.generateSingleElimination(bracketID: bracket.id, seeds: seeds)
                for m in matches {
                    try await session.repository.upsert(bracketMatch: m)
                }
            }
            await reload()
        } catch {
            print("TournamentDetailView.generateBrackets:", error)
        }
    }
}

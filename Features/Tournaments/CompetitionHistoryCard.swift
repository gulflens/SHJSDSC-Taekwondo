import SwiftUI

/// Athlete-scoped competition history. Built from `[Match]` (passed in by the
/// detail view to avoid a duplicate fetch) plus the athlete's registrations
/// + their tournaments.
public struct CompetitionHistoryCard: View {
    @Environment(AppSession.self) private var session

    public let athleteID: EntityID
    public let matches: [Match]

    @State private var registrations: [TournamentRegistration] = []
    @State private var tournamentLookup: [EntityID: Tournament] = [:]
    @State private var loading = true
    @State private var editing: TournamentRegistration?

    public init(athleteID: EntityID, matches: [Match]) {
        self.athleteID = athleteID
        self.matches = matches
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("athlete.section.competition_history").scaledFont(.headline)
            if loading {
                ProgressView().frame(maxWidth: .infinity)
            } else if registrations.isEmpty {
                Text("empty.no_tournaments")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                ForEach(sortedRegistrations) { reg in
                    eventRow(reg)
                }
            }
        }
        .task { await load() }
        .sheet(item: $editing) { reg in
            NavigationStack {
                CompetitionResultEditor(
                    initial: reg,
                    onSave: { updated in Task { await save(updated) } }
                )
            }
        }
    }

    private var sortedRegistrations: [TournamentRegistration] {
        registrations.sorted { lhs, rhs in
            let lDate = tournamentLookup[lhs.tournamentID]?.startsAt ?? lhs.registeredAt
            let rDate = tournamentLookup[rhs.tournamentID]?.startsAt ?? rhs.registeredAt
            return lDate > rDate
        }
    }

    private func eventRow(_ reg: TournamentRegistration) -> some View {
        let tournament = tournamentLookup[reg.tournamentID]
        let eventMatches = matches.filter { $0.tournamentID == reg.tournamentID }
        let won = eventMatches.filter { $0.won }.count
        let lost = eventMatches.count - won
        let pointsFor = eventMatches.reduce(0) { $0 + $1.ourScore }
        let pointsAgainst = eventMatches.reduce(0) { $0 + $1.opponentScore }
        let opponents = topOpponents(eventMatches)

        return Button {
            guard canEdit else { return }
            editing = reg
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Title row: name, date, level pill, medal.
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: tournament?.name ?? "—")
                            .scaledFont(.subheadline, weight: .bold)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            if let date = tournament?.startsAt {
                                Text(date, style: .date)
                                    .scaledFont(.caption2).foregroundStyle(.secondary)
                            }
                            if let level = tournament?.level {
                                levelPill(level)
                            }
                        }
                    }
                    Spacer()
                    medalIcon(reg.medal ?? .none)
                }

                // Meta row: sanctioning body, weight class, age division.
                HStack(spacing: 6) {
                    if let body = tournament?.sanctioningBody, !body.isEmpty {
                        metaPill(text: body, icon: "rosette")
                    } else {
                        metaPill(textKey: tournament?.hostingFederation.labelKey ?? "—", icon: "rosette")
                    }
                    metaPill(text: reg.weightCategory.shortLabel, icon: "scalemass")
                    if let ageDiv = reg.ageDivisionEntered {
                        metaPill(textKey: ageDiv.labelKey, icon: "person")
                    }
                }

                // Result row: bracket size + final position + W-L + points.
                HStack(spacing: 12) {
                    if let position = reg.finalPosition {
                        statBlock(
                            label: "competition.position",
                            value: positionLabel(position: position, bracketSize: reg.bracketSize)
                        )
                    }
                    if !eventMatches.isEmpty {
                        statBlock(
                            label: "competition.record",
                            value: "\(won)–\(lost)"
                        )
                        statBlock(
                            label: "competition.points",
                            value: "\(pointsFor)/\(pointsAgainst)"
                        )
                    }
                    Spacer()
                }

                // Opponents row.
                if !opponents.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .scaledFont(.caption2)
                            .foregroundStyle(.secondary)
                        Text(verbatim: opponents.joined(separator: ", "))
                            .scaledFont(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func levelPill(_ level: EventLevel) -> some View {
        let color: Color = switch level {
        case .local: .blue
        case .national: .purple
        case .regional: .orange
        case .international: .red
        }
        return Text(localizedKey: level.labelKey)
            .scaledFont(.caption2, weight: .semibold)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private func metaPill(text: String, icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).scaledFont(.caption2).foregroundStyle(.secondary)
            Text(verbatim: text).scaledFont(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.10), in: Capsule())
    }

    private func metaPill(textKey: String, icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).scaledFont(.caption2).foregroundStyle(.secondary)
            Text(localizedKey: textKey).scaledFont(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.10), in: Capsule())
    }

    private func statBlock(label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
            Text(verbatim: value)
                .scaledFont(.callout, weight: .bold, monospacedDigit: true)
                .foregroundStyle(.primary)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private func medalIcon(_ medal: MedalType) -> some View {
        Group {
            switch medal {
            case .gold:
                Image(systemName: "medal.fill").foregroundStyle(.yellow).scaledFont(.title3)
            case .silver:
                Image(systemName: "medal.fill").foregroundStyle(.gray).scaledFont(.title3)
            case .bronze:
                Image(systemName: "medal.fill").foregroundStyle(.orange).scaledFont(.title3)
            case .none:
                Color.clear.frame(width: 0, height: 0)
            }
        }
    }

    private func positionLabel(position: Int, bracketSize: Int?) -> String {
        if let bracketSize, bracketSize > 0 {
            return "\(position) / \(bracketSize)"
        }
        return "\(position)"
    }

    private func topOpponents(_ ms: [Match]) -> [String] {
        var seen: Set<String> = []
        var out: [String] = []
        for m in ms.sorted(by: { $0.date > $1.date }) {
            let label = m.opponentName ?? "—"
            if seen.insert(label).inserted {
                out.append(label)
            }
            if out.count >= 3 { break }
        }
        return out
    }

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editAthlete)
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            registrations = try await session.repository.registrations(athleteID: athleteID)
            var lookup: [EntityID: Tournament] = [:]
            for r in registrations where lookup[r.tournamentID] == nil {
                if let t = try await session.repository.tournament(id: r.tournamentID) {
                    lookup[r.tournamentID] = t
                }
            }
            tournamentLookup = lookup
        } catch {
            print("CompetitionHistoryCard.load:", error)
        }
    }

    private func save(_ reg: TournamentRegistration) async {
        do {
            try await session.repository.upsert(registration: reg)
            await load()
        } catch {
            print("CompetitionHistoryCard.save:", error)
        }
    }
}

// MARK: - Result editor

private struct CompetitionResultEditor: View {
    @Environment(\.dismiss) private var dismiss

    let initial: TournamentRegistration
    let onSave: (TournamentRegistration) -> Void

    @State private var ageDivision: AgeGroup
    @State private var hasAgeDivision: Bool
    @State private var bracketSize: Int
    @State private var finalPosition: Int
    @State private var medal: MedalType
    @State private var status: RegistrationStatus

    init(initial: TournamentRegistration, onSave: @escaping (TournamentRegistration) -> Void) {
        self.initial = initial
        self.onSave = onSave
        _ageDivision = State(initialValue: initial.ageDivisionEntered ?? .seniors)
        _hasAgeDivision = State(initialValue: initial.ageDivisionEntered != nil)
        _bracketSize = State(initialValue: initial.bracketSize ?? 0)
        _finalPosition = State(initialValue: initial.finalPosition ?? 0)
        _medal = State(initialValue: initial.medal ?? .none)
        _status = State(initialValue: initial.status)
    }

    var body: some View {
        Form {
            Section {
                Toggle("competition.has_age_division", isOn: $hasAgeDivision)
                if hasAgeDivision {
                    Picker("athlete.age_division", selection: $ageDivision) {
                        ForEach(AgeGroup.allCases, id: \.self) { ag in
                            Text(localizedKey: ag.labelKey).tag(ag)
                        }
                    }
                }
            } header: {
                Text("competition.entry")
            }

            Section {
                Stepper(value: $bracketSize, in: 0...256) {
                    HStack {
                        Text("competition.bracket_size")
                        Spacer()
                        Text(verbatim: "\(bracketSize)")
                            .scaledFont(.callout, monospacedDigit: true)
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
                Stepper(value: $finalPosition, in: 0...max(1, bracketSize)) {
                    HStack {
                        Text("competition.final_position")
                        Spacer()
                        Text(verbatim: "\(finalPosition)")
                            .scaledFont(.callout, monospacedDigit: true)
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
                Picker("competition.medal", selection: $medal) {
                    ForEach(MedalType.allCases, id: \.self) { m in
                        Text(localizedKey: m.labelKey).tag(m)
                    }
                }
            } header: {
                Text("competition.result")
            }

            Section {
                Picker("registration.status", selection: $status) {
                    ForEach(RegistrationStatus.allCases, id: \.self) { s in
                        Text(localizedKey: s.labelKey).tag(s)
                    }
                }
            }
        }
        .navigationTitle(Text("competition.edit_result"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
                .bareToolbarButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("action.save") { commit() }
                .bareToolbarButton()
            }
        }
    }

    private func commit() {
        var reg = initial
        reg.ageDivisionEntered = hasAgeDivision ? ageDivision : nil
        reg.bracketSize = bracketSize > 0 ? bracketSize : nil
        reg.finalPosition = finalPosition > 0 ? finalPosition : nil
        reg.medal = medal == .none ? nil : medal
        reg.status = status
        onSave(reg)
        dismiss()
    }
}

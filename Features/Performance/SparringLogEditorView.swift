import SwiftUI

public struct SparringLogEditorView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let athlete: Athlete
    public let editing: Match?
    public let onSaved: (Match) -> Void

    // === General ===
    @State private var date: Date
    @State private var context: SparringContext
    @State private var tournamentName: String
    @State private var opponentName: String
    @State private var matchType: MatchType
    @State private var weightClassKg: Double

    // === Result ===
    @State private var outcome: MatchOutcome
    @State private var winMethod: WinMethod
    @State private var rounds: Int
    @State private var roundsWon: Int
    @State private var roundsLost: Int
    @State private var ourScore: Int
    @State private var opponentScore: Int
    @State private var medal: MedalType

    // === Aggregates ===
    @State private var kicksAttempted: Int
    @State private var kicksLanded: Int
    @State private var punchesAttempted: Int
    @State private var punchesLanded: Int

    // === Points scored ===
    @State private var ourPunchPoints: Int
    @State private var ourBodyKickPoints: Int
    @State private var ourHeadKickPoints: Int
    @State private var ourSpinningBodyPoints: Int
    @State private var ourSpinningHeadPoints: Int

    // === Points conceded ===
    @State private var oppPunchPoints: Int
    @State private var oppBodyKickPoints: Int
    @State private var oppHeadKickPoints: Int
    @State private var oppSpinningBodyPoints: Int
    @State private var oppSpinningHeadPoints: Int

    // === Discipline ===
    @State private var penaltiesGiven: Int
    @State private var penaltiesReceived: Int
    @State private var knockdownsScored: Int
    @State private var knockdownsReceived: Int

    // === Tactical ===
    @State private var leadLegKicks: Int
    @State private var backLegKicks: Int
    @State private var openingAttacks: Int
    @State private var counterAttacks: Int
    @State private var topTechnique1: String
    @State private var topTechnique2: String
    @State private var topTechnique3: String
    @State private var combinations: String
    @State private var offenceSeconds: Int
    @State private var defenceSeconds: Int

    // === Ratings ===
    @State private var ringControlRating: Int
    @State private var composureRating: Int
    @State private var scoreManagementRating: Int

    // === Mental (Pillar 5) ===
    @State private var preMatchNerves: Int
    @State private var interRoundRecovery: Int
    @State private var responseToLosingPoint: Int
    @State private var responseToWinningPoint: Int

    // === Notes ===
    @State private var coachNotes: String

    @State private var saving = false

    public init(athlete: Athlete, editing: Match? = nil, onSaved: @escaping (Match) -> Void) {
        self.athlete = athlete
        self.editing = editing
        self.onSaved = onSaved
        let m = editing
        _date = State(initialValue: m?.date ?? Date())
        _context = State(initialValue: m?.context ?? .training)
        _tournamentName = State(initialValue: m?.tournamentName ?? "")
        _opponentName = State(initialValue: m?.opponentName ?? "")
        _matchType = State(initialValue: m?.matchType ?? .bestOf3)
        _weightClassKg = State(initialValue: m?.weightClassKg ?? athlete.weightKg)
        _outcome = State(initialValue: m?.effectiveOutcome ?? .win)
        _winMethod = State(initialValue: m?.winMethod ?? .points)
        _rounds = State(initialValue: m?.rounds ?? 3)
        _roundsWon = State(initialValue: m?.roundsWon ?? 0)
        _roundsLost = State(initialValue: m?.roundsLost ?? 0)
        _ourScore = State(initialValue: m?.ourScore ?? 0)
        _opponentScore = State(initialValue: m?.opponentScore ?? 0)
        _medal = State(initialValue: m?.medal ?? .none)
        _kicksAttempted = State(initialValue: m?.kicksAttempted ?? 0)
        _kicksLanded = State(initialValue: m?.kicksLanded ?? 0)
        _punchesAttempted = State(initialValue: m?.punchesAttempted ?? 0)
        _punchesLanded = State(initialValue: m?.punchesLanded ?? 0)
        _ourPunchPoints = State(initialValue: m?.ourPunchPoints ?? 0)
        _ourBodyKickPoints = State(initialValue: m?.ourBodyKickPoints ?? 0)
        _ourHeadKickPoints = State(initialValue: m?.ourHeadKickPoints ?? 0)
        _ourSpinningBodyPoints = State(initialValue: m?.ourSpinningBodyPoints ?? 0)
        _ourSpinningHeadPoints = State(initialValue: m?.ourSpinningHeadPoints ?? 0)
        _oppPunchPoints = State(initialValue: m?.oppPunchPoints ?? 0)
        _oppBodyKickPoints = State(initialValue: m?.oppBodyKickPoints ?? 0)
        _oppHeadKickPoints = State(initialValue: m?.oppHeadKickPoints ?? 0)
        _oppSpinningBodyPoints = State(initialValue: m?.oppSpinningBodyPoints ?? 0)
        _oppSpinningHeadPoints = State(initialValue: m?.oppSpinningHeadPoints ?? 0)
        _penaltiesGiven = State(initialValue: m?.penaltiesGiven ?? 0)
        _penaltiesReceived = State(initialValue: m?.penaltiesReceived ?? 0)
        _knockdownsScored = State(initialValue: m?.knockdownsScored ?? 0)
        _knockdownsReceived = State(initialValue: m?.knockdownsReceived ?? 0)
        _leadLegKicks = State(initialValue: m?.leadLegKicks ?? 0)
        _backLegKicks = State(initialValue: m?.backLegKicks ?? 0)
        _openingAttacks = State(initialValue: m?.openingAttacks ?? 0)
        _counterAttacks = State(initialValue: m?.counterAttacks ?? 0)
        let tops = m?.topTechniques ?? []
        _topTechnique1 = State(initialValue: tops.indices.contains(0) ? tops[0] : "")
        _topTechnique2 = State(initialValue: tops.indices.contains(1) ? tops[1] : "")
        _topTechnique3 = State(initialValue: tops.indices.contains(2) ? tops[2] : "")
        _combinations = State(initialValue: m?.combinations ?? "")
        _offenceSeconds = State(initialValue: m?.offenceSeconds ?? 0)
        _defenceSeconds = State(initialValue: m?.defenceSeconds ?? 0)
        _ringControlRating = State(initialValue: m?.ringControlRating ?? 3)
        _composureRating = State(initialValue: m?.composureRating ?? 3)
        _scoreManagementRating = State(initialValue: m?.scoreManagementRating ?? 3)
        _preMatchNerves = State(initialValue: m?.preMatchNerves ?? 3)
        _interRoundRecovery = State(initialValue: m?.interRoundRecovery ?? 3)
        _responseToLosingPoint = State(initialValue: m?.responseToLosingPoint ?? 3)
        _responseToWinningPoint = State(initialValue: m?.responseToWinningPoint ?? 3)
        _coachNotes = State(initialValue: m?.coachNotes ?? "")
    }

    public var body: some View {
        Form {
            generalSection
            resultSection
            aggregateSection
            pointsForSection
            pointsAgainstSection
            disciplineSection
            tacticalSection
            ratingsSection
            mentalSection
            notesSection
        }
        .navigationTitle(Text(editing == nil ? "sparring.add" : "sparring.edit"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
                .bareToolbarButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task { await save() }
                } label: {
                    if saving { ProgressView() } else { Text("action.save") }
                }
                .disabled(saving)
                .bareToolbarButton()
            }
        }
    }

    // MARK: - Sections

    private var generalSection: some View {
        Section {
            DatePicker("sparring.date", selection: $date, displayedComponents: .date)
            Picker("sparring.context", selection: $context) {
                ForEach(SparringContext.allCases, id: \.self) { c in
                    Text(localizedKey: c.labelKey).tag(c)
                }
            }
            .pickerStyle(.segmented)
            if context == .competition {
                TextField("sparring.tournament_name", text: $tournamentName)
            }
            TextField("sparring.opponent_name", text: $opponentName)
            Picker("sparring.match_type", selection: $matchType) {
                ForEach(MatchType.allCases, id: \.self) { t in
                    Text(localizedKey: t.labelKey).tag(t)
                }
            }
            HStack {
                Text("sparring.weight_class")
                Spacer()
                Text(verbatim: String(format: "%.1f kg", weightClassKg))
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Slider(value: $weightClassKg, in: 15...140, step: 0.5)
        } header: {
            Text("sparring.section.general")
        }
    }

    private var resultSection: some View {
        Section {
            Picker("sparring.outcome", selection: $outcome) {
                ForEach(MatchOutcome.allCases, id: \.self) { o in
                    Text(localizedKey: o.labelKey).tag(o)
                }
            }
            .pickerStyle(.segmented)
            Picker("sparring.win_method", selection: $winMethod) {
                ForEach(WinMethod.allCases, id: \.self) { m in
                    Text(localizedKey: m.labelKey).tag(m)
                }
            }
            stepperRow("sparring.rounds_total", value: $rounds, range: 1...7)
            stepperRow("sparring.rounds_won", value: $roundsWon, range: 0...rounds)
            stepperRow("sparring.rounds_lost", value: $roundsLost, range: 0...rounds)
            stepperRow("sparring.our_score", value: $ourScore, range: 0...100)
            stepperRow("sparring.opponent_score", value: $opponentScore, range: 0...100)
            if context == .competition {
                Picker("sparring.medal", selection: $medal) {
                    ForEach(MedalType.allCases, id: \.self) { m in
                        Text(localizedKey: m.labelKey).tag(m)
                    }
                }
            }
        } header: {
            Text("sparring.section.result")
        }
    }

    private var aggregateSection: some View {
        Section {
            stepperRow("sparring.kicks_attempted", value: $kicksAttempted, range: 0...300)
            stepperRow("sparring.kicks_landed", value: $kicksLanded, range: 0...kicksAttempted)
            accuracyRow("sparring.kick_accuracy", attempted: kicksAttempted, landed: kicksLanded)
            stepperRow("sparring.punches_attempted", value: $punchesAttempted, range: 0...300)
            stepperRow("sparring.punches_landed", value: $punchesLanded, range: 0...punchesAttempted)
            accuracyRow("sparring.punch_accuracy", attempted: punchesAttempted, landed: punchesLanded)
        } header: {
            Text("sparring.section.aggregate")
        }
    }

    private var pointsForSection: some View {
        Section {
            stepperRow("sparring.points.punch_1", value: $ourPunchPoints, range: 0...100)
            stepperRow("sparring.points.body_kick_2", value: $ourBodyKickPoints, range: 0...50)
            stepperRow("sparring.points.head_kick_3", value: $ourHeadKickPoints, range: 0...30)
            stepperRow("sparring.points.spinning_body_4", value: $ourSpinningBodyPoints, range: 0...30)
            stepperRow("sparring.points.spinning_head_5", value: $ourSpinningHeadPoints, range: 0...20)
        } header: {
            Text("sparring.section.points_for")
        } footer: {
            let total = ourPunchPoints + ourBodyKickPoints * 2 + ourHeadKickPoints * 3
                + ourSpinningBodyPoints * 4 + ourSpinningHeadPoints * 5
            Text(verbatim: String(format: NSLocalizedString("sparring.points_subtotal", comment: ""), total))
                .scaledFont(.caption2, monospacedDigit: true)
                .foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private var pointsAgainstSection: some View {
        Section {
            stepperRow("sparring.points.punch_1", value: $oppPunchPoints, range: 0...100)
            stepperRow("sparring.points.body_kick_2", value: $oppBodyKickPoints, range: 0...50)
            stepperRow("sparring.points.head_kick_3", value: $oppHeadKickPoints, range: 0...30)
            stepperRow("sparring.points.spinning_body_4", value: $oppSpinningBodyPoints, range: 0...30)
            stepperRow("sparring.points.spinning_head_5", value: $oppSpinningHeadPoints, range: 0...20)
        } header: {
            Text("sparring.section.points_against")
        } footer: {
            let total = oppPunchPoints + oppBodyKickPoints * 2 + oppHeadKickPoints * 3
                + oppSpinningBodyPoints * 4 + oppSpinningHeadPoints * 5
            Text(verbatim: String(format: NSLocalizedString("sparring.points_subtotal", comment: ""), total))
                .scaledFont(.caption2, monospacedDigit: true)
                .foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private var disciplineSection: some View {
        Section {
            stepperRow("sparring.penalties_given", value: $penaltiesGiven, range: 0...20)
            stepperRow("sparring.penalties_received", value: $penaltiesReceived, range: 0...20)
            stepperRow("sparring.knockdowns_scored", value: $knockdownsScored, range: 0...10)
            stepperRow("sparring.knockdowns_received", value: $knockdownsReceived, range: 0...10)
        } header: {
            Text("sparring.section.discipline")
        }
    }

    private var tacticalSection: some View {
        Section {
            stepperRow("sparring.lead_leg_kicks", value: $leadLegKicks, range: 0...200)
            stepperRow("sparring.back_leg_kicks", value: $backLegKicks, range: 0...200)
            stepperRow("sparring.opening_attacks", value: $openingAttacks, range: 0...100)
            stepperRow("sparring.counter_attacks", value: $counterAttacks, range: 0...100)
            VStack(alignment: .leading, spacing: 6) {
                Text("sparring.top_techniques").scaledFont(.subheadline)
                TextField("sparring.technique_1", text: $topTechnique1)
                TextField("sparring.technique_2", text: $topTechnique2)
                TextField("sparring.technique_3", text: $topTechnique3)
            }
            TextField("sparring.combinations", text: $combinations, axis: .vertical)
                .lineLimit(1...3)
            stepperRow("sparring.offence_seconds", value: $offenceSeconds, range: 0...600)
            stepperRow("sparring.defence_seconds", value: $defenceSeconds, range: 0...600)
        } header: {
            Text("sparring.section.tactical")
        }
    }

    private var ratingsSection: some View {
        Section {
            ratingRow("sparring.ring_control", value: $ringControlRating)
            ratingRow("sparring.composure", value: $composureRating)
            ratingRow("sparring.score_management", value: $scoreManagementRating)
        } header: {
            Text("sparring.section.ratings")
        } footer: {
            Text("sparring.ratings_help").scaledFont(.caption2).foregroundStyle(.secondary)
        }
    }

    private var mentalSection: some View {
        Section {
            ratingRow("sparring.pre_match_nerves", value: $preMatchNerves)
            ratingRow("sparring.inter_round_recovery", value: $interRoundRecovery)
            ratingRow("sparring.response_to_losing_point", value: $responseToLosingPoint)
            ratingRow("sparring.response_to_winning_point", value: $responseToWinningPoint)
        } header: {
            Text("sparring.section.mental")
        }
    }

    private var notesSection: some View {
        Section {
            TextField("sparring.notes", text: $coachNotes, axis: .vertical)
                .lineLimit(3...8)
        } header: {
            Text("sparring.section.notes")
        }
    }

    // MARK: - Helpers

    private func stepperRow(_ titleKey: LocalizedStringKey, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(titleKey)
                Spacer()
                Text(verbatim: "\(value.wrappedValue)")
                    .scaledFont(.callout, monospacedDigit: true)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
    }

    private func accuracyRow(_ titleKey: LocalizedStringKey, attempted: Int, landed: Int) -> some View {
        HStack {
            Text(titleKey).scaledFont(.caption).foregroundStyle(.secondary)
            Spacer()
            if attempted > 0 {
                let pct = Double(landed) / Double(attempted) * 100
                Text(verbatim: String(format: "%.0f%%", pct))
                    .scaledFont(.callout, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(.tint)
                    .environment(\.layoutDirection, .leftToRight)
            } else {
                Text(verbatim: "—").foregroundStyle(.tertiary)
            }
        }
    }

    private func ratingRow(_ titleKey: LocalizedStringKey, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(titleKey).scaledFont(.subheadline)
                Spacer()
                Text(verbatim: "\(value.wrappedValue) / 5")
                    .scaledFont(.callout, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(.tint)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0.rounded()) }
                ),
                in: 1...5,
                step: 1
            )
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        let tops = [topTechnique1, topTechnique2, topTechnique3]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let resolvedTournamentName: String = {
            if !tournamentName.isEmpty { return tournamentName }
            switch context {
            case .training: return String(localized: "sparring.context.training")
            case .friendly: return String(localized: "sparring.context.friendly")
            case .competition: return String(localized: "sparring.context.competition")
            }
        }()
        let won = outcome == .win
        let m = Match(
            id: editing?.id ?? UUID(),
            tournamentName: resolvedTournamentName,
            tournamentID: editing?.tournamentID,
            date: date,
            ourAthleteID: athlete.id,
            opponentAthleteID: editing?.opponentAthleteID,
            opponentName: opponentName.isEmpty ? nil : opponentName,
            weightClassKg: weightClassKg,
            rounds: rounds,
            ourScore: ourScore,
            opponentScore: opponentScore,
            won: won,
            medal: context == .competition ? medal : .none,
            events: editing?.events ?? [],
            context: context,
            matchType: matchType,
            winMethod: outcome == .draw ? nil : winMethod,
            outcome: outcome,
            roundsWon: roundsWon > 0 ? roundsWon : nil,
            roundsLost: roundsLost > 0 ? roundsLost : nil,
            kicksAttempted: kicksAttempted > 0 ? kicksAttempted : nil,
            kicksLanded: kicksAttempted > 0 ? kicksLanded : nil,
            punchesAttempted: punchesAttempted > 0 ? punchesAttempted : nil,
            punchesLanded: punchesAttempted > 0 ? punchesLanded : nil,
            ourPunchPoints: nilIfZero(ourPunchPoints),
            ourBodyKickPoints: nilIfZero(ourBodyKickPoints),
            ourHeadKickPoints: nilIfZero(ourHeadKickPoints),
            ourSpinningBodyPoints: nilIfZero(ourSpinningBodyPoints),
            ourSpinningHeadPoints: nilIfZero(ourSpinningHeadPoints),
            oppPunchPoints: nilIfZero(oppPunchPoints),
            oppBodyKickPoints: nilIfZero(oppBodyKickPoints),
            oppHeadKickPoints: nilIfZero(oppHeadKickPoints),
            oppSpinningBodyPoints: nilIfZero(oppSpinningBodyPoints),
            oppSpinningHeadPoints: nilIfZero(oppSpinningHeadPoints),
            penaltiesGiven: nilIfZero(penaltiesGiven),
            penaltiesReceived: nilIfZero(penaltiesReceived),
            knockdownsScored: nilIfZero(knockdownsScored),
            knockdownsReceived: nilIfZero(knockdownsReceived),
            leadLegKicks: nilIfZero(leadLegKicks),
            backLegKicks: nilIfZero(backLegKicks),
            openingAttacks: nilIfZero(openingAttacks),
            counterAttacks: nilIfZero(counterAttacks),
            topTechniques: tops.isEmpty ? nil : tops,
            combinations: combinations.isEmpty ? nil : combinations,
            offenceSeconds: nilIfZero(offenceSeconds),
            defenceSeconds: nilIfZero(defenceSeconds),
            ringControlRating: ringControlRating,
            composureRating: composureRating,
            scoreManagementRating: scoreManagementRating,
            coachNotes: coachNotes.isEmpty ? nil : coachNotes,
            preMatchNerves: preMatchNerves,
            interRoundRecovery: interRoundRecovery,
            responseToLosingPoint: responseToLosingPoint,
            responseToWinningPoint: responseToWinningPoint
        )
        do {
            try await session.repository.upsertMatch(m)
            onSaved(m)
            dismiss()
        } catch {
            print("SparringLogEditorView.save:", error)
        }
    }

    private func nilIfZero(_ v: Int) -> Int? { v == 0 ? nil : v }
}

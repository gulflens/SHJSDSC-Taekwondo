import SwiftUI

public struct LiveMatchTaggerView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let athlete: Athlete
    public let opponentName: String
    public let weightCategory: WeightCategory
    public let tournamentID: EntityID?
    public let bracketMatchID: EntityID?
    public let onFinish: (Match) -> Void

    @State private var store: LiveMatchStore?
    @State private var tournament: Tournament?
    @State private var showSummary = false
    @State private var finalMatch: Match?

    public init(
        athlete: Athlete,
        opponentName: String,
        weightCategory: WeightCategory,
        tournamentID: EntityID?,
        bracketMatchID: EntityID? = nil,
        onFinish: @escaping (Match) -> Void
    ) {
        self.athlete = athlete
        self.opponentName = opponentName
        self.weightCategory = weightCategory
        self.tournamentID = tournamentID
        self.bracketMatchID = bracketMatchID
        self.onFinish = onFinish
    }

    public var body: some View {
        Group {
            if let store, store.match != nil {
                content(store: store)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(Text("match.live"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
            }
        }
        .task {
            if store == nil {
                store = LiveMatchStore(repository: session.repository)
            }
            if let id = tournamentID {
                tournament = try? await session.repository.tournament(id: id)
            }
            if store?.match == nil {
                await store?.startMatch(
                    athlete: athlete,
                    opponentName: opponentName,
                    weightCategory: weightCategory,
                    tournament: tournament
                )
            }
        }
        .sheet(isPresented: $showSummary) {
            if let m = finalMatch {
                NavigationStack {
                    MatchSummaryView(match: m, onClose: {
                        showSummary = false
                        dismiss()
                    })
                }
            }
        }
    }

    @ViewBuilder
    private func content(store: LiveMatchStore) -> some View {
        VStack(spacing: 0) {
            topBar(store: store)
            Divider()
            HStack(spacing: 8) {
                scorePanel(store: store, side: .chung, name: athlete.fullName, nameAr: athlete.fullNameAr, color: .blue)
                scorePanel(store: store, side: .hong, name: opponentName, nameAr: nil, color: .red)
            }
            .padding(8)
            Divider()
            eventLog(store: store)
                .frame(maxHeight: 140)
        }
        .overlay(alignment: .center) {
            if let winner = store.winner, !store.isFinalized {
                winnerOverlay(side: winner, store: store)
            }
        }
    }

    private func topBar(store: LiveMatchStore) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: tournament?.name ?? String(localized: "match.practice"))
                    .font(.subheadline.bold())
                Text(verbatim: weightCategory.shortLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("match.round").font(.caption2).foregroundStyle(.secondary)
                Text(verbatim: "\(store.currentRound) / \(store.match?.rounds ?? 3)")
                    .font(.title3.bold().monospacedDigit())
                    .environment(\.layoutDirection, .leftToRight)
            }
            VStack(spacing: 2) {
                Text("match.time_remaining").font(.caption2).foregroundStyle(.secondary)
                Text(verbatim: store.formattedTime)
                    .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(store.isTimerRunning ? Color.primary : Color.orange)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Spacer()
            Button {
                Task { await store.endRound() }
            } label: {
                Label("match.end_round", systemImage: "stop.fill")
            }
            .buttonStyle(.bordered)
            .disabled(store.isFinalized)
        }
        .padding(12)
    }

    private func scorePanel(store: LiveMatchStore, side: MatchSide, name: String, nameAr: String?, color: Color) -> some View {
        VStack(spacing: 8) {
            VStack(spacing: 2) {
                Text(side == .chung ? "match.chung" : "match.hong")
                    .font(.caption.bold())
                    .foregroundStyle(color)
                Text(verbatim: name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                if let nameAr {
                    Text(verbatim: nameAr)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Text(verbatim: "\(side == .chung ? store.match?.ourScore ?? 0 : store.match?.opponentScore ?? 0)")
                .font(.system(size: 64, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(color)
                .environment(\.layoutDirection, .leftToRight)
            actionGrid(store: store, side: side, color: color)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.4), lineWidth: 1)
        )
    }

    private func actionGrid(store: LiveMatchStore, side: MatchSide, color: Color) -> some View {
        let actions: [ScoreAction] = [.headKick, .bodyKick, .turnBodyKick, .turnHeadKick, .punch, .penalty]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(actions, id: \.self) { action in
                Button {
                    Task { await store.recordEvent(side: side, action: action) }
                } label: {
                    VStack(spacing: 2) {
                        Text(LocalizedStringKey(actionLabelKey(action)))
                            .font(.caption.bold())
                            .lineLimit(1)
                        Text(verbatim: "+\(action.points)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(color.opacity(0.18))
                    .foregroundStyle(color)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(store.isFinalized)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in store.undoLast(side: side) }
                )
            }
        }
    }

    private func actionLabelKey(_ action: ScoreAction) -> String {
        switch action {
        case .headKick: "match.action.head_kick"
        case .bodyKick: "match.action.body_kick"
        case .turnBodyKick: "match.action.turn_body"
        case .turnHeadKick: "match.action.turn_head"
        case .punch: "match.action.punch"
        case .penalty: "match.action.penalty"
        }
    }

    private func eventLog(store: LiveMatchStore) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("match.event_log").font(.caption.bold()).padding(.horizontal, 12).padding(.top, 8)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    let events = (store.match?.events ?? []).suffix(10).reversed()
                    ForEach(Array(events), id: \.id) { e in
                        HStack(spacing: 6) {
                            Text(verbatim: "R\(e.round)").font(.caption2.monospacedDigit())
                                .environment(\.layoutDirection, .leftToRight)
                            Text(verbatim: String(format: "%02d:%02d", e.atSecond / 60, e.atSecond % 60))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .environment(\.layoutDirection, .leftToRight)
                            Text(e.side == .chung ? "match.chung" : "match.hong")
                                .font(.caption2)
                                .foregroundStyle(e.side == .chung ? .blue : .red)
                            Text(LocalizedStringKey(actionLabelKey(e.action)))
                                .font(.caption2)
                            Spacer()
                            Text(verbatim: "+\(e.action.points)").font(.caption2.monospacedDigit())
                                .environment(\.layoutDirection, .leftToRight)
                        }
                        .padding(.horizontal, 12)
                    }
                }
            }
        }
    }

    private func winnerOverlay(side: MatchSide, store: LiveMatchStore) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)
            Text("match.winner").font(.title3.bold())
            Text(verbatim: side == .chung ? athlete.fullName : opponentName)
                .font(.title.bold())
            HStack(spacing: 12) {
                if (store.match?.rounds ?? 3) > store.currentRound {
                    Button {
                        store.startNextRound()
                    } label: {
                        Label("match.start_round", systemImage: "play.fill")
                    }
                    .buttonStyle(.bordered)
                }
                Button {
                    Task { await confirm(store: store) }
                } label: {
                    Label("match.confirm", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .padding()
    }

    private func confirm(store: LiveMatchStore) async {
        let medal: MedalType = store.winner == .chung ? .gold : .none
        let m = await store.finalize(medal: medal)
        if let m {
            finalMatch = m
            onFinish(m)
            showSummary = true
        }
    }
}

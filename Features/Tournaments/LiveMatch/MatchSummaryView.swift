import SwiftUI

public struct MatchSummaryView: View {
    @Environment(AppSession.self) private var session

    public let match: Match
    public let onClose: () -> Void

    @State private var ourAthlete: Athlete?

    public init(match: Match, onClose: @escaping () -> Void) {
        self.match = match
        self.onClose = onClose
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard
                breakdownCard
                eventsTimeline
            }
            .padding()
        }
        .navigationTitle(Text("match.summary"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: shareSummary) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { onClose() }
            }
        }
        #else
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { onClose() }
            }
        }
        #endif
        .task { await load() }
    }

    private var summaryCard: some View {
        VStack(spacing: 8) {
            Text(verbatim: match.tournamentName).font(.headline)
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("match.chung").font(.caption).foregroundStyle(.blue)
                    Text(verbatim: ourAthlete?.fullName ?? "—").font(.subheadline.bold())
                    Text(verbatim: "\(match.ourScore)")
                        .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.blue)
                        .environment(\.layoutDirection, .leftToRight)
                }
                Text(verbatim: "—").font(.title2).foregroundStyle(.secondary)
                VStack(spacing: 2) {
                    Text("match.hong").font(.caption).foregroundStyle(.red)
                    Text(verbatim: match.opponentName ?? "—").font(.subheadline.bold())
                    Text(verbatim: "\(match.opponentScore)")
                        .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.red)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
            HStack {
                if match.medal != .none {
                    Image(systemName: "medal.fill").foregroundStyle(.yellow)
                    Text(LocalizedStringKey(match.medal.labelKey))
                        .font(.subheadline.bold())
                }
                Spacer()
                Text(match.date, style: .date).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var breakdownCard: some View {
        let chungEvents = match.events.filter { $0.side == .chung }
        let hongEvents = match.events.filter { $0.side == .hong }
        return VStack(alignment: .leading, spacing: 6) {
            Text("match.summary").font(.headline)
            HStack(alignment: .top) {
                breakdownColumn(label: "match.chung", events: chungEvents, color: .blue)
                breakdownColumn(label: "match.hong", events: hongEvents, color: .red)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func breakdownColumn(label: LocalizedStringKey, events: [ScoreEvent], color: Color) -> some View {
        let counts = Dictionary(grouping: events, by: { $0.action }).mapValues { $0.count }
        let actions: [ScoreAction] = [.headKick, .bodyKick, .turnBodyKick, .turnHeadKick, .punch, .penalty]
        return VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.bold()).foregroundStyle(color)
            ForEach(actions, id: \.self) { action in
                let count = counts[action] ?? 0
                if count > 0 {
                    HStack {
                        Text(LocalizedStringKey(actionLabel(action)))
                            .font(.caption)
                        Spacer()
                        Text(verbatim: "\(count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var eventsTimeline: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("match.event_log").font(.headline)
            if match.events.isEmpty {
                Text("empty.no_data").foregroundStyle(.secondary)
            } else {
                ForEach(match.events, id: \.id) { e in
                    HStack(spacing: 8) {
                        Text(verbatim: "R\(e.round)").font(.caption2.monospacedDigit())
                            .environment(\.layoutDirection, .leftToRight)
                        Text(verbatim: String(format: "%02d:%02d", e.atSecond / 60, e.atSecond % 60))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                        Circle().fill(e.side == .chung ? Color.blue : Color.red).frame(width: 6, height: 6)
                        Text(LocalizedStringKey(actionLabel(e.action)))
                            .font(.caption)
                        Spacer()
                        Text(verbatim: "+\(e.action.points)").font(.caption.monospacedDigit())
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
            }
        }
    }

    private func actionLabel(_ action: ScoreAction) -> String {
        switch action {
        case .headKick: "match.action.head_kick"
        case .bodyKick: "match.action.body_kick"
        case .turnBodyKick: "match.action.turn_body"
        case .turnHeadKick: "match.action.turn_head"
        case .punch: "match.action.punch"
        case .penalty: "match.action.penalty"
        }
    }

    private var shareSummary: String {
        var lines: [String] = []
        lines.append(match.tournamentName)
        lines.append("\(ourAthlete?.fullName ?? "—") \(match.ourScore) — \(match.opponentScore) \(match.opponentName ?? "—")")
        if match.won { lines.append("Winner: \(ourAthlete?.fullName ?? "")") }
        return lines.joined(separator: "\n")
    }

    private func load() async {
        do {
            ourAthlete = try await session.repository.athlete(id: match.ourAthleteID)
        } catch {
            print("MatchSummaryView.load:", error)
        }
    }
}

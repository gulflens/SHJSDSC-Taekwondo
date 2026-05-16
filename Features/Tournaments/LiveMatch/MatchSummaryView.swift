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
                .bareToolbarButton()
            }
        }
        #else
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { onClose() }
                .bareToolbarButton()
            }
        }
        #endif
        .task { await load() }
    }

    private var summaryCard: some View {
        VStack(spacing: 8) {
            Text(verbatim: match.tournamentName).scaledFont(.headline)
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("match.chung").scaledFont(.caption).foregroundStyle(.blue)
                    Text(verbatim: ourAthlete?.fullName ?? "—").scaledFont(.subheadline, weight: .bold)
                    Text(verbatim: "\(match.ourScore)")
                        .scaledFont(size: 44, weight: .bold, design: .rounded, monospacedDigit: true)
                        .foregroundStyle(.blue)
                        .environment(\.layoutDirection, .leftToRight)
                }
                Text(verbatim: "—").scaledFont(.title2).foregroundStyle(.secondary)
                VStack(spacing: 2) {
                    Text("match.hong").scaledFont(.caption).foregroundStyle(.red)
                    Text(verbatim: match.opponentName ?? "—").scaledFont(.subheadline, weight: .bold)
                    Text(verbatim: "\(match.opponentScore)")
                        .scaledFont(size: 44, weight: .bold, design: .rounded, monospacedDigit: true)
                        .foregroundStyle(.red)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
            HStack {
                if match.medal != .none {
                    Image(systemName: "medal.fill").foregroundStyle(.yellow)
                    Text(localizedKey: match.medal.labelKey)
                        .scaledFont(.subheadline, weight: .bold)
                }
                Spacer()
                Text(match.date, style: .date).scaledFont(.caption).foregroundStyle(.secondary)
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
            Text("match.summary").scaledFont(.headline)
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
            Text(label).scaledFont(.caption, weight: .bold).foregroundStyle(color)
            ForEach(actions, id: \.self) { action in
                let count = counts[action] ?? 0
                if count > 0 {
                    HStack {
                        Text(localizedKey: actionLabel(action))
                            .scaledFont(.caption)
                        Spacer()
                        Text(verbatim: "\(count)")
                            .scaledFont(.caption, monospacedDigit: true)
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
            Text("match.event_log").scaledFont(.headline)
            if match.events.isEmpty {
                Text("empty.no_data").foregroundStyle(.secondary)
            } else {
                ForEach(match.events, id: \.id) { e in
                    HStack(spacing: 8) {
                        Text(verbatim: "R\(e.round)").scaledFont(.caption2, monospacedDigit: true)
                            .environment(\.layoutDirection, .leftToRight)
                        Text(verbatim: String(format: "%02d:%02d", e.atSecond / 60, e.atSecond % 60))
                            .scaledFont(.caption2, monospacedDigit: true)
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                        Circle().fill(e.side == .chung ? Color.blue : Color.red).frame(width: 6, height: 6)
                        Text(localizedKey: actionLabel(e.action))
                            .scaledFont(.caption)
                        Spacer()
                        Text(verbatim: "+\(e.action.points)").scaledFont(.caption, monospacedDigit: true)
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

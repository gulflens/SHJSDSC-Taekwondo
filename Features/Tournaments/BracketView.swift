import SwiftUI

public struct BracketView: View {
    @Environment(AppSession.self) private var session

    public let bracketID: EntityID

    @State private var matches: [BracketMatch] = []
    @State private var athleteLookup: [EntityID: Athlete] = [:]
    @State private var bracket: Bracket?
    @State private var taggingMatch: BracketMatch?

    public init(bracketID: EntityID) { self.bracketID = bracketID }

    public var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 8) {
                if let bracket {
                    Text(verbatim: bracket.weightCategory.shortLabel).font(.headline).padding(.horizontal)
                }
                bracketDiagram
                    .padding()
            }
        }
        .navigationTitle(Text("tournament.bracket"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await load() }
        .sheet(item: $taggingMatch) { bm in
            NavigationStack {
                if let aA = bm.athleteAID, let athleteA = athleteLookup[aA] {
                    LiveMatchTaggerView(
                        athlete: athleteA,
                        opponentName: bm.athleteBID.flatMap { athleteLookup[$0]?.fullName } ?? "Opponent",
                        weightCategory: bracket?.weightCategory ?? .juniorsUnder63,
                        tournamentID: bracket?.tournamentID,
                        bracketMatchID: bm.id,
                        onFinish: { _ in Task { await load() } }
                    )
                } else {
                    Text("empty.no_data").padding()
                }
            }
        }
    }

    private var bracketDiagram: some View {
        let rounds = Dictionary(grouping: matches, by: { $0.round })
            .sorted { $0.key < $1.key }
        return HStack(alignment: .top, spacing: 24) {
            ForEach(rounds, id: \.key) { round, roundMatches in
                VStack(spacing: spacing(forRound: round)) {
                    ForEach(roundMatches.sorted { $0.position < $1.position }) { bm in
                        matchCard(bm)
                    }
                }
            }
        }
    }

    private func spacing(forRound round: Int) -> CGFloat {
        // Doubling spacing per round so matches line up visually
        return 12 * pow(2, Double(round - 1))
    }

    private func matchCard(_ bm: BracketMatch) -> some View {
        let aName = bm.athleteAID.flatMap { athleteLookup[$0]?.fullName }
        let bName = bm.athleteBID.flatMap { athleteLookup[$0]?.fullName }
        let isClickable = bm.athleteAID != nil && bm.athleteBID != nil && bm.matchID == nil
        return VStack(alignment: .leading, spacing: 4) {
            participantRow(name: aName, isWinner: bm.winnerID == bm.athleteAID)
            Divider()
            participantRow(name: bName, isWinner: bm.winnerID == bm.athleteBID)
        }
        .padding(8)
        .frame(width: 180)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(bm.matchID != nil ? Color.green.opacity(0.6) : Color.clear, lineWidth: 1)
        )
        .onTapGesture {
            if isClickable { taggingMatch = bm }
        }
    }

    private func participantRow(name: String?, isWinner: Bool) -> some View {
        HStack {
            Text(verbatim: name ?? "—")
                .font(.caption)
                .foregroundStyle(name == nil ? .secondary : .primary)
                .lineLimit(1)
            Spacer()
            if isWinner {
                Image(systemName: "trophy.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
        }
    }

    private func load() async {
        do {
            matches = try await session.repository.bracketMatches(bracketID: bracketID)
            // Find owning bracket
            let allTournaments = try await session.repository.tournaments()
            for t in allTournaments {
                let bs = try await session.repository.brackets(tournamentID: t.id)
                if let b = bs.first(where: { $0.id == bracketID }) {
                    bracket = b
                    break
                }
            }
            let athleteIDs = Set(matches.flatMap { [$0.athleteAID, $0.athleteBID].compactMap { $0 } })
            var lookup: [EntityID: Athlete] = [:]
            for id in athleteIDs {
                if let a = try await session.repository.athlete(id: id) { lookup[id] = a }
            }
            athleteLookup = lookup
        } catch {
            print("BracketView.load:", error)
        }
    }
}

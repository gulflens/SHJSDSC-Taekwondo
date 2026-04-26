import SwiftUI

public struct GradingSessionView: View {
    @Environment(AppSession.self) private var session

    public let sessionID: EntityID

    @State private var gradingSession: GradingSession?
    @State private var candidates: [Athlete] = []
    @State private var scoresByAthlete: [EntityID: GradingScore] = [:]
    @State private var branch: Branch?

    public init(sessionID: EntityID) { self.sessionID = sessionID }

    public var body: some View {
        Group {
            if let g = gradingSession {
                content(session: g)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(Text("grading.session"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await load() }
    }

    @ViewBuilder
    private func content(session g: GradingSession) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(g.scheduledAt, style: .date).font(.subheadline.bold())
                    if let branch {
                        Text(verbatim: branch.name).font(.caption).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                        Text(verbatim: "\(scoresByAthlete.count) / \(g.candidateAthleteIDs.count)")
                            .font(.caption.monospacedDigit())
                            .environment(\.layoutDirection, .leftToRight)
                        Text("grading.scored").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section(header: Text("grading.candidates")) {
                if candidates.isEmpty {
                    Text("empty.no_athletes_flagged").foregroundStyle(.secondary)
                } else {
                    ForEach(candidates) { a in
                        let existing = scoresByAthlete[a.id]
                        NavigationLink(destination: GradingScoreEntryView(
                            sessionID: sessionID,
                            athlete: a,
                            existing: existing,
                            onSaved: { Task { await load() } }
                        )) {
                            candidateRow(athlete: a, score: existing)
                        }
                    }
                }
            }
        }
    }

    private func candidateRow(athlete a: Athlete, score: GradingScore?) -> some View {
        HStack(spacing: 10) {
            Avatar(seed: a.avatarSeed, label: a.initials, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: a.fullName)
                Text(LocalizedStringKey(a.currentBelt.label))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let score {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(verbatim: "\(score.total)")
                        .font(.callout.bold().monospacedDigit())
                        .environment(\.layoutDirection, .leftToRight)
                    Text(LocalizedStringKey(score.decision.labelKey))
                        .font(.caption2)
                        .foregroundStyle(decisionColor(score.decision))
                }
            } else {
                Image(systemName: "circle.dashed")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func decisionColor(_ d: GradingDecision) -> Color {
        switch d {
        case .pass: .green
        case .retry: .orange
        case .fail: .red
        }
    }

    private func load() async {
        do {
            gradingSession = try await session.repository.gradingSession(id: sessionID)
            guard let g = gradingSession else { return }
            branch = try await session.repository.branch(id: g.branchID)
            var cs: [Athlete] = []
            for id in g.candidateAthleteIDs {
                if let a = try await session.repository.athlete(id: id) { cs.append(a) }
            }
            candidates = cs
            let raw = try await session.repository.gradingScores(sessionID: sessionID)
            scoresByAthlete = Dictionary(uniqueKeysWithValues: raw.map { ($0.athleteID, $0) })
        } catch {
            print("GradingSessionView.load:", error)
        }
    }
}

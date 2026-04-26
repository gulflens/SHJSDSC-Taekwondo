import SwiftUI

public struct BranchHeatMapView: View {
    @Environment(AppSession.self) private var session
    @State private var rows: [BranchHeatRow] = []

    public init() {}

    public var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 12) {
                header
                ForEach(rows) { row in
                    HStack(spacing: 12) {
                        Text(verbatim: row.branch.name)
                            .font(.subheadline.bold())
                            .frame(width: 120, alignment: .leading)
                        ForEach(Array(row.dimensions.enumerated()), id: \.offset) { _, grade in
                            GradeBadge(grade: grade, size: 30)
                        }
                        GradeBadge(grade: row.composite, size: 36)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(Text("tab.branches"))
        .task { await load() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text(verbatim: " ").frame(width: 120)
            Text("dimension.competition").font(.caption2).frame(width: 30)
            Text("dimension.technical").font(.caption2).frame(width: 30)
            Text("dimension.physical").font(.caption2).frame(width: 30)
            Text("dimension.adherence").font(.caption2).frame(width: 30)
            Text("dimension.belt_progression").font(.caption2).frame(width: 30)
            Text("dimension.wellness").font(.caption2).frame(width: 30)
            Text("kpi.composite").font(.caption2).frame(width: 36)
        }
        .foregroundStyle(.secondary)
    }

    private func load() async {
        do {
            let branches = try await session.repository.branches()
            var out: [BranchHeatRow] = []
            for b in branches {
                let scores = try await session.repository.scores(branchID: b.id)
                guard !scores.isEmpty else {
                    out.append(BranchHeatRow(
                        id: b.id, branch: b,
                        dimensions: Array(repeating: .f, count: 6),
                        composite: .f
                    ))
                    continue
                }
                func avg(_ kp: KeyPath<PerformanceScore, Double>) -> Double {
                    scores.reduce(0.0) { $0 + $1[keyPath: kp] } / Double(scores.count)
                }
                let dims: [LetterGrade] = [
                    .from(score: avg(\.competition)),
                    .from(score: avg(\.technical)),
                    .from(score: avg(\.physical)),
                    .from(score: avg(\.adherence)),
                    .from(score: avg(\.beltProgression)),
                    .from(score: avg(\.wellness)),
                ]
                let comp = ScoreEngine.branchComposite(scores)
                out.append(BranchHeatRow(id: b.id, branch: b, dimensions: dims, composite: .from(score: comp)))
            }
            rows = out
        } catch {
            print("BranchHeatMapView.load:", error)
        }
    }
}

private struct BranchHeatRow: Identifiable {
    let id: EntityID
    let branch: Branch
    let dimensions: [LetterGrade]
    let composite: LetterGrade
}

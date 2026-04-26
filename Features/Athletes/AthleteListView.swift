import SwiftUI

public enum AthleteListScope: Sendable, Hashable {
    case all
    case byBranch(EntityID)
    case myAthletes(coachID: EntityID)
}

public struct AthleteListView: View {
    @Environment(AppSession.self) private var session
    @State private var store: AthletesStore?
    @State private var query: String = ""
    @State private var statusFilter: AthleteStatus?

    public let scope: AthleteListScope

    public init(scope: AthleteListScope) {
        self.scope = scope
    }

    public var body: some View {
        Group {
            if let store {
                content(store: store)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(Text("tab.athletes"))
        .task {
            if store == nil { store = AthletesStore(repository: session.repository) }
            guard let store else { return }
            switch scope {
            case .all: await store.loadAll()
            case .byBranch(let bid): await store.load(branchID: bid)
            case .myAthletes(let cid): await store.loadForCoach(cid)
            }
        }
    }

    @ViewBuilder
    private func content(store: AthletesStore) -> some View {
        let filtered = store.athletes.filter { athlete in
            (statusFilter == nil || athlete.status == statusFilter)
            && (query.isEmpty
                || athlete.fullName.localizedCaseInsensitiveContains(query)
                || athlete.fullNameAr.contains(query))
        }
        List {
            if filtered.isEmpty {
                Text("empty.search_no_results").foregroundStyle(.secondary)
            } else {
                ForEach(filtered) { a in
                    NavigationLink(destination: AthleteDetailView(athlete: a)) {
                        AthleteRow(athlete: a, score: store.scoreByAthlete[a.id])
                    }
                }
            }
        }
        .searchable(text: $query)
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("filter.all") { statusFilter = nil }
                    Divider()
                    ForEach(AthleteStatus.allCases, id: \.self) { st in
                        Button(LocalizedStringKey(st.labelKey)) { statusFilter = st }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel(Text("filter.title"))
            }
        }
    }
}

private struct AthleteRow: View {
    let athlete: Athlete
    let score: PerformanceScore?

    var body: some View {
        HStack(spacing: 12) {
            Avatar(seed: athlete.avatarSeed, label: athlete.initials)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: athlete.fullName)
                HStack(spacing: 6) {
                    Text(LocalizedStringKey(athlete.currentBelt.label))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(verbatim: "·").foregroundStyle(.secondary)
                    Text(LocalizedStringKey(athlete.ageGroup.labelKey))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            StatusPill(status: athlete.status)
            if let score {
                let weights: ScoreWeights = athlete.status == .competitionTeam
                    ? .competitionTeam
                    : (athlete.ageGroup == .cubs ? .cubs : .standard)
                GradeBadge(grade: ScoreEngine.grade(score, weights: weights), size: 28)
            }
        }
        .padding(.vertical, 4)
    }
}

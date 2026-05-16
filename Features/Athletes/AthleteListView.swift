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
    @State private var showingAdd = false
    @State private var showingImport = false

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
        VStack(spacing: 0) {
            AppSearchField(text: $query)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

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
        }
        .toolbar {
            #if os(iOS)
            let filterPlacement: ToolbarItemPlacement = .topBarTrailing
            #else
            let filterPlacement: ToolbarItemPlacement = .primaryAction
            #endif
            ToolbarItem(placement: filterPlacement) {
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
                .bareToolbarButton()
            }
            if let role = session.currentUser?.role,
               PermissionMatrix.allowed(role: role, permission: .editAthlete) {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("athlete.add"))
                    .bareToolbarButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingImport = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .accessibilityLabel(Text("athlete.import"))
                    .bareToolbarButton()
                }
            }
        }
        .navigationDestination(isPresented: $showingAdd) {
            AddAthleteView(initialBranchID: scopeBranchID()) { newAthlete in
                store.insertOrUpdate(newAthlete)
            }
        }
        .navigationDestination(isPresented: $showingImport) {
            AthleteImportView {
                Task {
                    switch scope {
                    case .all: await store.loadAll()
                    case .byBranch(let bid): await store.load(branchID: bid)
                    case .myAthletes(let cid): await store.loadForCoach(cid)
                    }
                }
            }
        }
    }

    private func scopeBranchID() -> EntityID? {
        if case .byBranch(let id) = scope { return id }
        return session.currentUser?.primaryBranchID
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
                    Text(localizedKey: athlete.currentBelt.label)
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                    Text(verbatim: "·").foregroundStyle(.secondary)
                    Text(localizedKey: athlete.ageGroup.labelKey)
                        .scaledFont(.caption)
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

import SwiftUI

/// Branch hub: an "Overview" tab that compares all branches at a glance,
/// followed by per-branch tabs in the requested order
/// (Al Rahmania → Al Nasserya → Al Nouf → Industrial 18). Selecting a branch
/// tab swaps the embedded `BranchProfileView` below it.
public struct BranchListView: View {
    @Environment(AppSession.self) private var session
    @State private var store: BranchesStore?
    @State private var mediaLookup: [EntityID: BranchMedia] = [:]
    @State private var hoursLookup: [EntityID: BranchHours] = [:]
    @State private var selectedTab: BranchTab = .overview
    @State private var manageTarget: EntityID?
    @State private var showingAdd = false

    private enum BranchTab: Hashable {
        case overview
        case branch(EntityID)
    }

    /// Display order requested for the segmented picker. Anything outside
    /// this list is appended after, sorted by name.
    private static let preferredOrder: [String] = [
        "Al Rahmania",
        "Al Nasserya",
        "Al Nouf",
        "Industrial 18"
    ]

    public init() {}

    public var body: some View {
        Group {
            if let store {
                content(store: store)
            } else {
                ProgressView()
            }
        }
        .toolbar {
            if let role = session.currentUser?.role,
               PermissionMatrix.allowed(role: role, permission: .editBranchProfile),
               case .branch(let id) = selectedTab {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        manageTarget = id
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel(Text("branch.edit"))
                    .bareToolbarButton()
                }
            }
            if let role = session.currentUser?.role,
               PermissionMatrix.allowed(role: role, permission: .editBranchProfile) {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("branch.add"))
                    .bareToolbarButton()
                }
            }
        }
        .navigationDestination(item: $manageTarget) { id in
            BranchEditView(branchID: id)
        }
        .navigationDestination(isPresented: $showingAdd) {
            AddBranchView { _ in
                Task {
                    await store?.loadAll()
                    await loadAuxiliary()
                }
            }
        }
        .task {
            if store == nil { store = BranchesStore(repository: session.repository) }
            await store?.loadAll()
            await loadAuxiliary()
            ensureSelection()
        }
        // Returning from BranchEditView (manageTarget → nil) or AddBranchView
        // (showingAdd → false) doesn't re-fire `.task`, so we'd otherwise show
        // pre-edit data — and any newly-added branch wouldn't appear at all.
        .onChange(of: manageTarget) { _, new in
            if new == nil {
                Task { await store?.loadAll(); await loadAuxiliary() }
            }
        }
        .onChange(of: showingAdd) { _, new in
            if !new {
                Task { await store?.loadAll(); await loadAuxiliary() }
            }
        }
    }

    @ViewBuilder
    private func content(store: BranchesStore) -> some View {
        let ordered = orderedBranches(store.summaries.map(\.branch))
        VStack(spacing: 0) {
            if !ordered.isEmpty {
                branchTabs(ordered)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.appBackground)
                Divider()
            }
            switch selectedTab {
            case .overview:
                overviewList(store: store, branches: ordered)
            case .branch(let id):
                BranchProfileView(branchID: id)
                    .id(id)
            }
        }
        .background(Color.appBackground)
        .onChange(of: store.summaries.map(\.branch.id)) { _, _ in
            ensureSelection()
        }
    }

    private func branchTabs(_ branches: [Branch]) -> some View {
        Picker("", selection: $selectedTab) {
            Text("tab.overview").tag(BranchTab.overview)
            ForEach(branches) { branch in
                Text(verbatim: branch.name).tag(BranchTab.branch(branch.id))
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private func overviewList(store: BranchesStore, branches: [Branch]) -> some View {
        let summaryByID = Dictionary(uniqueKeysWithValues: store.summaries.map { ($0.branch.id, $0) })
        return ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(branches) { branch in
                    if let summary = summaryByID[branch.id] {
                        Button {
                            selectedTab = .branch(branch.id)
                        } label: {
                            BranchSummaryRow(
                                summary: summary,
                                media: mediaLookup[branch.id],
                                hours: hoursLookup[branch.id]
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    private func orderedBranches(_ branches: [Branch]) -> [Branch] {
        let preferred = Self.preferredOrder
        let knownIndex: (String) -> Int = { name in
            preferred.firstIndex(where: { $0.caseInsensitiveCompare(name) == .orderedSame })
                ?? Int.max
        }
        return branches.sorted { lhs, rhs in
            let li = knownIndex(lhs.name)
            let ri = knownIndex(rhs.name)
            if li != ri { return li < ri }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func ensureSelection() {
        guard let store else { return }
        if case .branch(let id) = selectedTab,
           !store.summaries.contains(where: { $0.branch.id == id }) {
            selectedTab = .overview
        }
    }

    private func loadAuxiliary() async {
        guard let store else { return }
        for s in store.summaries {
            async let m = (try? await session.repository.media(branchID: s.branch.id))
            async let h = (try? await session.repository.hours(branchID: s.branch.id))
            let (media, hours) = await (m, h)
            if let media = media ?? nil { mediaLookup[s.branch.id] = media }
            if let hours = hours ?? nil { hoursLookup[s.branch.id] = hours }
        }
    }
}

// MARK: - Compact comparison row used on the Overview tab

private struct BranchSummaryRow: View {
    let summary: BranchSummary
    let media: BranchMedia?
    let hours: BranchHours?

    var body: some View {
        HStack(spacing: 12) {
            heroThumb
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(verbatim: summary.branch.name).scaledFont(.headline)
                    if let isOpen = hours?.isOpenNow() {
                        Text(isOpen ? "branch.open_now" : "branch.closed_now")
                            .scaledFont(.caption2, weight: .bold)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background((isOpen ? Color.green : Color.gray).opacity(0.18), in: Capsule())
                            .foregroundStyle(isOpen ? .green : .secondary)
                    }
                }
                Text(verbatim: summary.branch.nameAr)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Label("\(summary.athleteCount)/\(summary.branch.capacity)", systemImage: "person.3.fill")
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                    Label("\(Int(summary.utilisation * 100))%", systemImage: "gauge.with.needle")
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            GradeBadge(grade: summary.grade, size: 36)
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var heroThumb: some View {
        if let url = media?.heroPhotoURL, let parsed = URL(string: url) {
            AsyncImage(url: parsed) { phase in
                switch phase {
                case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                default: brandFallback
                }
            }
        } else {
            brandFallback
        }
    }

    private var brandFallback: some View {
        let color: Color = summary.branch.brandHexColor.map { Color(hex: $0) } ?? .accentColor
        return color.opacity(0.85)
    }
}

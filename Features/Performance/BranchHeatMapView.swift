import SwiftUI

public struct BranchHeatMapView: View {
    @Environment(AppSession.self) private var session
    @State private var rows: [BranchHeatRow] = []
    @State private var showingAdd = false
    @State private var selectedTab: BranchTab = .overview
    @State private var editTarget: EntityID?

    /// Discriminator for the segmented picker. `Overview` shows the club-wide
    /// comparison (every branch heat card stacked); `branch(id)` zooms in on
    /// one branch's card with a tap-through to its profile.
    private enum BranchTab: Hashable {
        case overview
        case branch(EntityID)
    }

    /// Display order for the segmented picker — keeps Al Rahmania first as
    /// the headquarters branch, then the others in the requested sequence.
    /// Anything outside this list is appended alphabetically.
    private static let preferredOrder: [String] = [
        "Al Rahmania",
        "Al Nasserya",
        "Al Nouf",
        "Industrial 18"
    ]

    public init() {}

    private var clubComposite: Double {
        guard !rows.isEmpty else { return 0 }
        let total = rows.reduce(0.0) { $0 + $1.compositeScore }
        return total / Double(rows.count)
    }

    private var totalAthletes: Int {
        rows.reduce(0) { $0 + $1.athleteCount }
    }

    private var orderedRows: [BranchHeatRow] {
        let preferred = Self.preferredOrder
        let knownIndex: (String) -> Int = { name in
            preferred.firstIndex(where: { $0.caseInsensitiveCompare(name) == .orderedSame })
                ?? Int.max
        }
        return rows.sorted { lhs, rhs in
            let li = knownIndex(lhs.branch.name)
            let ri = knownIndex(rhs.branch.name)
            if li != ri { return li < ri }
            return lhs.branch.name.localizedCaseInsensitiveCompare(rhs.branch.name) == .orderedAscending
        }
    }

    private var selectedRow: BranchHeatRow? {
        guard case .branch(let id) = selectedTab else { return nil }
        return orderedRows.first(where: { $0.branch.id == id })
    }

    public var body: some View {
        VStack(spacing: 0) {
            if !orderedRows.isEmpty {
                branchTabs
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                    .background(Color.appBackground)
                Divider()
            }
            ScrollView {
                VStack(spacing: 16) {
                    clubSummaryCard
                    switch selectedTab {
                    case .overview:
                        ForEach(orderedRows) { row in
                            NavigationLink(destination: BranchProfileView(branchID: row.branch.id)) {
                                branchCard(row: row)
                            }
                            .buttonStyle(.plain)
                        }
                        if rows.isEmpty {
                            Text("empty.no_branches")
                                .scaledFont(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 32)
                        }
                    case .branch:
                        if let row = selectedRow {
                            NavigationLink(destination: BranchProfileView(branchID: row.branch.id)) {
                                branchCard(row: row)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .background(Color.appBackground)
        .toolbar {
            if let role = session.currentUser?.role,
               PermissionMatrix.allowed(role: role, permission: .editBranchProfile),
               case .branch(let id) = selectedTab {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editTarget = id
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
        .navigationDestination(isPresented: $showingAdd) {
            AddBranchView { _ in
                Task { await load() }
            }
        }
        .navigationDestination(item: $editTarget) { id in
            BranchEditView(branchID: id)
        }
        .task {
            await load()
            ensureSelection()
        }
        .onChange(of: rows.map(\.branch.id)) { _, _ in
            ensureSelection()
        }
        // Returning from BranchEditView (editTarget → nil) or AddBranchView
        // (showingAdd → false) needs an explicit reload because `.task`
        // doesn't re-fire on back-navigation.
        .onChange(of: editTarget) { _, new in
            if new == nil { Task { await load() } }
        }
        .onChange(of: showingAdd) { _, new in
            if !new { Task { await load() } }
        }
    }

    private var branchTabs: some View {
        Picker("", selection: $selectedTab) {
            Text("tab.overview").tag(BranchTab.overview)
            ForEach(orderedRows) { row in
                Text(verbatim: row.branch.name).tag(BranchTab.branch(row.branch.id))
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private func ensureSelection() {
        if case .branch(let id) = selectedTab,
           !orderedRows.contains(where: { $0.branch.id == id }) {
            selectedTab = .overview
        }
    }

    // MARK: - Club summary

    private var clubSummaryCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                GradeBadge(grade: .from(score: clubComposite), size: 56)
                Text(verbatim: String(format: "%.0f", clubComposite))
                    .scaledFont(.caption, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("kpi.club_performance")
                    .scaledFont(.headline)
                HStack(spacing: 16) {
                    Label("\(rows.count)", systemImage: "building.2.fill")
                        .scaledFont(.subheadline)
                        .foregroundStyle(.secondary)
                    Label("\(totalAthletes)", systemImage: "figure.taekwondo")
                        .scaledFont(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            dimensionLegend
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var dimensionLegend: some View {
        VStack(alignment: .leading, spacing: 3) {
            legendDot(color: .green, label: "A")
            legendDot(color: .blue, label: "B")
            legendDot(color: .orange, label: "C")
            legendDot(color: .red, label: "D/F")
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(verbatim: label).scaledFont(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: - Branch card

    private func branchCard(row: BranchHeatRow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                GradeBadge(grade: row.composite, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: row.branch.name)
                        .scaledFont(.headline)
                        .foregroundStyle(.primary)
                    HStack(spacing: 8) {
                        Label("\(row.athleteCount)", systemImage: "person.3.fill")
                            .scaledFont(.caption)
                            .foregroundStyle(.secondary)
                        Text(verbatim: String(format: "%.0f pts", row.compositeScore))
                            .scaledFont(.caption, monospacedDigit: true)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .scaledFont(.caption)
                    .foregroundStyle(.tertiary)
            }

            dimensionBars(row: row)
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Dimension bars

    private static let dimensionKeys: [(label: LocalizedStringKey, icon: String)] = [
        ("dimension.competition", "trophy.fill"),
        ("dimension.technical", "gearshape.fill"),
        ("dimension.physical", "figure.run"),
        ("dimension.adherence", "calendar.badge.checkmark"),
        ("dimension.belt_progression", "arrow.up.right"),
        ("dimension.wellness", "heart.fill"),
    ]

    private func dimensionBars(row: BranchHeatRow) -> some View {
        VStack(spacing: 6) {
            ForEach(Array(row.rawScores.enumerated()), id: \.offset) { idx, score in
                let dim = Self.dimensionKeys[idx]
                let grade = row.dimensions[idx]
                dimensionBar(label: dim.label, icon: dim.icon, score: score, grade: grade)
            }
        }
    }

    private func dimensionBar(label: LocalizedStringKey, icon: String, score: Double, grade: LetterGrade) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .scaledFont(.caption2)
                .foregroundStyle(gradeColor(grade))
                .frame(width: 16)

            Text(label)
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.quaternarySystemFill))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(gradeColor(grade).opacity(0.7))
                        .frame(width: geo.size.width * min(1, score / 100))
                }
            }
            .frame(height: 10)

            Text(verbatim: grade.label)
                .scaledFont(.caption2, weight: .bold, monospacedDigit: true)
                .foregroundStyle(gradeColor(grade))
                .frame(width: 24, alignment: .trailing)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func gradeColor(_ grade: LetterGrade) -> Color {
        switch grade {
        case .aPlus, .a, .aMinus: .green
        case .bPlus, .b, .bMinus: .blue
        case .cPlus, .c, .cMinus: .orange
        case .dPlus, .d, .f: .red
        }
    }

    // MARK: - Data loading

    private func load() async {
        do {
            let branches = try await session.repository.branches()
            var out: [BranchHeatRow] = []
            for b in branches {
                let scores = try await session.repository.scores(branchID: b.id)
                let athletes = try await session.repository.athletes(branchID: b.id)
                if scores.isEmpty {
                    out.append(BranchHeatRow(
                        id: b.id, branch: b,
                        rawScores: Array(repeating: 0, count: 6),
                        dimensions: Array(repeating: .f, count: 6),
                        composite: .f, compositeScore: 0,
                        athleteCount: athletes.count
                    ))
                    continue
                }
                func avg(_ kp: KeyPath<PerformanceScore, Double>) -> Double {
                    scores.reduce(0.0) { $0 + $1[keyPath: kp] } / Double(scores.count)
                }
                let rawScores = [
                    avg(\.competition), avg(\.technical), avg(\.physical),
                    avg(\.adherence), avg(\.beltProgression), avg(\.wellness),
                ]
                let dims = rawScores.map { LetterGrade.from(score: $0) }
                let comp = ScoreEngine.branchComposite(scores)
                out.append(BranchHeatRow(
                    id: b.id, branch: b,
                    rawScores: rawScores, dimensions: dims,
                    composite: .from(score: comp), compositeScore: comp,
                    athleteCount: athletes.count
                ))
            }
            rows = out.sorted { $0.compositeScore > $1.compositeScore }
        } catch {
            print("BranchHeatMapView.load:", error)
        }
    }
}

private struct BranchHeatRow: Identifiable {
    let id: EntityID
    let branch: Branch
    let rawScores: [Double]
    let dimensions: [LetterGrade]
    let composite: LetterGrade
    let compositeScore: Double
    let athleteCount: Int
}

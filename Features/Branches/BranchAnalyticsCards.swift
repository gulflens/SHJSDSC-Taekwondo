import SwiftUI

// Analytics cards for the Branches Overview screen on iPad. Each card is a
// self-contained `SectionCard` so the Overview can compose them freely.

// MARK: - Athlete distribution donut

public struct BranchAthleteDistributionCard: View {
    public let branches: [Branch]
    public let athletesByBranch: [EntityID: [Athlete]]

    public init(branches: [Branch], athletesByBranch: [EntityID: [Athlete]]) {
        self.branches = branches
        self.athletesByBranch = athletesByBranch
    }

    public var body: some View {
        SectionCard("branches.analytics.distribution", icon: "chart.pie.fill") {
            HStack(alignment: .top, spacing: 16) {
                donut
                    .frame(width: 132, height: 132)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(orderedSlices, id: \.branch.id) { slice in
                        legendRow(slice)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var donut: some View {
        ZStack {
            ForEach(Array(orderedSlices.enumerated()), id: \.offset) { index, slice in
                Circle()
                    .trim(from: cumulativeStart(at: index), to: cumulativeEnd(at: index))
                    .stroke(sliceColor(at: index), lineWidth: 18)
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 0) {
                Text(verbatim: "\(totalAthletes)")
                    .scaledFont(.title2, weight: .bold, monospacedDigit: true)
                    .environment(\.layoutDirection, .leftToRight)
                Text("branches.analytics.total_athletes")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private struct Slice {
        let branch: Branch
        let count: Int
    }

    private var orderedSlices: [Slice] {
        branches
            .map { Slice(branch: $0, count: athletesByBranch[$0.id]?.count ?? 0) }
            .sorted { lhs, rhs in
                if lhs.branch.isMain != rhs.branch.isMain { return lhs.branch.isMain }
                return lhs.count > rhs.count
            }
    }

    private var totalAthletes: Int { orderedSlices.reduce(0) { $0 + $1.count } }

    private func cumulativeStart(at index: Int) -> CGFloat {
        guard totalAthletes > 0 else { return 0 }
        let prior = orderedSlices.prefix(index).reduce(0) { $0 + $1.count }
        return CGFloat(prior) / CGFloat(totalAthletes)
    }

    private func cumulativeEnd(at index: Int) -> CGFloat {
        guard totalAthletes > 0 else { return 0 }
        let inclusive = orderedSlices.prefix(index + 1).reduce(0) { $0 + $1.count }
        return CGFloat(inclusive) / CGFloat(totalAthletes)
    }

    private func sliceColor(at index: Int) -> Color {
        let palette: [Color] = [
            Color(red: 0.12, green: 0.43, blue: 0.92),
            Color(red: 0.20, green: 0.65, blue: 0.65),
            Color(red: 0.55, green: 0.40, blue: 0.75),
            Color(red: 0.95, green: 0.55, blue: 0.20),
            Color(red: 0.18, green: 0.62, blue: 0.36)
        ]
        return palette[index % palette.count]
    }

    private func legendRow(_ slice: Slice) -> some View {
        let index = orderedSlices.firstIndex { $0.branch.id == slice.branch.id } ?? 0
        let pct = totalAthletes > 0 ? Double(slice.count) / Double(totalAthletes) * 100 : 0
        return HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(sliceColor(at: index))
                .frame(width: 10, height: 10)
            Text(verbatim: slice.branch.name)
                .scaledFont(.caption)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(verbatim: "\(slice.count)")
                .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                .environment(\.layoutDirection, .leftToRight)
            Text(verbatim: String(format: "%.0f%%", pct))
                .scaledFont(.caption2, monospacedDigit: true)
                .foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
        }
    }
}

// MARK: - Sessions this week bar chart

public struct BranchSessionsBarCard: View {
    public let branches: [Branch]
    public let sessionsByBranch: [EntityID: Int]

    public init(branches: [Branch], sessionsByBranch: [EntityID: Int]) {
        self.branches = branches
        self.sessionsByBranch = sessionsByBranch
    }

    public var body: some View {
        SectionCard("branches.analytics.sessions_week", icon: "chart.bar.fill") {
            VStack(spacing: 10) {
                ForEach(orderedBranches) { branch in
                    barRow(branch)
                }
            }
        }
    }

    private var orderedBranches: [Branch] {
        branches.sorted { lhs, rhs in
            if lhs.isMain != rhs.isMain { return lhs.isMain }
            return (sessionsByBranch[lhs.id] ?? 0) > (sessionsByBranch[rhs.id] ?? 0)
        }
    }

    private var maxSessions: Int {
        max(1, sessionsByBranch.values.max() ?? 1)
    }

    private func barRow(_ branch: Branch) -> some View {
        let count = sessionsByBranch[branch.id] ?? 0
        let ratio = Double(count) / Double(maxSessions)
        return VStack(spacing: 4) {
            HStack(spacing: 6) {
                if branch.isMain {
                    Image(systemName: "crown.fill")
                        .scaledFont(.caption2)
                        .foregroundStyle(Color(red: 0.86, green: 0.65, blue: 0.13))
                }
                Text(verbatim: branch.name)
                    .scaledFont(.caption)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(verbatim: "\(count)")
                    .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                    .environment(\.layoutDirection, .leftToRight)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.12))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(branch.isMain ? Color.accentColor : Color.accentColor.opacity(0.55))
                        .frame(width: max(3, geo.size.width * ratio))
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Branch performance table

public struct BranchPerformanceTableCard: View {
    public let branches: [Branch]
    public let athletesByBranch: [EntityID: [Athlete]]
    public let coachesByBranch: [EntityID: [Coach]]
    public let sessionsByBranch: [EntityID: Int]

    public init(
        branches: [Branch],
        athletesByBranch: [EntityID: [Athlete]],
        coachesByBranch: [EntityID: [Coach]],
        sessionsByBranch: [EntityID: Int]
    ) {
        self.branches = branches
        self.athletesByBranch = athletesByBranch
        self.coachesByBranch = coachesByBranch
        self.sessionsByBranch = sessionsByBranch
    }

    public var body: some View {
        SectionCard("branches.analytics.performance", icon: "list.bullet.rectangle") {
            VStack(spacing: 0) {
                header
                Divider().opacity(0.4)
                ForEach(orderedBranches) { branch in
                    row(branch)
                    Divider().opacity(0.4)
                }
            }
        }
    }

    private var orderedBranches: [Branch] {
        branches.sorted { lhs, rhs in
            if lhs.isMain != rhs.isMain { return lhs.isMain }
            return lhs.name < rhs.name
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            headerCell("branches.table.col.branch", weight: 2.4, alignment: .leading)
            headerCell("branches.table.col.utilization", weight: 1.4, alignment: .trailing)
            headerCell("branches.table.col.athletes", weight: 1, alignment: .trailing)
            headerCell("branches.table.col.coaches", weight: 1, alignment: .trailing)
            headerCell("branches.table.col.sessions", weight: 1, alignment: .trailing)
            headerCell("branches.table.col.score", weight: 1.2, alignment: .trailing)
        }
        .scaledFont(.caption2, weight: .semibold)
        .foregroundStyle(.secondary)
        .padding(.vertical, 6)
    }

    private func headerCell(_ key: LocalizedStringKey, weight: CGFloat, alignment: Alignment) -> some View {
        Text(key)
            .frame(maxWidth: .infinity, alignment: alignment)
            .layoutPriority(weight)
    }

    private func row(_ branch: Branch) -> some View {
        let athletes = athletesByBranch[branch.id]?.count ?? 0
        let coaches = coachesByBranch[branch.id]?.count ?? 0
        let sessions = sessionsByBranch[branch.id] ?? 0
        let utilization = branch.capacity > 0 ? Double(athletes) / Double(branch.capacity) : 0
        let score = compositeScore(branch: branch)
        return HStack(spacing: 12) {
            HStack(spacing: 6) {
                if branch.isMain {
                    Image(systemName: "crown.fill")
                        .scaledFont(.caption2)
                        .foregroundStyle(Color(red: 0.86, green: 0.65, blue: 0.13))
                }
                Text(verbatim: branch.name)
                    .scaledFont(.footnote)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(2.4)
            valueCell(String(format: "%.0f%%", utilization * 100), color: utilizationColor(utilization))
                .layoutPriority(1.4)
            valueCell("\(athletes)").layoutPriority(1)
            valueCell("\(coaches)").layoutPriority(1)
            valueCell("\(sessions)").layoutPriority(1)
            scoreCell(score).layoutPriority(1.2)
        }
        .padding(.vertical, 8)
    }

    private func valueCell(_ text: String, color: Color = .primary) -> some View {
        Text(verbatim: text)
            .scaledFont(.footnote, weight: .semibold, monospacedDigit: true)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .environment(\.layoutDirection, .leftToRight)
    }

    private func scoreCell(_ score: Double) -> some View {
        let color: Color = switch score {
        case 0.75...: .green
        case 0.5..<0.75: .tint
        case 0.25..<0.5: .orange
        default: .red
        }
        return HStack(spacing: 4) {
            Spacer(minLength: 0)
            Image(systemName: score >= 0.5 ? "arrow.up.right" : "arrow.down.right")
                .scaledFont(.caption2)
                .foregroundStyle(color)
            Text(verbatim: String(format: "%.0f", score * 100))
                .scaledFont(.footnote, weight: .semibold, monospacedDigit: true)
                .foregroundStyle(color)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private func utilizationColor(_ utilization: Double) -> Color {
        switch utilization {
        case 0.85...: .green
        case 0.5..<0.85: .tint
        case 0.25..<0.5: .orange
        default: .red
        }
    }

    /// 0...1 composite mixing utilization, sessions-per-coach, and coach-to-
    /// athlete ratio. Pure heuristic; replace with a real `BranchScore`
    /// repository when one ships.
    private func compositeScore(branch: Branch) -> Double {
        let athletes = athletesByBranch[branch.id]?.count ?? 0
        let coaches = coachesByBranch[branch.id]?.count ?? 0
        let sessions = sessionsByBranch[branch.id] ?? 0
        let utilization = branch.capacity > 0 ? Double(athletes) / Double(branch.capacity) : 0
        let sessionsPerCoach = coaches > 0 ? Double(sessions) / Double(coaches) : 0
        let coachRatio = athletes > 0 ? Double(coaches) / Double(athletes) : 0
        let normalisedSessions = min(1, sessionsPerCoach / 5)
        let normalisedRatio = min(1, coachRatio * 30) // 1 coach per ~30 athletes is solid
        return max(0, min(1, (utilization + normalisedSessions + normalisedRatio) / 3))
    }
}

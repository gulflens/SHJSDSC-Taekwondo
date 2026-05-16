import SwiftUI

/// Org-chart visualisation of the federation hierarchy: main branch on top,
/// secondary branches connected below via elegant L-shaped lines. iPad-only
/// — on compact size class the screen above renders flat cards instead.
public struct BranchHierarchyView: View {
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
        SectionCard("branches.hierarchy.title", icon: "rectangle.connected.to.line.below") {
            if let main = branches.first(where: { $0.isMain }) {
                VStack(spacing: 0) {
                    branchNode(main, isMain: true)
                    connector
                    secondaryRow
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
            } else {
                EmptyStateCard(
                    icon: "questionmark.circle",
                    titleKey: "branches.hierarchy.empty.title",
                    messageKey: "branches.hierarchy.empty.message"
                )
            }
        }
    }

    private var secondaries: [Branch] {
        branches.filter { !$0.isMain }
    }

    private var secondaryRow: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(secondaries) { branch in
                VStack(spacing: 0) {
                    secondaryConnector
                    branchNode(branch, isMain: false)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var connector: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.accentColor.opacity(0.35))
                .frame(width: 2, height: 18)
            Rectangle()
                .fill(Color.accentColor.opacity(0.35))
                .frame(height: 2)
                .padding(.horizontal, secondaries.count > 1 ? 60 : 0)
        }
    }

    private var secondaryConnector: some View {
        Rectangle()
            .fill(Color.accentColor.opacity(0.35))
            .frame(width: 2, height: 18)
    }

    @ViewBuilder
    private func branchNode(_ branch: Branch, isMain: Bool) -> some View {
        let athletes = athletesByBranch[branch.id]?.count ?? 0
        let coaches = coachesByBranch[branch.id]?.count ?? 0
        let sessions = sessionsByBranch[branch.id] ?? 0
        NavigationLink {
            BranchProfileView(branchID: branch.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: isMain ? "crown.fill" : "building.2.fill")
                        .scaledFont(.subheadline, weight: .semibold)
                        .foregroundStyle(isMain ? Color(red: 0.86, green: 0.65, blue: 0.13) : .tint)
                    Text(verbatim: branch.name)
                        .scaledFont(.subheadline, weight: .semibold)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    statusDot(for: branch.operationalStatus)
                }
                Text(verbatim: branch.area.isEmpty ? branch.emirate : "\(branch.area), \(branch.emirate)")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                Divider().opacity(0.4)
                HStack(spacing: 14) {
                    miniStat(icon: "person.3.fill", value: "\(athletes)")
                    miniStat(icon: "graduationcap.fill", value: "\(coaches)")
                    miniStat(icon: "calendar.badge.checkmark", value: "\(sessions)")
                }
            }
            .padding(12)
            .frame(maxWidth: isMain ? 380 : .infinity, alignment: .leading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isMain ? Color.accentColor.opacity(0.6) : Color.secondary.opacity(0.15), lineWidth: isMain ? 1.5 : 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func miniStat(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .scaledFont(.caption2)
                .foregroundStyle(.tint)
            Text(verbatim: value)
                .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private func statusDot(for status: BranchOperationalStatus) -> some View {
        let color: Color = switch status {
        case .active: .green
        case .maintenance: .orange
        case .tournamentMode: .red
        case .closed: .gray
        }
        return Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .accessibilityLabel(Text(localizedKey: status.labelKey))
    }
}

import SwiftUI

/// Coach reports surface. The current data model doesn't expose a Reports
/// repository — this tab renders a styled empty state plus the report types
/// the coach could file once Stage 2 ships the Reports module.
///
/// Keeping the surface here so the spec's "8-tab module" promise holds and
/// the slot is ready for backing data.
public struct CoachReportsTab: View {
    public let coach: Coach
    public let isWide: Bool

    public init(coach: Coach, isWide: Bool) {
        self.coach = coach
        self.isWide = isWide
    }

    public var body: some View {
        VStack(spacing: 14) {
            kpiStrip
            availableReportsCard
            statusCard
        }
    }

    private var kpiStrip: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 4 : 2),
            spacing: 12
        ) {
            KPITile(title: "coach.reports.pending", value: "0", icon: "clock.fill")
            KPITile(title: "coach.reports.submitted", value: "0", icon: "paperplane.fill")
            KPITile(title: "coach.reports.approved", value: "0", icon: "checkmark.seal.fill")
            KPITile(title: "coach.reports.flagged", value: "0", icon: "exclamationmark.bubble.fill")
        }
    }

    private var availableReportsCard: some View {
        SectionCard("coach.reports.available", icon: "doc.text.fill") {
            VStack(spacing: 6) {
                reportTypeRow("coach.reports.type.athlete_evaluation", icon: "figure.taekwondo")
                reportTypeRow("coach.reports.type.belt_recommendation", icon: "circle.hexagongrid.fill")
                reportTypeRow("coach.reports.type.discipline", icon: "shield.fill")
                reportTypeRow("coach.reports.type.injury", icon: "bandage.fill")
                reportTypeRow("coach.reports.type.performance", icon: "chart.line.uptrend.xyaxis")
                reportTypeRow("coach.reports.type.federation", icon: "rosette")
            }
        }
    }

    private func reportTypeRow(_ key: LocalizedStringKey, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                Image(systemName: icon)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.tint)
            }
            .frame(width: 38, height: 38)
            Text(key)
                .scaledFont(.subheadline, weight: .semibold)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .padding(.vertical, 6)
    }

    private var statusCard: some View {
        SectionCard("coach.reports.history", icon: "list.bullet.rectangle") {
            EmptyStateCard(
                icon: "doc.text.magnifyingglass",
                titleKey: "coach.reports.empty.title",
                messageKey: "coach.reports.empty.message"
            )
        }
    }
}

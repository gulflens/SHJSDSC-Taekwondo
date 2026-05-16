import SwiftUI

/// Surfaces athletes on a coach's roster who have hit every grading
/// criterion (time-at-rank, attendance, technical, physical) and are ready
/// to be put forward for a belt test. Renders as a `SectionCard` on the
/// coach home dashboard.
public struct PromotionReadinessCard: View {
    public let coachID: EntityID

    @Environment(AppSession.self) private var appSession
    @State private var store: PromotionReadinessStore?

    public init(coachID: EntityID) {
        self.coachID = coachID
    }

    public var body: some View {
        Group {
            if let store {
                content(store: store)
            } else {
                SectionCard("coach.home.readiness.title", icon: "rosette") {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 80)
                }
            }
        }
        .task {
            if store == nil {
                store = PromotionReadinessStore(repository: appSession.repository)
            }
            await store?.load(coachID: coachID)
        }
    }

    @ViewBuilder
    private func content(store: PromotionReadinessStore) -> some View {
        SectionCard("coach.home.readiness.title", icon: "rosette") {
            if store.isLoading && store.entries.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else if store.entries.isEmpty {
                EmptyStateCard(
                    icon: "rosette",
                    titleKey: "coach.home.readiness.empty.title",
                    messageKey: "coach.home.readiness.empty.message"
                )
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Text("coach.home.readiness.count \(store.entries.count)")
                            .scaledFont(.caption, weight: .semibold)
                            .foregroundStyle(.tint)
                        Spacer(minLength: 0)
                    }
                    .padding(.bottom, 10)
                    ForEach(Array(store.entries.prefix(5))) { entry in
                        NavigationLink(destination: AthleteDetailView(athlete: entry.athlete)) {
                            row(entry)
                        }
                        .buttonStyle(.plain)
                        if entry.id != store.entries.prefix(5).last?.id {
                            Divider().opacity(0.25)
                        }
                    }
                }
            }
        }
    }

    private func row(_ entry: PromotionReadinessEntry) -> some View {
        let a = entry.athlete
        let e = entry.eligibility
        return HStack(spacing: 12) {
            Avatar(seed: a.avatarSeed, label: a.initials, size: 40, urlString: a.avatarURL)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: a.fullName)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(localizedKey: e.currentBelt.label)
                    Image(systemName: "arrow.right")
                        .scaledFont(.caption2, weight: .bold)
                        .foregroundStyle(.secondary)
                        .flipsForRightToLeftLayoutDirection(true)
                    Text(localizedKey: e.targetBelt.label)
                        .foregroundStyle(.tint)
                }
                .scaledFont(.caption, weight: .semibold)
                HStack(spacing: 6) {
                    metricChip(
                        icon: "calendar",
                        value: "\(Int(e.attendancePct * 100))%",
                        tint: tint(for: e.attendancePct, threshold: 0.75)
                    )
                    metricChip(
                        icon: "figure.taekwondo",
                        value: String(format: "%.1f", e.latestTechnicalAvg),
                        tint: tint(for: e.latestTechnicalAvg / 10, threshold: 0.65)
                    )
                    metricChip(
                        icon: "bolt.fill",
                        value: "\(Int(e.latestPhysicalComposite))",
                        tint: tint(for: e.latestPhysicalComposite / 100, threshold: 0.6)
                    )
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func metricChip(icon: String, value: String, tint: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .scaledFont(.caption2)
            Text(verbatim: value)
                .scaledFont(.caption2, weight: .semibold, monospacedDigit: true)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(tint.opacity(0.15), in: Capsule())
        .foregroundStyle(tint)
    }

    private func tint(for value: Double, threshold: Double) -> Color {
        if value >= threshold + 0.15 { return .green }
        if value >= threshold { return .accentColor }
        return .orange
    }
}

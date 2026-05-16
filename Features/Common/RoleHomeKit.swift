import SwiftUI

// MARK: - Role home dashboard kit
//
// Shared helpers for the four role home dashboards (Coach / Athlete / Parent /
// Branch Manager). The executive cards themselves reuse `ExecutiveAnalyticsCard`
// / `MiniSparkline` / `TrendIndicator` from `BranchOverviewKit` — this file
// only adds the deterministic demo-data generator and the layout / action
// primitives the four screens have in common.

/// Deterministic 12-point sparkline for a home executive analytics card. The
/// home dashboards have no historical analytics table, so trend lines are
/// synthesised from a stable seed — the same approach as the Stage 1.11 branch
/// dashboard. `rising` flips the slope so "good-trending" and "down-trending"
/// metrics each read correctly.
public func homeSpark(_ seed: Int, rising: Bool = true) -> [Double] {
    (0..<12).map { i in
        let t = Double(i) / 11.0
        return 50 + (rising ? 1 : -1) * t * 26 + sin(Double(i) * 1.7 + Double(seed)) * 7
    }
}

/// Adaptive column set for a home dashboard's executive analytics grid —
/// `wideCount` columns on iPad, two on iPhone.
public func homeAnalyticsColumns(isWide: Bool, wideCount: Int = 6) -> [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: 12),
          count: isWide ? wideCount : 2)
}

// MARK: - Quick action tile

/// Compact tinted quick-action tile used in the home dashboards' action grids
/// (Coach quick links, Branch Manager quick actions). Pairs an icon chip with
/// a short two-line label on a soft tinted surface.
public struct HomeQuickActionTile: View {
    private let icon: String
    private let titleKey: LocalizedStringKey
    private let tint: Color
    private let action: () -> Void

    public init(
        icon: String,
        titleKey: LocalizedStringKey,
        tint: Color = .accentColor,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.titleKey = titleKey
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.14))
                    Image(systemName: icon)
                        .scaledFont(.subheadline, weight: .semibold)
                        .foregroundStyle(tint)
                }
                .frame(width: 36, height: 36)
                Text(titleKey)
                    .scaledFont(.caption, weight: .semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity row

/// One row in a home dashboard's recent-activity feed — a tinted icon chip,
/// a title, an optional subtitle, and a trailing timestamp string.
public struct HomeActivityRow: View {
    private let icon: String
    private let tint: Color
    private let title: String
    private let subtitle: String?
    private let timeText: String

    public init(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String? = nil,
        timeText: String
    ) {
        self.icon = icon
        self.tint = tint
        self.title = title
        self.subtitle = subtitle
        self.timeText = timeText
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint.opacity(0.15))
                Image(systemName: icon)
                    .scaledFont(.caption, weight: .semibold)
                    .foregroundStyle(tint)
            }
            .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: title)
                    .scaledFont(.caption, weight: .semibold)
                    .lineLimit(1)
                if let subtitle {
                    Text(verbatim: subtitle)
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 6)
            Text(verbatim: timeText)
                .scaledFont(.caption2)
                .foregroundStyle(.tertiary)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.vertical, 3)
    }
}

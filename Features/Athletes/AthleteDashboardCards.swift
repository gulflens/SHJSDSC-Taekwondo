import SwiftUI
import Charts

// MARK: - Athlete dashboard cards
//
// Stage 1.12 — the athlete performance card (list) and the athlete preview
// panel (iPad detail), plus the 12-week performance-trend chart.

// MARK: Performance card

/// Premium athlete intelligence card for the dashboard list.
public struct AthletePerformanceCard: View {
    private let intel: AthleteIntel
    private let selected: Bool
    @Environment(\.horizontalSizeClass) private var hSize

    public init(intel: AthleteIntel, selected: Bool) {
        self.intel = intel
        self.selected = selected
    }

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        Group {
            if isWide {
                HStack(alignment: .center, spacing: 14) {
                    avatar
                    infoColumn.frame(maxWidth: .infinity, alignment: .leading)
                    metricRings
                    AthleteGradeRing(grade: intel.grade, score: intel.composite,
                                     size: 56, showsCaption: false)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        avatar
                        infoColumn
                        Spacer(minLength: 4)
                        AthleteGradeRing(grade: intel.grade, score: intel.composite,
                                         size: 52, showsCaption: false)
                    }
                    metricRings
                }
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(selected ? Color.accentColor.opacity(0.07) : Color.secondary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(selected ? Color.accentColor : Color.secondary.opacity(0.08),
                        lineWidth: selected ? 1.5 : 1)
        )
        .shadow(color: selected ? Color.accentColor.opacity(0.16) : .clear, radius: 8, y: 3)
        .contentShape(Rectangle())
    }

    private var avatar: some View {
        Avatar(seed: intel.athlete.avatarSeed, label: intel.athlete.initials, size: 54)
            .overlay(Circle().stroke(intel.grade.branchTint.opacity(0.6), lineWidth: 2))
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(intel.athlete.status == .rest ? Color.secondary : Color.secondaryAccent)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.cardBackground, lineWidth: 2))
            }
    }

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: intel.athlete.fullName)
                .scaledFont(.subheadline, weight: .bold)
                .lineLimit(1)
            HStack(spacing: 5) {
                Text(localizedKey: intel.athlete.currentBelt.label)
                Text(verbatim: "·")
                Text(localizedKey: intel.ageGroup.labelKey)
            }
            .scaledFont(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            Text(verbatim: String(format: NSLocalizedString("athlete.branch.fmt", comment: ""),
                                   intel.branchName))
                .scaledFont(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            HStack(spacing: 5) {
                AthleteTagChip(titleKey: intel.athlete.status.labelKey,
                               tint: intel.athlete.status.tint,
                               systemIcon: intel.athlete.status.systemIcon)
                if intel.isElite {
                    AthleteTagChip(titleKey: "athlete.elite", tint: .purple, systemIcon: "star.fill")
                }
            }
            .padding(.top, 1)
        }
    }

    private var metricRings: some View {
        HStack(spacing: isWide ? 10 : 8) {
            ForEach(AthleteMetricKind.allCases, id: \.self) { kind in
                MiniMetricRing(kind: kind, score: intel.metric(kind))
            }
        }
    }
}

// MARK: - Preview panel

/// iPad right-side athlete preview — photo, vitals, performance trend,
/// recent activity, and a link to the full profile.
public struct AthletePreviewPanel: View {
    private let intel: AthleteIntel
    private let onViewProfile: () -> Void

    public init(intel: AthleteIntel, onViewProfile: @escaping () -> Void) {
        self.intel = intel
        self.onViewProfile = onViewProfile
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                vitalsRow
                trendSection
                activitySection
                Button(action: onViewProfile) {
                    Text("athlete.view_profile")
                        .scaledFont(.subheadline, weight: .semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(Color.accentColor)
                        .background(Color.accentColor.opacity(0.10),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(18)
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(Color.secondary.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
        .id(intel.id)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Avatar(seed: intel.athlete.avatarSeed, label: intel.athlete.initials, size: 60)
                .overlay(Circle().stroke(intel.grade.branchTint.opacity(0.6), lineWidth: 2))
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: intel.athlete.fullName)
                    .scaledFont(.headline, weight: .bold)
                HStack(spacing: 5) {
                    Text(localizedKey: intel.ageGroup.labelKey)
                    Text(verbatim: "·")
                    Text(localizedKey: intel.athlete.currentBelt.label)
                }
                .scaledFont(.caption).foregroundStyle(.secondary)
                Text(verbatim: String(format: NSLocalizedString("athlete.branch.fmt", comment: ""),
                                       intel.branchName))
                    .scaledFont(.caption2).foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
    }

    private var vitalsRow: some View {
        HStack(spacing: 10) {
            vital("calendar", "athlete.age", "\(intel.age)")
            vital("person.fill", "athlete.gender",
                  NSLocalizedString("gender.\(intel.athlete.gender.rawValue)", comment: ""))
            vital("scalemass", "athlete.weight",
                  String(format: NSLocalizedString("athlete.weight.fmt", comment: ""), intel.athlete.weightKg))
            vital("ruler", "athlete.height",
                  intel.athlete.heightCm.map {
                      String(format: NSLocalizedString("athlete.height.fmt", comment: ""), $0)
                  } ?? "—")
        }
    }

    private func vital(_ icon: String, _ labelKey: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon).scaledFont(.caption2).foregroundStyle(.secondary)
                Text(localizedKey: labelKey).scaledFont(.caption2).foregroundStyle(.secondary)
            }
            Text(verbatim: value)
                .scaledFont(.subheadline, weight: .bold)
                .lineLimit(1)
                .environment(\.layoutDirection, .leftToRight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9).padding(.vertical, 8)
        .background(Color.secondary.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("athlete.perf_trend")
                .scaledFont(.subheadline, weight: .semibold)
            AthletePerformanceTrendChart(values: intel.perfTrend, tint: intel.grade.branchTint)
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("athlete.recent_activity")
                .scaledFont(.subheadline, weight: .semibold)
            VStack(spacing: 8) {
                ForEach(intel.recentActivity) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.done ? "checkmark.circle.fill" : "clock.fill")
                            .scaledFont(.subheadline)
                            .foregroundStyle(item.done ? Color.secondaryAccent : Color.orange)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(localizedKey: item.kind.labelKey)
                                .scaledFont(.caption, weight: .semibold)
                            Text(verbatim: item.dateText)
                                .scaledFont(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
}

// MARK: - Performance trend chart

/// 12-week single-line performance trend.
public struct AthletePerformanceTrendChart: View {
    private let values: [Double]
    private let tint: Color

    public init(values: [Double], tint: Color) {
        self.values = values
        self.tint = tint
    }

    public var body: some View {
        Chart {
            ForEach(Array(values.enumerated()), id: \.offset) { idx, value in
                LineMark(x: .value("Week", idx + 1), y: .value("Score", value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(tint)
                AreaMark(x: .value("Week", idx + 1), y: .value("Score", value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(colors: [tint.opacity(0.22), tint.opacity(0.01)],
                                                    startPoint: .top, endPoint: .bottom))
                PointMark(x: .value("Week", idx + 1), y: .value("Score", value))
                    .foregroundStyle(tint)
                    .symbolSize(28)
            }
        }
        .chartYScale(domain: 40...100)
        .chartXAxis {
            AxisMarks(values: [1, 3, 5, 7, 9, 11]) { value in
                AxisValueLabel {
                    if let week = value.as(Int.self) {
                        Text(verbatim: "W\(week)")
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [40, 60, 80, 100])
        }
        .frame(height: 150)
        .environment(\.layoutDirection, .leftToRight)
    }
}

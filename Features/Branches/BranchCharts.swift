import SwiftUI
import Charts

// MARK: - Branch performance charts
//
// Stage 1.11 — three reusable chart views for the Branch Performance Overview
// dashboard. Each is bare (no card chrome) — the caller wraps them.
//
//   • AthleteDistributionChart — donut of athlete counts per branch
//   • AttendanceTrendChart     — 12-week multi-line attendance trend
//   • CoachingRadarChart       — hand-drawn 6-axis coaching radar
//
// Swift Charts powers the donut + line chart; the radar is hand-drawn with
// `Canvas` since Swift Charts has no radar mark. Branches arrive already
// sorted — `branchChartColor(index:)` keeps each branch the same color across
// all three charts by its index in the passed array.

// MARK: - Shared palette

/// Stable per-branch chart color. Branches are passed already-sorted, so the
/// caller's index is the identity. The pastel ramp cycles for >6 branches.
public func branchChartColor(_ index: Int) -> Color {
    let palette: [Color] = [.accentColor, .secondaryAccent, .orange, .purple, .pink, .cyan]
    return palette[index % palette.count]
}

// MARK: - Legend

/// Compact colored-dot legend shared by all three charts.
private struct BranchChartLegend: View {
    let branches: [BranchAnalytics]

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 110), spacing: 10, alignment: .leading)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(Array(branches.enumerated()), id: \.element.id) { index, analytics in
                HStack(spacing: 6) {
                    Circle()
                        .fill(branchChartColor(index))
                        .frame(width: 8, height: 8)
                    Text(verbatim: analytics.branch.name)
                        .scaledFont(.caption2, weight: .medium)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

// MARK: - 1. Athlete distribution donut

public struct AthleteDistributionChart: View {
    private let branches: [BranchAnalytics]

    public init(branches: [BranchAnalytics]) {
        self.branches = branches
    }

    private var total: Int {
        branches.reduce(0) { $0 + $1.athleteCount }
    }

    public var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Chart(Array(branches.enumerated()), id: \.element.id) { index, analytics in
                    SectorMark(
                        angle: .value("count", analytics.athleteCount),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .cornerRadius(3)
                    .foregroundStyle(branchChartColor(index))
                }
                .frame(height: 200)
                .environment(\.layoutDirection, .leftToRight)

                VStack(spacing: 2) {
                    Text(verbatim: "\(total)")
                        .scaledFont(.title, weight: .bold, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                    Text("branch.dist.total")
                        .scaledFont(.caption2, weight: .medium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            legend
        }
    }

    private var legend: some View {
        VStack(spacing: 6) {
            ForEach(Array(branches.enumerated()), id: \.element.id) { index, analytics in
                HStack(spacing: 8) {
                    Circle()
                        .fill(branchChartColor(index))
                        .frame(width: 9, height: 9)
                    Text(verbatim: analytics.branch.name)
                        .scaledFont(.caption, weight: .medium)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(verbatim: "\(analytics.athleteCount)")
                        .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                    Text(verbatim: percentText(analytics.athleteCount))
                        .scaledFont(.caption2, monospacedDigit: true)
                        .foregroundStyle(.secondary)
                        .environment(\.layoutDirection, .leftToRight)
                        .frame(width: 44, alignment: .trailing)
                }
            }
        }
    }

    private func percentText(_ count: Int) -> String {
        guard total > 0 else { return "0%" }
        let pct = Double(count) / Double(total) * 100
        return String(format: "%.0f%%", pct)
    }
}

// MARK: - 2. Attendance trend multi-line

public struct AttendanceTrendChart: View {
    private let branches: [BranchAnalytics]

    public init(branches: [BranchAnalytics]) {
        self.branches = branches
    }

    public var body: some View {
        VStack(spacing: 14) {
            Chart {
                ForEach(Array(branches.enumerated()), id: \.element.id) { index, analytics in
                    let color = branchChartColor(index)
                    ForEach(Array(analytics.attendanceTrend.enumerated()), id: \.offset) { week, value in
                        LineMark(
                            x: .value("week", week + 1),
                            y: .value("attendance", value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(color)
                        .foregroundStyle(by: .value("branch", analytics.branch.name))

                        PointMark(
                            x: .value("week", week + 1),
                            y: .value("attendance", value)
                        )
                        .foregroundStyle(color)
                        .symbolSize(28)
                    }
                }
            }
            .chartForegroundStyleScale(range: foregroundRange)
            .chartLegend(.hidden)
            .chartYScale(domain: 40...100)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXScale(domain: 1...12)
            .chartXAxis {
                AxisMarks(values: Array(stride(from: 1, through: 12, by: 2))) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let week = value.as(Int.self) {
                            Text(verbatim: "W\(week)")
                        }
                    }
                }
            }
            .frame(height: 200)
            .environment(\.layoutDirection, .leftToRight)

            BranchChartLegend(branches: branches)
        }
    }

    /// Keeps the `foregroundStyle(by:)` scale aligned with the explicit
    /// per-branch palette so the line colors match the legend exactly.
    private var foregroundRange: [Color] {
        branches.enumerated().map { branchChartColor($0.offset) }
    }
}

// MARK: - 3. Coaching radar (hand-drawn)

public struct CoachingRadarChart: View {
    private let branches: [BranchAnalytics]
    private let ringCount = 4

    public init(branches: [BranchAnalytics]) {
        self.branches = branches
    }

    private let axes = BranchRadarAxis.allCases

    public var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                // Leave headroom for the axis labels at the spoke ends.
                let radius = side / 2 * 0.66

                ZStack {
                    grid(center: center, radius: radius)
                    polygons(center: center, radius: radius)
                    axisLabels(center: center, radius: radius)
                }
            }
            .frame(height: 220)
            .environment(\.layoutDirection, .leftToRight)

            BranchChartLegend(branches: branches)

            Text("branch.radar.scale_note")
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Grid

    private func grid(center: CGPoint, radius: CGFloat) -> some View {
        Canvas { context, _ in
            let strokeColor = Color.secondary.opacity(0.18)

            // Concentric rings.
            for ring in 1...ringCount {
                let r = radius * CGFloat(ring) / CGFloat(ringCount)
                var path = Path()
                for (idx, _) in axes.enumerated() {
                    let p = vertex(center: center, radius: r, index: idx)
                    if idx == 0 { path.move(to: p) } else { path.addLine(to: p) }
                }
                path.closeSubpath()
                context.stroke(path, with: .color(strokeColor), lineWidth: 1)
            }

            // Spokes.
            for idx in axes.indices {
                let p = vertex(center: center, radius: radius, index: idx)
                var spoke = Path()
                spoke.move(to: center)
                spoke.addLine(to: p)
                context.stroke(spoke, with: .color(strokeColor), lineWidth: 1)
            }
        }
    }

    // MARK: Branch polygons

    private func polygons(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            ForEach(Array(branches.enumerated()), id: \.element.id) { index, analytics in
                let color = branchChartColor(index)
                let path = polygonPath(for: analytics, center: center, radius: radius)
                path.fill(color.opacity(0.16))
                path.stroke(color, lineWidth: 1.5)
            }
        }
    }

    private func polygonPath(for analytics: BranchAnalytics,
                             center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        for (idx, axis) in axes.enumerated() {
            let score = analytics.radar.first { $0.axis == axis }?.score ?? 0
            let fraction = CGFloat(min(100, max(0, score)) / 100)
            let p = vertex(center: center, radius: radius * fraction, index: idx)
            if idx == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    // MARK: Axis labels

    private func axisLabels(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            ForEach(Array(axes.enumerated()), id: \.element) { idx, axis in
                let p = vertex(center: center, radius: radius + 18, index: idx)
                Text(localizedKey: axis.labelKey)
                    .scaledFont(.caption2, weight: .medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize()
                    .position(x: p.x, y: p.y)
            }
        }
    }

    // MARK: Geometry

    /// Vertex for axis `index`, starting straight up (12 o'clock) and going
    /// clockwise — the conventional radar orientation.
    private func vertex(center: CGPoint, radius: CGFloat, index: Int) -> CGPoint {
        let step = (2 * Double.pi) / Double(axes.count)
        let angle = -Double.pi / 2 + step * Double(index)
        return CGPoint(
            x: center.x + radius * CGFloat(cos(angle)),
            y: center.y + radius * CGFloat(sin(angle))
        )
    }
}

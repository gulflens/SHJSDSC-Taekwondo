import SwiftUI

// MARK: - Branch overview design kit
//
// Stage 1.11 — shared components for the Branch Performance Overview:
// colour mapping, the executive analytics card, grade / metric rings, trend
// indicator, status chip, rank badge, insight card, and a mini sparkline.

public extension LetterGrade {
    /// Dashboard accent for a branch's overall grade.
    var branchTint: Color {
        switch self {
        case .aPlus, .a, .aMinus: .secondaryAccent
        case .bPlus, .b, .bMinus: .accentColor
        case .cPlus, .c, .cMinus: .orange
        case .dPlus, .d, .f:      .red
        }
    }
}

public extension BranchMetricKind {
    /// Pastel accent for each performance metric ring.
    var tint: Color {
        switch self {
        case .competition: .accentColor
        case .technique:   .purple
        case .fitness:     .orange
        case .attendance:  .cyan
        case .progress:    .secondaryAccent
        case .wellness:    .pink
        }
    }
}

public extension BranchTrend {
    var tint: Color {
        switch self {
        case .improving: .secondaryAccent
        case .stable:    .secondary
        case .declining: .red
        }
    }
    var systemIcon: String {
        switch self {
        case .improving: "arrow.up.right"
        case .stable:    "arrow.right"
        case .declining: "arrow.down.right"
        }
    }
}

// MARK: - Mini sparkline

/// Tiny filled line trend for the executive analytics cards.
public struct MiniSparkline: View {
    private let values: [Double]
    private let tint: Color

    public init(values: [Double], tint: Color) {
        self.values = values
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { geo in
            let pts = points(in: geo.size)
            ZStack {
                if pts.count > 1 {
                    Path { p in
                        p.move(to: CGPoint(x: pts[0].x, y: geo.size.height))
                        pts.forEach { p.addLine(to: $0) }
                        p.addLine(to: CGPoint(x: pts.last!.x, y: geo.size.height))
                        p.closeSubpath()
                    }
                    .fill(LinearGradient(colors: [tint.opacity(0.22), tint.opacity(0.01)],
                                         startPoint: .top, endPoint: .bottom))
                    Path { p in
                        p.move(to: pts[0])
                        pts.dropFirst().forEach { p.addLine(to: $0) }
                    }
                    .stroke(tint, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                }
            }
        }
        .frame(height: 32)
        .environment(\.layoutDirection, .leftToRight)
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        let lo = values.min() ?? 0
        let hi = values.max() ?? 1
        let span = max(hi - lo, 0.0001)
        let stepX = size.width / CGFloat(values.count - 1)
        return values.enumerated().map { i, v in
            let norm = (v - lo) / span
            return CGPoint(x: CGFloat(i) * stepX,
                           y: size.height - CGFloat(norm) * size.height)
        }
    }
}

// MARK: - Executive analytics card

/// Top-row KPI card — icon + label + headline value + sparkline + 30-day delta.
public struct ExecutiveAnalyticsCard: View {
    private let titleKey: String
    private let systemIcon: String
    private let tint: Color
    private let value: String
    private let spark: [Double]
    private let deltaPct: Double

    public init(titleKey: String, systemIcon: String, tint: Color,
                value: String, spark: [Double], deltaPct: Double) {
        self.titleKey = titleKey
        self.systemIcon = systemIcon
        self.tint = tint
        self.value = value
        self.spark = spark
        self.deltaPct = deltaPct
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: systemIcon)
                    .scaledFont(.caption, weight: .semibold)
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .background(tint.opacity(0.14),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(localizedKey: titleKey)
                    .scaledFont(.caption2, weight: .medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            Text(verbatim: value)
                .scaledFont(.title2, weight: .bold)
                .monospacedDigit()
                .environment(\.layoutDirection, .leftToRight)
            MiniSparkline(values: spark, tint: tint)
            HStack(spacing: 5) {
                TrendIndicator(pct: deltaPct, compact: true)
                Text("branch.vs_30d")
                    .scaledFont(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(0.05)))
        )
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.secondary.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
}

// MARK: - Trend indicator

/// "↑ 15.2%" / "↓ -2.4%" — green up, red down.
public struct TrendIndicator: View {
    private let pct: Double
    private let compact: Bool

    public init(pct: Double, compact: Bool = false) {
        self.pct = pct
        self.compact = compact
    }

    public var body: some View {
        let up = pct >= 0
        return HStack(spacing: 3) {
            Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                .scaledFont(.caption2, weight: .bold)
            Text(verbatim: String(format: "%+.1f%%", pct))
                .scaledFont(compact ? .caption2 : .subheadline, weight: .semibold)
                .monospacedDigit()
        }
        .foregroundStyle(up ? Color.secondaryAccent : Color.red)
        .environment(\.layoutDirection, .leftToRight)
    }
}

// MARK: - Grade ring

/// Large branch grade ring — letter grade + score, Apple-Fitness style.
public struct BranchGradeRing: View {
    private let grade: LetterGrade
    private let score: Double
    private let size: CGFloat

    public init(grade: LetterGrade, score: Double, size: CGFloat = 76) {
        self.grade = grade
        self.score = score
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle().stroke(grade.branchTint.opacity(0.15), lineWidth: size * 0.11)
            Circle()
                .trim(from: 0, to: min(1, max(0, score / 100)))
                .stroke(
                    LinearGradient(colors: [grade.branchTint, grade.branchTint.opacity(0.65)],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: grade.branchTint.opacity(0.3), radius: 4)
                .animation(.easeInOut(duration: 0.5), value: score)
            VStack(spacing: 0) {
                Text(verbatim: grade.label)
                    .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                    .foregroundStyle(grade.branchTint)
                Text(verbatim: String(format: NSLocalizedString("branch.score.fmt", comment: ""), score))
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Metric ring

/// Mini radial ring for one performance metric — score inside, label below.
public struct PerformanceMetricRing: View {
    private let kind: BranchMetricKind
    private let score: Double

    public init(kind: BranchMetricKind, score: Double) {
        self.kind = kind
        self.score = score
    }

    public var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle().stroke(kind.tint.opacity(0.16), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: min(1, max(0, score / 100)))
                    .stroke(kind.tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(verbatim: "\(Int(score.rounded()))")
                    .scaledFont(.caption2, weight: .bold, monospacedDigit: true)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(width: 44, height: 44)
            Text(localizedKey: kind.labelKey)
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Status chip

/// "Improving / Stable / Declining" pastel chip with a trend arrow.
public struct BranchStatusChip: View {
    private let trend: BranchTrend

    public init(_ trend: BranchTrend) {
        self.trend = trend
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.systemIcon)
                .scaledFont(.caption2, weight: .bold)
            Text(localizedKey: trend.labelKey)
                .scaledFont(.caption2, weight: .semibold)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(trend.tint.opacity(0.15), in: Capsule())
        .foregroundStyle(trend.tint)
    }
}

// MARK: - Rank badge

/// Soft pastel circular ranking badge (1 / 2 / 3 / …).
public struct RankBadge: View {
    private let rank: Int

    public init(_ rank: Int) {
        self.rank = rank
    }

    public var body: some View {
        Text(verbatim: "\(rank)")
            .scaledFont(.subheadline, weight: .bold, monospacedDigit: true)
            .foregroundStyle(tint)
            .frame(width: 30, height: 30)
            .background(tint.opacity(0.16), in: Circle())
            .overlay(Circle().stroke(tint.opacity(0.3), lineWidth: 1))
            .environment(\.layoutDirection, .leftToRight)
    }

    private var tint: Color {
        switch rank {
        case 1:  .orange
        case 2:  .accentColor
        case 3:  .cyan
        default: .secondary
        }
    }
}

// MARK: - Key insight card

/// Soft colored intelligence card — icon + a formatted insight sentence.
public struct KeyInsightCard: View {
    private let systemIcon: String
    private let tint: Color
    private let text: AttributedString

    public init(systemIcon: String, tint: Color, text: AttributedString) {
        self.systemIcon = systemIcon
        self.tint = tint
        self.text = text
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: systemIcon)
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.16),
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(text)
                .scaledFont(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

// MARK: - Section card

/// Rounded white card wrapper with an optional header used by the dashboard's
/// analytics sections (Athlete Distribution / Attendance Trend / …).
public struct BranchSectionCard<Content: View>: View {
    private let titleKey: String
    private let content: Content

    public init(titleKey: String, @ViewBuilder content: () -> Content) {
        self.titleKey = titleKey
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizedKey: titleKey)
                .scaledFont(.headline, weight: .semibold)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.secondary.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 5)
    }
}

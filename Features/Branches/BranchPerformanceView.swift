import SwiftUI

// MARK: - Branch Performance Overview
//
// Stage 1.11 — federation-grade executive dashboard. Header + executive
// analytics cards + branch performance ranking + key insights + the three
// comparison charts. Replaces the old progress-bar heat-map view.
//
// Composite / grade / the six metric scores are real averages of seeded
// performance data; growth, trends, the radar and the sparklines are
// demo-derived in `BranchAnalyticsEngine`.

public struct BranchPerformanceView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var hSize

    @State private var analytics: [BranchAnalytics] = []
    @State private var loading = true
    @State private var sort: BranchSort = .overall
    @State private var dateRange: BranchDateRange = .days30

    public init() {}

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        VStack(spacing: 0) {
            header
            if loading {
                Spacer(); ProgressView(); Spacer()
            } else {
                dashboard
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task { await load() }
    }

    // MARK: Header

    private var header: some View {
        Group {
            if isWide {
                HStack(alignment: .center, spacing: 12) {
                    titleBlock
                    Spacer(minLength: 8)
                    dateMenu
                    filterMenu
                    compareButton
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack { titleBlock; Spacer(minLength: 8); compareButton }
                    HStack(spacing: 8) { dateMenu; filterMenu; Spacer(minLength: 0) }
                }
            }
        }
        .padding(.horizontal, isWide ? 22 : 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("branch.overview.title").scaledFont(.title2, weight: .bold)
            Text("branch.overview.subtitle")
                .scaledFont(.caption).foregroundStyle(.secondary)
        }
    }

    private var dateMenu: some View {
        Menu {
            ForEach(BranchDateRange.allCases, id: \.self) { range in
                Button {
                    dateRange = range
                } label: {
                    if dateRange == range {
                        Label { Text(localizedKey: range.labelKey) }
                        icon: { Image(systemName: "checkmark") }
                    } else {
                        Text(localizedKey: range.labelKey)
                    }
                }
            }
        } label: {
            headerChip(icon: "calendar", titleKey: dateRange.labelKey, active: false)
        }
        .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
    }

    private var filterMenu: some View {
        Menu {
            Picker("branch.sort", selection: $sort) {
                ForEach(BranchSort.allCases, id: \.self) { s in
                    Text(localizedKey: s.labelKey).tag(s)
                }
            }
        } label: {
            headerChip(icon: "line.3.horizontal.decrease", titleKey: "branch.filter",
                       active: sort != .overall)
        }
        .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
    }

    private func headerChip(icon: String, titleKey: String, active: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).scaledFont(.caption, weight: .semibold)
            Text(localizedKey: titleKey).scaledFont(.subheadline, weight: .semibold)
        }
        .foregroundStyle(active ? Color.accentColor : Color.primary)
        .padding(.horizontal, 13).padding(.vertical, 8)
        .background(Capsule().fill(active ? Color.accentColor.opacity(0.14)
                                          : Color.secondary.opacity(0.10)))
        .overlay(Capsule().stroke(Color.secondary.opacity(0.16), lineWidth: 1))
    }

    private var compareButton: some View {
        Button {} label: {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.xaxis").scaledFont(.footnote, weight: .semibold)
                Text("branch.compare").scaledFont(.subheadline, weight: .semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(
                Capsule().fill(LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.82)],
                    startPoint: .top, endPoint: .bottom)))
            .shadow(color: Color.accentColor.opacity(0.32), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(true)
        .opacity(0.85)
    }

    // MARK: Dashboard

    private var dashboard: some View {
        ScrollView {
            VStack(spacing: 16) {
                analyticsRow
                // The ranking spans the full width; Key Insights sit beneath
                // it as a tile grid; the comparison charts follow.
                rankingCard
                insightsCard
                if isWide {
                    chartsRow
                } else {
                    chartsColumn
                }
            }
            .padding(.horizontal, isWide ? 22 : 14)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
    }

    // MARK: Executive analytics row

    private var analyticsRow: some View {
        let cols = isWide
            ? Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        let totalAthletes = analytics.reduce(0) { $0 + $1.athleteCount }
        let totalCoaches = analytics.reduce(0) { $0 + $1.coachCount }
        let avgComposite = analytics.isEmpty ? 0
            : analytics.reduce(0.0) { $0 + $1.compositeScore } / Double(analytics.count)
        let avgAttendance = analytics.isEmpty ? 0
            : analytics.reduce(0.0) { $0 + $1.metric(.attendance) } / Double(analytics.count)
        let avgGrowth = analytics.isEmpty ? 0
            : analytics.reduce(0.0) { $0 + $1.growthPct } / Double(analytics.count)
        return LazyVGrid(columns: cols, spacing: 12) {
            ExecutiveAnalyticsCard(titleKey: "branch.kpi.branches", systemIcon: "building.2.fill",
                                   tint: .accentColor, value: "\(analytics.count)",
                                   spark: spark(1, rising: true), deltaPct: 0)
            ExecutiveAnalyticsCard(titleKey: "branch.kpi.athletes", systemIcon: "person.3.fill",
                                   tint: .secondaryAccent, value: totalAthletes.formatted(),
                                   spark: spark(2, rising: true), deltaPct: 6.4)
            ExecutiveAnalyticsCard(titleKey: "branch.kpi.coaches", systemIcon: "figure.taekwondo",
                                   tint: .orange, value: "\(totalCoaches)",
                                   spark: spark(3, rising: true), deltaPct: 6.1)
            ExecutiveAnalyticsCard(titleKey: "branch.kpi.performance", systemIcon: "chart.line.uptrend.xyaxis",
                                   tint: .purple, value: LetterGrade.from(score: avgComposite).label,
                                   spark: spark(4, rising: true), deltaPct: 5.6)
            ExecutiveAnalyticsCard(titleKey: "branch.kpi.attendance", systemIcon: "heart.fill",
                                   tint: .pink, value: "\(Int(avgAttendance.rounded()))%",
                                   spark: spark(5, rising: true), deltaPct: 4.3)
            ExecutiveAnalyticsCard(titleKey: "branch.kpi.growth", systemIcon: "arrow.up.right",
                                   tint: .cyan, value: String(format: "%+.1f%%", avgGrowth),
                                   spark: spark(6, rising: avgGrowth >= 0), deltaPct: 3.3)
        }
    }

    /// Deterministic 12-point demo sparkline.
    private func spark(_ seed: Int, rising: Bool) -> [Double] {
        (0..<12).map { i in
            let t = Double(i) / 11.0
            let trend = (rising ? 1.0 : -1.0) * t * 26
            let wobble = sin(Double(i) * 1.7 + Double(seed)) * 7
            return 50 + trend + wobble
        }
    }

    // MARK: Ranking

    private var rankingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("branch.ranking.title").scaledFont(.headline, weight: .bold)
                Spacer(minLength: 8)
                Text(localizedKey: sort.labelKey)
                    .scaledFont(.caption, weight: .semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)
            Divider().opacity(0.5)
            LazyVStack(spacing: 0) {
                ForEach(Array(rankedAnalytics.enumerated()), id: \.element.id) { idx, a in
                    if idx > 0 { Divider().opacity(0.4) }
                    branchRow(a)
                }
            }
            .padding(8)
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.secondary.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }

    @ViewBuilder
    private func branchRow(_ a: BranchAnalytics) -> some View {
        if isWide {
            HStack(alignment: .center, spacing: 14) {
                RankBadge(a.rank)
                BranchGradeRing(grade: a.grade, score: a.compositeScore, size: 74)
                branchInfo(a).frame(width: 188, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    TrendIndicator(pct: a.growthPct)
                    Text("branch.growth_30d").scaledFont(.caption2).foregroundStyle(.secondary)
                }
                .frame(width: 96, alignment: .leading)
                metricRings(a)
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 6) {
                    BranchStatusChip(a.trend)
                    Text(verbatim: String(format: NSLocalizedString("branch.national_rank.fmt", comment: ""),
                                           a.nationalRank))
                        .scaledFont(.caption2).foregroundStyle(.secondary)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 12)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    RankBadge(a.rank)
                    BranchGradeRing(grade: a.grade, score: a.compositeScore, size: 64)
                    branchInfo(a)
                    Spacer(minLength: 0)
                }
                HStack {
                    TrendIndicator(pct: a.growthPct)
                    Text("branch.growth_30d").scaledFont(.caption2).foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    BranchStatusChip(a.trend)
                }
                metricRings(a)
            }
            .padding(.horizontal, 10).padding(.vertical, 12)
        }
    }

    private func branchInfo(_ a: BranchAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(verbatim: a.branch.name).scaledFont(.subheadline, weight: .bold).lineLimit(1)
            infoLine("person.3.fill", String(format: NSLocalizedString("branch.athletes.fmt", comment: ""), a.athleteCount))
            infoLine("figure.taekwondo", String(format: NSLocalizedString("branch.coaches.fmt", comment: ""), a.coachCount))
            infoLine("calendar", String(format: NSLocalizedString("branch.sessions.fmt", comment: ""), a.sessionsPerWeek))
        }
    }

    private func infoLine(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).scaledFont(.caption2).foregroundStyle(.tertiary).frame(width: 14)
            Text(verbatim: text).scaledFont(.caption2).foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private func metricRings(_ a: BranchAnalytics) -> some View {
        HStack(spacing: isWide ? 10 : 6) {
            ForEach(BranchMetricKind.allCases, id: \.self) { kind in
                PerformanceMetricRing(kind: kind, score: a.metric(kind))
            }
        }
    }

    // MARK: Insights

    private var insightsCard: some View {
        BranchSectionCard(titleKey: "branch.insights.title") {
            // Tile grid — two columns on iPad, single column on iPhone.
            let cols = isWide
                ? Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
                : [GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(insights) { insight in
                    KeyInsightCard(systemIcon: insightIcon(insight.kind),
                                   tint: insightTint(insight.kind),
                                   text: insightText(insight))
                }
            }
        }
    }

    private func insightIcon(_ kind: BranchInsight.Kind) -> String {
        switch kind {
        case .improvedAttendance: "chart.line.uptrend.xyaxis"
        case .topCompetition:     "trophy.fill"
        case .needsAttention:     "exclamationmark.triangle.fill"
        case .overallGrowth:      "chart.bar.fill"
        }
    }

    private func insightTint(_ kind: BranchInsight.Kind) -> Color {
        switch kind {
        case .improvedAttendance: .secondaryAccent
        case .topCompetition:     .accentColor
        case .needsAttention:     .orange
        case .overallGrowth:      .purple
        }
    }

    private func insightText(_ insight: BranchInsight) -> AttributedString {
        let key: String
        switch insight.kind {
        case .improvedAttendance: key = "branch.insight.attendance"
        case .topCompetition:     key = "branch.insight.competition"
        case .needsAttention:     key = "branch.insight.attention"
        case .overallGrowth:      key = "branch.insight.overall"
        }
        let raw: String
        if insight.kind == .overallGrowth {
            raw = String(format: NSLocalizedString(key, comment: ""), insight.value)
        } else {
            raw = String(format: NSLocalizedString(key, comment: ""),
                          insight.branchName, insight.value)
        }
        return (try? AttributedString(markdown: raw)) ?? AttributedString(raw)
    }

    // MARK: Charts

    private var chartsRow: some View {
        HStack(alignment: .top, spacing: 16) {
            BranchSectionCard(titleKey: "branch.dist.title") {
                AthleteDistributionChart(branches: analytics)
            }
            BranchSectionCard(titleKey: "branch.trend.title") {
                AttendanceTrendChart(branches: analytics)
            }
            BranchSectionCard(titleKey: "branch.coaching.title") {
                CoachingRadarChart(branches: analytics)
            }
        }
    }

    private var chartsColumn: some View {
        VStack(spacing: 16) {
            BranchSectionCard(titleKey: "branch.dist.title") {
                AthleteDistributionChart(branches: analytics)
            }
            BranchSectionCard(titleKey: "branch.trend.title") {
                AttendanceTrendChart(branches: analytics)
            }
            BranchSectionCard(titleKey: "branch.coaching.title") {
                CoachingRadarChart(branches: analytics)
            }
        }
    }

    // MARK: Data

    private var rankedAnalytics: [BranchAnalytics] {
        switch sort {
        case .overall:     return analytics
        case .competition: return analytics.sorted { $0.metric(.competition) > $1.metric(.competition) }
        case .attendance:  return analytics.sorted { $0.metric(.attendance) > $1.metric(.attendance) }
        case .growth:      return analytics.sorted { $0.growthPct > $1.growthPct }
        case .wellness:    return analytics.sorted { $0.metric(.wellness) > $1.metric(.wellness) }
        }
    }

    private var insights: [BranchInsight] {
        let avgGrowth = analytics.isEmpty ? 0
            : analytics.reduce(0.0) { $0 + $1.growthPct } / Double(analytics.count)
        return BranchAnalyticsEngine.insights(analytics, overallGrowth: avgGrowth)
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            let branches = try await session.repository.branches()
            var inputs: [BranchAnalyticsEngine.Input] = []
            for b in branches {
                let scores = try await session.repository.scores(branchID: b.id)
                let aths = try await session.repository.athletes(branchID: b.id)
                let coaches = try await session.repository.coaches(branchID: b.id)
                inputs.append(.init(
                    branch: b, scores: scores,
                    athleteCount: aths.count, coachCount: coaches.count,
                    sessionsPerWeek: coaches.count + aths.count / 80
                ))
            }
            analytics = BranchAnalyticsEngine.analyze(inputs)
        } catch {
            print("BranchPerformanceView.load:", error)
        }
    }
}

// MARK: - Sort & range

enum BranchSort: String, CaseIterable, Hashable {
    case overall, competition, attendance, growth, wellness
    var labelKey: String { "branch.sort.\(rawValue)" }
}

enum BranchDateRange: String, CaseIterable, Hashable {
    case days30, days90, year
    var labelKey: String { "branch.range.\(rawValue)" }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let f = pow(10.0, Double(places))
        return (self * f).rounded() / f
    }
}

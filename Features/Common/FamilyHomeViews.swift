import SwiftUI

// MARK: - Athlete home
//
// Stage 1.13 executive remodel. Greeting hero + a personal executive
// analytics row (composite + the five performance metrics) + a performance
// card (grade ring + insights + 12-week trend) + next class + recent
// activity + find-branch shortcut. Performance intel reuses `AthleteIntel`.

public struct AthleteHomeView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var athlete: Athlete?
    @State private var intel: AthleteIntel?
    @State private var nextSession: ClassSession?
    @State private var showingFindBranch = false

    public init() {}

    private var isWide: Bool { sizeClass == .regular }

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let user = session.currentUser {
                    GreetingHero(
                        fullName: user.fullName,
                        fullNameAr: user.fullNameAr,
                        roleLabel: NSLocalizedString("role.\(user.role.rawValue)", comment: ""),
                        subtitleKey: "athlete.home.subtitle"
                    )
                }
                if let intel {
                    analyticsRow(intel)
                    performanceCard(intel)
                }
                nextClassCard
                if let intel {
                    recentActivityCard(intel)
                }
                findBranchCard
            }
            .padding(.horizontal, isWide ? 20 : 14)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .demoRoleSwitcher()
        .sheet(isPresented: $showingFindBranch) {
            NavigationStack { BranchListView() }
        }
        .task { await load() }
    }

    // MARK: Analytics

    private func analyticsRow(_ intel: AthleteIntel) -> some View {
        LazyVGrid(columns: homeAnalyticsColumns(isWide: isWide), spacing: 12) {
            ExecutiveAnalyticsCard(titleKey: "athlete.home.kpi.score",
                                   systemIcon: "rosette", tint: intel.grade.branchTint,
                                   value: String(format: "%.0f", intel.composite),
                                   spark: homeSpark(1), deltaPct: 6.4)
            metricCard(intel, .attendance, "shield.lefthalf.filled", 2, 4.1)
            metricCard(intel, .progress, "arrow.up.forward.circle.fill", 3, 8.7)
            metricCard(intel, .discipline, "brain.head.profile", 4, 2.9)
            metricCard(intel, .fitness, "bolt.heart.fill", 5, 5.5)
            metricCard(intel, .competition, "trophy.fill", 6, 7.2)
        }
    }

    private func metricCard(_ intel: AthleteIntel, _ kind: AthleteMetricKind,
                            _ icon: String, _ seed: Int, _ delta: Double) -> some View {
        ExecutiveAnalyticsCard(titleKey: kind.labelKey, systemIcon: icon, tint: kind.tint,
                               value: "\(Int(intel.metric(kind).rounded()))",
                               spark: homeSpark(seed), deltaPct: delta)
    }

    // MARK: Performance card

    private func performanceCard(_ intel: AthleteIntel) -> some View {
        SectionCard("athlete.home.performance", icon: "chart.line.uptrend.xyaxis", trailing: {
            if let athlete {
                NavigationLink {
                    AthleteDetailView(athlete: athlete)
                } label: {
                    HStack(spacing: 3) {
                        Text("athlete.view_profile")
                            .scaledFont(.caption2, weight: .semibold)
                        Image(systemName: "chevron.right")
                            .scaledFont(.caption2, weight: .semibold)
                            .flipsForRightToLeftLayoutDirection(true)
                    }
                    .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
        }, content: {
            VStack(spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    AthleteGradeRing(grade: intel.grade, score: intel.composite, size: 80)
                    VStack(spacing: 8) {
                        AthleteInsightCard(
                            systemIcon: "star.fill", tint: .secondaryAccent,
                            text: insightText("athlete.home.insight.strong.fmt", strongestMetric(intel)))
                        AthleteInsightCard(
                            systemIcon: "scope", tint: .orange,
                            text: insightText("athlete.home.insight.focus.fmt", weakestMetric(intel)))
                    }
                }
                AthletePerformanceTrendChart(values: intel.perfTrend, tint: intel.grade.branchTint)
            }
        })
    }

    private func insightText(_ formatKey: String, _ metric: AthleteMetricKind) -> AttributedString {
        let name = NSLocalizedString(metric.labelKey, comment: "")
        return AttributedString(String(format: NSLocalizedString(formatKey, comment: ""), name))
    }

    private func strongestMetric(_ intel: AthleteIntel) -> AthleteMetricKind {
        intel.metrics.max { $0.score < $1.score }?.kind ?? .attendance
    }

    private func weakestMetric(_ intel: AthleteIntel) -> AthleteMetricKind {
        intel.metrics.min { $0.score < $1.score }?.kind ?? .competition
    }

    // MARK: Next class

    private var nextClassCard: some View {
        SectionCard("heading.next_class", icon: "calendar.badge.clock") {
            if let s = nextSession {
                HStack(spacing: 12) {
                    VStack(spacing: 0) {
                        Text(s.startsAt, format: .dateTime.hour())
                            .scaledFont(.title3, weight: .bold, monospacedDigit: true)
                            .environment(\.layoutDirection, .leftToRight)
                        Text(s.startsAt, format: .dateTime.minute())
                            .scaledFont(.caption2, monospacedDigit: true)
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    .frame(width: 54)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: s.title)
                            .scaledFont(.subheadline, weight: .semibold)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Text(localizedKey: s.discipline.labelKey)
                            Text(verbatim: "·")
                            Text(s.startsAt, format: .dateTime.weekday(.wide).day().month(.abbreviated))
                                .environment(\.layoutDirection, .leftToRight)
                        }
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            } else {
                EmptyStateCard(icon: "calendar",
                               titleKey: "empty.no_classes_today",
                               messageKey: "athlete.home.no_class.message")
            }
        }
    }

    // MARK: Recent activity

    private func recentActivityCard(_ intel: AthleteIntel) -> some View {
        SectionCard("athlete.recent_activity", icon: "clock.arrow.circlepath") {
            VStack(spacing: 8) {
                ForEach(intel.recentActivity) { item in
                    HomeActivityRow(
                        icon: item.kind.systemIcon,
                        tint: item.done ? .secondaryAccent : .orange,
                        title: NSLocalizedString(item.kind.labelKey, comment: ""),
                        timeText: item.dateText)
                    if item.id != intel.recentActivity.last?.id {
                        Divider().opacity(0.3)
                    }
                }
            }
        }
    }

    // MARK: Find branch

    private var findBranchCard: some View {
        Button { showingFindBranch = true } label: {
            findBranchContent
        }
        .buttonStyle(.plain)
    }

    private func load() async {
        guard let userID = session.currentUser?.id else { return }
        do {
            guard let athlete = try await session.repository.athlete(id: userID) else { return }
            self.athlete = athlete
            let score = try? await session.repository.score(athleteID: athlete.id)
            let branches = try await session.repository.branches()
            let branchName = branches.first { $0.id == athlete.branchID }?.name
                ?? NSLocalizedString("admin.no_branch", comment: "")
            intel = AthleteIntel.make(athlete: athlete, score: score, branchName: branchName)
            let sessions = try await session.repository.sessions(branchID: athlete.branchID, on: Date())
            nextSession = sessions.first { $0.startsAt > Date() } ?? sessions.first
        } catch {
            print("AthleteHomeView.load:", error)
        }
    }
}

// MARK: - Parent home
//
// Stage 1.13 executive remodel. Greeting hero + an aggregate analytics row
// across the linked children + a rich card per child (the shared
// `AthletePerformanceCard`) + find-branch shortcut.

public struct ParentHomeView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var childIntels: [AthleteIntel] = []
    @State private var loaded = false
    @State private var showingFindBranch = false

    public init() {}

    private var isWide: Bool { sizeClass == .regular }

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let user = session.currentUser {
                    GreetingHero(
                        fullName: user.fullName,
                        fullNameAr: user.fullNameAr,
                        roleLabel: NSLocalizedString("role.\(user.role.rawValue)", comment: ""),
                        subtitleKey: "parent.home.subtitle"
                    )
                }
                if !childIntels.isEmpty {
                    analyticsRow
                }
                childrenCard
                findBranchCard
            }
            .padding(.horizontal, isWide ? 20 : 14)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .demoRoleSwitcher()
        .sheet(isPresented: $showingFindBranch) {
            NavigationStack { BranchListView() }
        }
        .task { await load() }
    }

    // MARK: Analytics

    private var analyticsRow: some View {
        LazyVGrid(columns: homeAnalyticsColumns(isWide: isWide, wideCount: 4), spacing: 12) {
            ExecutiveAnalyticsCard(titleKey: "parent.home.kpi.children",
                                   systemIcon: "figure.2.and.child.holdinghands", tint: .accentColor,
                                   value: "\(childIntels.count)",
                                   spark: homeSpark(1), deltaPct: 0)
            ExecutiveAnalyticsCard(titleKey: "parent.home.kpi.score",
                                   systemIcon: "chart.line.uptrend.xyaxis", tint: .secondaryAccent,
                                   value: String(format: "%.0f", avgComposite),
                                   spark: homeSpark(2), deltaPct: 5.8)
            ExecutiveAnalyticsCard(titleKey: "parent.home.kpi.attendance",
                                   systemIcon: "shield.lefthalf.filled", tint: .cyan,
                                   value: "\(Int(avgMetric(.attendance).rounded()))%",
                                   spark: homeSpark(3), deltaPct: 3.4)
            ExecutiveAnalyticsCard(titleKey: "parent.home.kpi.progress",
                                   systemIcon: "arrow.up.forward.circle.fill", tint: .orange,
                                   value: "\(Int(avgMetric(.progress).rounded()))",
                                   spark: homeSpark(4), deltaPct: 6.1)
        }
    }

    private var avgComposite: Double {
        let xs = childIntels.map(\.composite)
        return xs.isEmpty ? 0 : xs.reduce(0, +) / Double(xs.count)
    }

    private func avgMetric(_ kind: AthleteMetricKind) -> Double {
        let xs = childIntels.map { $0.metric(kind) }
        return xs.isEmpty ? 0 : xs.reduce(0, +) / Double(xs.count)
    }

    // MARK: Children

    private var childrenCard: some View {
        SectionCard("heading.athletes", icon: "person.2.fill") {
            if childIntels.isEmpty {
                EmptyStateCard(
                    icon: "person.crop.circle.badge.questionmark",
                    titleKey: loaded ? "empty.no_linked_athletes" : "common.loading",
                    messageKey: loaded ? "parent.home.empty.message" : nil)
            } else {
                VStack(spacing: 10) {
                    ForEach(childIntels) { intel in
                        NavigationLink {
                            AthleteDetailView(athlete: intel.athlete)
                        } label: {
                            AthletePerformanceCard(intel: intel, selected: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Find branch

    private var findBranchCard: some View {
        Button { showingFindBranch = true } label: {
            findBranchContent
        }
        .buttonStyle(.plain)
    }

    private func load() async {
        do {
            let all = try await session.repository.athletes()
            let children = Array(all.prefix(2))
            let scores = try await session.repository.allScores()
            let scoreByID = Dictionary(uniqueKeysWithValues: scores.map { ($0.athleteID, $0) })
            let branches = try await session.repository.branches()
            let branchNames = Dictionary(uniqueKeysWithValues: branches.map { ($0.id, $0.name) })
            childIntels = children.map { child in
                AthleteIntel.make(
                    athlete: child,
                    score: scoreByID[child.id],
                    branchName: branchNames[child.branchID]
                        ?? NSLocalizedString("admin.no_branch", comment: ""))
            }
        } catch {
            print("ParentHomeView.load:", error)
        }
        loaded = true
    }
}

// MARK: - Shared find-branch shortcut

/// The find-a-branch shortcut card shared by the Athlete and Parent homes.
private var findBranchContent: some View {
    SectionCard {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentColor.opacity(0.14))
                Image(systemName: "mappin.and.ellipse")
                    .scaledFont(.title3)
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("find_branch.title")
                    .scaledFont(.subheadline, weight: .semibold)
                Text("find_branch.subtitle")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
                .flipsForRightToLeftLayoutDirection(true)
        }
    }
}

// MARK: - My schedule

public struct MyScheduleView: View {
    @Environment(AppSession.self) private var session
    @State private var sessions: [ClassSession] = []
    @State private var branches: [EntityID: Branch] = [:]

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                if sessions.isEmpty {
                    Text("empty.no_classes_today").foregroundStyle(.secondary)
                } else {
                    ForEach(sessions) { s in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: s.title).scaledFont(.headline)
                            HStack(spacing: 6) {
                                Text(s.startsAt, style: .time)
                                Text(verbatim: "→")
                                Text(s.endsAt, style: .time)
                                Spacer()
                                Text(localizedKey: s.discipline.labelKey)
                                    .scaledFont(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let branch = branches[s.branchID] {
                                Text(verbatim: branch.name).scaledFont(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        guard let userID = session.currentUser?.id else { return }
        do {
            if let athlete = try await session.repository.athlete(id: userID) {
                sessions = try await session.repository.sessions(branchID: athlete.branchID, on: Date())
            } else if let branchID = session.currentUser?.primaryBranchID {
                sessions = try await session.repository.sessions(branchID: branchID, on: Date())
            } else if let first = session.branches.first {
                sessions = try await session.repository.sessions(branchID: first.id, on: Date())
            }
            let bs = try await session.repository.branches()
            branches = Dictionary(uniqueKeysWithValues: bs.map { ($0.id, $0) })
        } catch {
            print("MyScheduleView.load:", error)
        }
    }
}

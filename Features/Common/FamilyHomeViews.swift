import SwiftUI

public struct AthleteHomeView: View {
    @Environment(AppSession.self) private var session
    @State private var athlete: Athlete?
    @State private var nextSession: ClassSession?
    @State private var todaySessions: [ClassSession] = []
    @State private var showingFindBranch = false

    public init() {}

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
                if let athlete {
                    athleteSummaryCard(athlete)
                }
                nextClassCard
                findBranchCard
            }
            .padding(.horizontal, 14)
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

    private func athleteSummaryCard(_ athlete: Athlete) -> some View {
        SectionCard("athlete.home.your_profile", icon: "person.text.rectangle.fill") {
            HStack(spacing: 14) {
                Avatar(seed: athlete.avatarSeed, label: athlete.initials, size: 56, urlString: athlete.avatarURL)
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: athlete.fullName)
                        .scaledFont(.subheadline, weight: .semibold)
                    HStack(spacing: 6) {
                        CategoryBadge(
                            value: NSLocalizedString(athlete.currentBelt.color.labelKey, comment: ""),
                            tone: athlete.currentBelt.color == .black ? .dark : .neutral,
                            icon: "circle.hexagongrid.fill"
                        )
                        StatusPill(status: athlete.status)
                    }
                }
                Spacer(minLength: 0)
                NavigationLink {
                    AthleteDetailView(athlete: athlete)
                } label: {
                    Image(systemName: "chevron.right")
                        .scaledFont(.subheadline, weight: .semibold)
                        .foregroundStyle(.secondary)
                        .flipsForRightToLeftLayoutDirection(true)
                }
                .buttonStyle(.plain)
            }
        }
    }

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
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                EmptyStateCard(
                    icon: "calendar",
                    titleKey: "empty.no_classes_today",
                    messageKey: "athlete.home.no_class.message"
                )
            }
        }
    }

    private var findBranchCard: some View {
        Button {
            showingFindBranch = true
        } label: {
            SectionCard {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.accentColor.opacity(0.14))
                        Image(systemName: "mappin.and.ellipse")
                            .scaledFont(.title3)
                            .foregroundStyle(.tint)
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
        .buttonStyle(.plain)
    }

    private func load() async {
        guard let userID = session.currentUser?.id else { return }
        do {
            if let athlete = try await session.repository.athlete(id: userID) {
                self.athlete = athlete
                let sessions = try await session.repository.sessions(branchID: athlete.branchID, on: Date())
                todaySessions = sessions
                nextSession = sessions.first { $0.startsAt > Date() } ?? sessions.first
            }
        } catch {
            print("AthleteHomeView.load:", error)
        }
    }
}

public struct ParentHomeView: View {
    @Environment(AppSession.self) private var session
    @State private var children: [Athlete] = []
    @State private var showingFindBranch = false

    public init() {}

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
                childrenCard
                findBranchCard
            }
            .padding(.horizontal, 14)
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

    private var childrenCard: some View {
        SectionCard("heading.athletes", icon: "person.2.fill") {
            if children.isEmpty {
                EmptyStateCard(
                    icon: "person.crop.circle.badge.questionmark",
                    titleKey: "empty.no_linked_athletes",
                    messageKey: "parent.home.empty.message"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(children) { child in
                        NavigationLink(destination: AthleteDetailView(athlete: child)) {
                            childRow(child)
                        }
                        .buttonStyle(.plain)
                        if child.id != children.last?.id {
                            Divider().opacity(0.3)
                        }
                    }
                }
            }
        }
    }

    private func childRow(_ athlete: Athlete) -> some View {
        HStack(spacing: 12) {
            Avatar(seed: athlete.avatarSeed, label: athlete.initials, size: 44, urlString: athlete.avatarURL)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: athlete.fullName)
                    .scaledFont(.subheadline, weight: .semibold)
                HStack(spacing: 6) {
                    Text(localizedKey: athlete.currentBelt.color.labelKey)
                        .scaledFont(.caption2)
                    Text(verbatim: "·")
                        .scaledFont(.caption2)
                    Text(localizedKey: athlete.ageGroup.labelKey)
                        .scaledFont(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            StatusPill(status: athlete.status)
            Image(systemName: "chevron.right")
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var findBranchCard: some View {
        Button {
            showingFindBranch = true
        } label: {
            SectionCard {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.accentColor.opacity(0.14))
                        Image(systemName: "mappin.and.ellipse")
                            .scaledFont(.title3)
                            .foregroundStyle(.tint)
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
        .buttonStyle(.plain)
    }

    private func load() async {
        do {
            let all = try await session.repository.athletes()
            children = Array(all.prefix(2))
        } catch {
            print("ParentHomeView.load:", error)
        }
    }
}

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


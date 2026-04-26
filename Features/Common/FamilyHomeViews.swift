import SwiftUI

public struct AthleteHomeView: View {
    @Environment(AppSession.self) private var session
    @State private var nextSession: ClassSession?

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let user = session.currentUser {
                        Text("greeting.morning").font(.title3).foregroundStyle(.secondary)
                        Text(verbatim: user.fullName).font(.largeTitle.bold())
                    }
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                Text("heading.next_class").font(.subheadline.bold())
                                Spacer()
                            }
                            if let s = nextSession {
                                Text(verbatim: s.title)
                                HStack {
                                    Text(s.startsAt, style: .time)
                                    Text("→")
                                    Text(s.endsAt, style: .time)
                                }
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            } else {
                                Text("empty.no_classes_today").foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding()
            }
            .navigationTitle(Text("tab.home"))
            .demoRoleSwitcher()
        }
        .task { await load() }
    }

    private func load() async {
        guard let userID = session.currentUser?.id else { return }
        do {
            if let athlete = try await session.repository.athlete(id: userID) {
                let sessions = try await session.repository.sessions(branchID: athlete.branchID, on: Date())
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

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                if let user = session.currentUser {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("greeting.morning").font(.title3).foregroundStyle(.secondary)
                            Text(verbatim: user.fullName).font(.title2.bold())
                        }
                    }
                }
                Section(header: Text("heading.athletes")) {
                    if children.isEmpty {
                        Text("empty.no_linked_athletes").foregroundStyle(.secondary)
                    } else {
                        ForEach(children) { c in
                            NavigationLink(destination: AthleteDetailView(athlete: c)) {
                                HStack(spacing: 12) {
                                    Avatar(seed: c.avatarSeed, label: c.initials)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(verbatim: c.fullName)
                                        Text(LocalizedStringKey(c.currentBelt.label))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("tab.home"))
            .demoRoleSwitcher()
        }
        .task { await load() }
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
                            Text(verbatim: s.title).font(.headline)
                            HStack(spacing: 6) {
                                Text(s.startsAt, style: .time)
                                Text(verbatim: "→")
                                Text(s.endsAt, style: .time)
                                Spacer()
                                Text(LocalizedStringKey(s.discipline.labelKey))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let branch = branches[s.branchID] {
                                Text(verbatim: branch.name).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("tab.schedule"))
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

public struct MoreView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: $appLanguage) {
                        Text("language.system").tag("system")
                        Text("language.english").tag("en")
                        Text("language.arabic").tag("ar")
                    } label: {
                        Text("settings.language")
                    }
                } header: {
                    Text("settings.language")
                }
                Section(header: Text("settings.about")) {
                    HStack {
                        Text("settings.about")
                        Spacer()
                        Text(verbatim: "SHJSDSC v1.0").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(Text("tab.more"))
        }
    }
}

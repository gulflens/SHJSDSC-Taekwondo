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
    @Environment(AppSession.self) private var session
    @Environment(\.notificationScheduler) private var notificationScheduler
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    @State private var exportShareURL: URL?
    @State private var firingTest = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("settings.language")) {
                    Picker(selection: $appLanguage) {
                        Text("language.system").tag("system")
                        Text("language.english").tag("en")
                        Text("language.arabic").tag("ar")
                    } label: {
                        Text("settings.language")
                    }
                }
                Section {
                    NavigationLink(destination: NotificationsCenterView()) {
                        Label("settings.notifications", systemImage: "bell")
                    }
                    Button {
                        Task { await fireTestDigest() }
                    } label: {
                        if firingTest {
                            HStack { ProgressView(); Text("settings.fire_test") }
                        } else {
                            Label("settings.fire_test", systemImage: "bolt.badge.clock")
                        }
                    }
                }
                if let role = session.currentUser?.role {
                    if role == .developer || role == .admin || role == .technicalDirector {
                        Section(header: Text("admin.accounts")) {
                            NavigationLink(destination: AdminCreateAccountView()) {
                                Label("admin.create_account", systemImage: "person.badge.plus")
                            }
                        }
                        Section(header: Text("settings.manage")) {
                            NavigationLink(destination: AnnouncementsView()) {
                                Label("tab.announcements", systemImage: "megaphone")
                            }
                            NavigationLink(destination: CoachListView()) {
                                Label("tab.coaches", systemImage: "person.crop.rectangle.stack.fill")
                            }
                            NavigationLink(destination: GradingDashboardView()) {
                                Label("tab.grading", systemImage: "medal")
                            }
                        }
                    }
                    if PermissionMatrix.allowed(role: role, permission: .viewAuditLog) {
                        Section {
                            NavigationLink(destination: AuditLogView()) {
                                Label("audit.title", systemImage: "list.bullet.rectangle")
                            }
                        }
                    }
                    Section {
                        NavigationLink(destination: CertificationsListView()) {
                            Label("tab.certifications", systemImage: "checkmark.shield")
                        }
                    }
                }
                Section(header: Text("settings.privacy")) {
                    Link(destination: URL(string: "https://gulflens.studio/privacy")!) {
                        Label("settings.privacy", systemImage: "hand.raised")
                    }
                }
                Section(header: Text("settings.about")) {
                    HStack {
                        Text("settings.about")
                        Spacer()
                        Text(verbatim: "SHJSDSC v1.0 · gulflens.studio").foregroundStyle(.secondary).font(.caption)
                    }
                }
                Section {
                    Button {
                        Task { await exportMyData() }
                    } label: {
                        Label("settings.export_data", systemImage: "square.and.arrow.down.on.square")
                    }
                    if let url = exportShareURL {
                        ShareLink(item: url) {
                            Label("export.share", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button(role: .destructive) {
                        Task { await session.signOut() }
                    } label: {
                        Label("settings.sign_out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                if session.currentUser?.role == .developer {
                    Section(header: Text("settings.developer")) {
                        Toggle("settings.use_demo_data", isOn: Binding(
                            get: {
                                let hasSet = UserDefaults.standard.object(forKey: "useDemoData") != nil
                                return hasSet ? UserDefaults.standard.bool(forKey: "useDemoData") : true
                            },
                            set: { newValue in
                                UserDefaults.standard.set(newValue, forKey: "useDemoData")
                                Task { await wipeLocalState() }
                            }
                        ))
                        Text("settings.use_demo_data_help").font(.caption2).foregroundStyle(.secondary)

                        Button(role: .destructive) {
                            Task { await wipeLocalState() }
                        } label: {
                            Label("settings.wipe_local", systemImage: "trash")
                        }
                        Text("settings.wipe_local_help").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(Text("settings.title"))
        }
    }

    private func fireTestDigest() async {
        firingTest = true
        defer { firingTest = false }
        do {
            let title = String(localized: "notif.sunday_digest.title")
            let body = String(localized: "notif.sunday_digest.body_test")
            try await notificationScheduler.scheduleLocal(
                id: "sunday-digest-test",
                title: title,
                body: body,
                fireAt: Date().addingTimeInterval(5)
            )
        } catch {
            print("MoreView.fireTestDigest:", error)
        }
    }

    private func exportMyData() async {
        guard let user = session.currentUser else { return }
        do {
            let athlete = try? await session.repository.athlete(id: user.id)
            let registrations = try await session.repository.registrations(athleteID: user.id)
            let matches = try await session.repository.matches(athleteID: user.id)
            let exporter = CSVReportExporter()
            let data = exporter.exportMyData(
                user: user,
                athlete: athlete,
                registrations: registrations,
                matches: matches
            )
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("my-data.json")
            try data.write(to: url)
            exportShareURL = url
        } catch {
            print("MoreView.exportMyData:", error)
        }
    }

    /// Resets local-only state without touching the backend:
    /// • Cancels every queued local notification (Sunday digest, cert
    ///   expiries, test fires) so old data doesn't keep firing alerts.
    /// • Forgets the remembered user id so the next launch lands on
    ///   SignInView instead of auto-restoring the previous identity.
    /// • Signs out of the current session.
    /// • Wipes the documents/athletePhotos cache so demo-mode photos
    ///   don't leak across resets.
    /// The new repository (DemoRepository or SupabaseRepository) is
    /// chosen at the next app launch — force-quit and reopen for the
    /// "Use demo data" toggle to actually swap backends.
    private func wipeLocalState() async {
        for kind in NotificationKind.allCases {
            await notificationScheduler.cancel(id: kind.rawValue)
        }
        await notificationScheduler.cancel(id: "sunday-digest")
        await notificationScheduler.cancel(id: "sunday-digest-test")

        UserDefaults.standard.removeObject(forKey: "rememberedUserID")
        UserDefaults.standard.removeObject(forKey: "hasRequestedNotifAuth")

        if let documents = try? FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false
        ) {
            let photosDir = documents.appendingPathComponent("athletePhotos", isDirectory: true)
            try? FileManager.default.removeItem(at: photosDir)
        }

        await session.signOut()
    }
}

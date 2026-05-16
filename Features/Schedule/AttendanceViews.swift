import SwiftUI

public struct AttendanceListView: View {
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
                        NavigationLink(destination: AttendanceMarkView(session: s)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(verbatim: s.title).scaledFont(.headline)
                                HStack(spacing: 6) {
                                    Text(s.startsAt, style: .time)
                                    Text(verbatim: "→")
                                    Text(s.endsAt, style: .time)
                                }
                                .scaledFont(.caption)
                                .foregroundStyle(.secondary)
                                if let b = branches[s.branchID] {
                                    Text(verbatim: b.name).scaledFont(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        guard let coachID = session.currentUser?.id else { return }
        do {
            sessions = try await session.repository.sessions(coachID: coachID, on: Date())
            let bs = try await session.repository.branches()
            branches = Dictionary(uniqueKeysWithValues: bs.map { ($0.id, $0) })
        } catch {
            print("AttendanceListView.load:", error)
        }
    }
}

public struct AttendanceMarkView: View {
    @Environment(AppSession.self) private var appSession
    public let session: ClassSession
    @State private var athletes: [Athlete] = []
    @State private var marks: [EntityID: AttendanceState] = [:]
    @State private var saving: Bool = false
    @State private var saved: Bool = false

    public init(session: ClassSession) { self.session = session }

    public var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: session.title).scaledFont(.headline)
                        HStack(spacing: 6) {
                            Text(session.startsAt, style: .time)
                            Text(verbatim: "→")
                            Text(session.endsAt, style: .time)
                            Spacer()
                            Text(localizedKey: session.discipline.labelKey).scaledFont(.caption, weight: .bold)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                Section(header: Text("heading.athletes")) {
                    if athletes.isEmpty {
                        Text("empty.no_athletes_flagged").foregroundStyle(.secondary)
                    } else {
                        ForEach(athletes) { a in
                            HStack(spacing: 12) {
                                Avatar(seed: a.avatarSeed, label: a.initials, size: 32)
                                Text(verbatim: a.fullName)
                                Spacer()
                                Picker(selection: binding(for: a.id)) {
                                    ForEach(AttendanceState.allCases, id: \.self) { st in
                                        Text(localizedKey: st.labelKey).tag(Optional(st))
                                    }
                                } label: { EmptyView() }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: 130)
                            }
                        }
                    }
                }
            }
            saveBar
        }
        .navigationTitle(Text("tab.classes"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await load() }
    }

    private var saveBar: some View {
        HStack {
            if saved {
                Label("action.saved", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            Spacer()
            Button {
                Task { await save() }
            } label: {
                if saving {
                    ProgressView()
                } else {
                    Text("action.save")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(saving)
        }
        .padding()
        .background(.bar)
    }

    private func binding(for id: EntityID) -> Binding<AttendanceState?> {
        Binding(
            get: { marks[id] },
            set: { marks[id] = $0 }
        )
    }

    private func load() async {
        do {
            let all = try await appSession.repository.athletes()
            let enrolled = Set(session.enrolledAthleteIDs)
            athletes = all.filter { enrolled.contains($0.id) }
            let existing = try await appSession.repository.attendance(sessionID: session.id)
            for r in existing { marks[r.athleteID] = r.state }
            for a in athletes where marks[a.id] == nil { marks[a.id] = .present }
        } catch {
            print("AttendanceMarkView.load:", error)
        }
    }

    private func save() async {
        saving = true
        saved = false
        defer { saving = false }
        do {
            let records = marks.map { (athleteID, state) in
                AttendanceRecord(sessionID: session.id, athleteID: athleteID, state: state, recordedAt: Date())
            }
            try await appSession.repository.upsertAttendance(records)
            saved = true
        } catch {
            print("AttendanceMarkView.save:", error)
        }
    }
}

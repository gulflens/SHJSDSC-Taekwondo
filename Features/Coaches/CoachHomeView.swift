import SwiftUI

public struct CoachHomeView: View {
    @Environment(AppSession.self) private var session
    @State private var store: ScheduleStore?

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if let store {
                    content(store: store)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(Text("tab.home"))
            .demoRoleSwitcher()
        }
        .task {
            if store == nil { store = ScheduleStore(repository: session.repository) }
            guard let store, let coachID = session.currentUser?.id else { return }
            await store.loadCoachDay(coachID: coachID)
        }
    }

    @ViewBuilder
    private func content(store: ScheduleStore) -> some View {
        List {
            if let user = session.currentUser {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("greeting.morning").font(.title3).foregroundStyle(.secondary)
                        Text(verbatim: user.fullName).font(.title2.bold())
                    }
                }
            }
            Section(header: Text("heading.today")) {
                if store.sessionsToday.isEmpty {
                    Text("empty.no_classes_today").foregroundStyle(.secondary)
                } else {
                    ForEach(store.sessionsToday) { s in
                        NavigationLink(destination: AttendanceMarkView(session: s)) {
                            CoachClassRow(session: s, branch: store.branchLookup[s.branchID])
                        }
                    }
                }
            }
        }
    }
}

private struct CoachClassRow: View {
    let session: ClassSession
    let branch: Branch?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: session.title).font(.headline)
                HStack(spacing: 6) {
                    Text(session.startsAt, style: .time)
                    Text(verbatim: "→")
                    Text(session.endsAt, style: .time)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if let branch {
                    Text(verbatim: branch.name).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(LocalizedStringKey(session.discipline.labelKey))
                    .font(.caption.bold())
                Text(verbatim: "\(session.enrolledAthleteIDs.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

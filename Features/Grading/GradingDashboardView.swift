import SwiftUI

public struct GradingDashboardView: View {
    @Environment(AppSession.self) private var session
    @State private var store: GradingStore?
    @State private var ready: [(athlete: Athlete, eligibility: GradingEligibility)] = []
    @State private var coachLookup: [EntityID: Coach] = [:]
    @State private var branchLookup: [EntityID: Branch] = [:]
    @State private var showSchedule = false

    public init() {}

    public var body: some View {
        Group {
            if let store {
                content(store: store)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(Text("grading.dashboard"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSchedule = true
                } label: {
                    Label("grading.schedule", systemImage: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showSchedule) {
            NavigationStack {
                ScheduleGradingView { newSession in
                    Task {
                        await store?.saveSession(newSession)
                        await reload()
                    }
                }
            }
        }
        .task {
            if store == nil { store = GradingStore(repository: session.repository) }
            await reload()
        }
    }

    @ViewBuilder
    private func content(store: GradingStore) -> some View {
        List {
            Section(header: Text("heading.upcoming_sessions")) {
                if store.sessions.isEmpty {
                    Text("empty.no_sessions").foregroundStyle(.secondary)
                } else {
                    ForEach(store.sessions) { s in
                        NavigationLink(destination: GradingSessionView(sessionID: s.id)) {
                            sessionRow(session: s, store: store)
                        }
                    }
                }
            }
            Section(header: Text("heading.ready_to_grade")) {
                if ready.isEmpty {
                    Text("empty.nobody_to_grade").foregroundStyle(.secondary)
                } else {
                    ForEach(ready, id: \.athlete.id) { item in
                        readyRow(item: item)
                    }
                }
            }
        }
    }

    private func sessionRow(session s: GradingSession, store: GradingStore) -> some View {
        let progress = store.progress(for: s.id)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(s.scheduledAt, style: .date).font(.subheadline.bold())
                Spacer()
                Text(LocalizedStringKey(s.status.labelKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let branch = branchLookup[s.branchID] {
                Text(verbatim: branch.name).font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Image(systemName: "person.3.fill").font(.caption2)
                Text(verbatim: "\(progress.scored) / \(progress.total)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .padding(.vertical, 2)
    }

    private func readyRow(item: (athlete: Athlete, eligibility: GradingEligibility)) -> some View {
        HStack(spacing: 10) {
            Avatar(seed: item.athlete.avatarSeed, label: item.athlete.initials, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: item.athlete.fullName)
                HStack(spacing: 4) {
                    Text(LocalizedStringKey(item.eligibility.currentBelt.label))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(verbatim: "→")
                    Text(LocalizedStringKey(item.eligibility.targetBelt.label))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if item.eligibility.isEligible {
                Label("grading.eligible", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }

    private func reload() async {
        do {
            let branches = try await session.repository.branches()
            branchLookup = Dictionary(uniqueKeysWithValues: branches.map { ($0.id, $0) })
            let coaches = try await session.repository.coaches()
            coachLookup = Dictionary(uniqueKeysWithValues: coaches.map { ($0.id, $0) })
            await store?.loadAll(branches: branches)

            let athletes = try await session.repository.athletes()
            var rows: [(Athlete, GradingEligibility)] = []
            for a in athletes {
                let target = GradingEngine.nextBelt(after: a.currentBelt)
                let elig = try await session.repository.eligibility(athleteID: a.id, targetBelt: target)
                if elig.isEligible {
                    rows.append((a, elig))
                }
            }
            ready = rows
        } catch {
            print("GradingDashboardView.reload:", error)
        }
    }
}

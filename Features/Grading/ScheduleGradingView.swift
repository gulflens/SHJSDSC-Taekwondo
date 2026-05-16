import SwiftUI

public struct ScheduleGradingView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let onCreate: (GradingSession) -> Void

    @State private var scheduledAt: Date = Date().addingTimeInterval(7 * 24 * 3600)
    @State private var branchID: EntityID?
    @State private var examiners: Set<EntityID> = []
    @State private var candidates: Set<EntityID> = []

    @State private var branches: [Branch] = []
    @State private var coachesInBranch: [Coach] = []
    @State private var athletesInBranch: [Athlete] = []
    @State private var eligibility: [EntityID: GradingEligibility] = [:]
    @State private var saving = false

    public init(onCreate: @escaping (GradingSession) -> Void) {
        self.onCreate = onCreate
    }

    public var body: some View {
        Form {
            Section {
                DatePicker("grading.scheduled_at", selection: $scheduledAt, in: Date()...)
            }
            Section(header: Text("tab.branches")) {
                Picker(selection: $branchID) {
                    Text("filter.all").tag(EntityID?.none)
                    ForEach(branches) { b in
                        Text(verbatim: b.name).tag(Optional(b.id))
                    }
                } label: {
                    Text("tab.branches")
                }
                .onChange(of: branchID) { _, _ in
                    Task { await loadBranchScoped() }
                }
            }
            Section(header: Text("grading.examiners")) {
                if coachesInBranch.isEmpty {
                    Text("empty.no_coaches").foregroundStyle(.secondary)
                } else {
                    ForEach(coachesInBranch) { c in
                        Toggle(isOn: Binding(
                            get: { examiners.contains(c.id) },
                            set: { yes in if yes { examiners.insert(c.id) } else { examiners.remove(c.id) } }
                        )) {
                            HStack {
                                Avatar(seed: c.avatarSeed, label: c.initials, size: 28)
                                Text(verbatim: c.fullName)
                            }
                        }
                    }
                }
            }
            Section(header: Text("grading.candidates")) {
                if athletesInBranch.isEmpty {
                    Text("empty.no_athletes_flagged").foregroundStyle(.secondary)
                } else {
                    ForEach(athletesInBranch) { a in
                        Toggle(isOn: Binding(
                            get: { candidates.contains(a.id) },
                            set: { yes in if yes { candidates.insert(a.id) } else { candidates.remove(a.id) } }
                        )) {
                            HStack {
                                Avatar(seed: a.avatarSeed, label: a.initials, size: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(verbatim: a.fullName)
                                    if let elig = eligibility[a.id] {
                                        Text(elig.isEligible ? "grading.eligible" : "grading.not_eligible")
                                            .scaledFont(.caption2)
                                            .foregroundStyle(elig.isEligible ? .green : .orange)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Section {
                Button {
                    Task { await save() }
                } label: {
                    if saving {
                        HStack { ProgressView(); Text("action.saving") }
                    } else {
                        Text("grading.schedule")
                    }
                }
                .disabled(saving || branchID == nil || examiners.isEmpty || candidates.isEmpty)
            }
        }
        .navigationTitle(Text("grading.schedule"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
                .bareToolbarButton()
            }
        }
        .task { await loadBranches() }
    }

    private func loadBranches() async {
        do {
            branches = try await session.repository.branches()
            branchID = branches.first?.id
            await loadBranchScoped()
        } catch {
            print("ScheduleGradingView.loadBranches:", error)
        }
    }

    private func loadBranchScoped() async {
        examiners.removeAll()
        candidates.removeAll()
        eligibility.removeAll()
        guard let bid = branchID else { return }
        do {
            coachesInBranch = try await session.repository.coaches(branchID: bid)
            athletesInBranch = try await session.repository.athletes(branchID: bid)
            for a in athletesInBranch {
                let target = GradingEngine.nextBelt(after: a.currentBelt)
                let elig = try await session.repository.eligibility(athleteID: a.id, targetBelt: target)
                eligibility[a.id] = elig
                if elig.isEligible { candidates.insert(a.id) }
            }
            if let primary = coachesInBranch.first { examiners.insert(primary.id) }
        } catch {
            print("ScheduleGradingView.loadBranchScoped:", error)
        }
    }

    private func save() async {
        guard let bid = branchID else { return }
        saving = true
        defer { saving = false }
        let new = GradingSession(
            scheduledAt: scheduledAt,
            branchID: bid,
            examinerCoachIDs: Array(examiners),
            candidateAthleteIDs: Array(candidates),
            status: .scheduled
        )
        do {
            try await session.repository.upsert(new)
            onCreate(new)
            dismiss()
        } catch {
            print("ScheduleGradingView.save:", error)
        }
    }
}

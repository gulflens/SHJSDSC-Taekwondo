import SwiftUI

public struct ScheduleClassView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let editing: ClassSession?
    public let onSaved: (ClassSession) -> Void

    @State private var title: String
    @State private var discipline: ClassDiscipline
    @State private var ageGroup: AgeGroup
    @State private var branchID: EntityID?
    @State private var coachID: EntityID?
    @State private var startsAt: Date
    @State private var endsAt: Date
    @State private var capacity: Int

    @State private var branches: [Branch] = []
    @State private var coachesInBranch: [Coach] = []
    @State private var saving = false
    @State private var error: String?
    @State private var showErrorAlert = false

    public init(editing: ClassSession? = nil, onSaved: @escaping (ClassSession) -> Void) {
        self.editing = editing
        self.onSaved = onSaved
        let defaultStart: Date = {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comps.hour = 17
            comps.minute = 0
            return Calendar.current.date(from: comps) ?? Date()
        }()
        let defaultEnd = defaultStart.addingTimeInterval(60 * 60)
        _title = State(initialValue: editing?.title ?? "")
        _discipline = State(initialValue: editing?.discipline ?? .fundamentals)
        _ageGroup = State(initialValue: editing?.ageGroup ?? .juniors)
        _branchID = State(initialValue: editing?.branchID)
        _coachID = State(initialValue: editing?.coachID)
        _startsAt = State(initialValue: editing?.startsAt ?? defaultStart)
        _endsAt = State(initialValue: editing?.endsAt ?? defaultEnd)
        _capacity = State(initialValue: editing?.capacity ?? 20)
    }

    public var body: some View {
        Form {
            Section {
                TextField("class.title", text: $title)
                Picker("class.discipline", selection: $discipline) {
                    ForEach(ClassDiscipline.allCases, id: \.self) { d in
                        Text(localizedKey: d.labelKey).tag(d)
                    }
                }
                Picker("class.age_group", selection: $ageGroup) {
                    ForEach(AgeGroup.allCases, id: \.self) { ag in
                        Text(localizedKey: ag.labelKey).tag(ag)
                    }
                }
            } header: {
                Text("class.section.identity")
            }

            Section {
                Picker("tab.branches", selection: $branchID) {
                    Text("admin.no_branch").tag(EntityID?.none)
                    ForEach(branches) { b in
                        Text(verbatim: b.name).tag(EntityID?.some(b.id))
                    }
                }
                .onChange(of: branchID) { _, _ in
                    Task { await loadCoaches() }
                }
                Picker("tab.coaches", selection: $coachID) {
                    Text("admin.no_branch").tag(EntityID?.none)
                    ForEach(coachesInBranch) { c in
                        Text(verbatim: c.fullName).tag(EntityID?.some(c.id))
                    }
                }
            } header: {
                Text("class.section.assignment")
            }

            Section {
                DatePicker("class.starts_at", selection: $startsAt)
                DatePicker("class.ends_at", selection: $endsAt, in: startsAt...)
                Stepper(value: $capacity, in: 1...100) {
                    HStack {
                        Text("class.capacity")
                        Spacer()
                        Text(verbatim: "\(capacity)")
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
            } header: {
                Text("class.section.schedule")
            }
        }
        .navigationTitle(Text(editing == nil ? "class.add" : "class.edit"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
                .bareToolbarButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task { await save() }
                } label: {
                    if saving { ProgressView() } else { Text("action.save") }
                }
                .disabled(saving || !isValid)
                .bareToolbarButton()
            }
        }
        .alert("class.save_error", isPresented: $showErrorAlert) {
            Button("action.ok", role: .cancel) {}
        } message: {
            Text(verbatim: error ?? "")
        }
        .task { await load() }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && branchID != nil
            && coachID != nil
            && endsAt > startsAt
    }

    private func load() async {
        do {
            branches = try await session.repository.branches()
            // Default branch = the editing branch, otherwise the user's primary,
            // otherwise the first branch.
            if branchID == nil {
                branchID = session.currentUser?.primaryBranchID ?? branches.first?.id
            }
            await loadCoaches()
            // Default coach = the current user when they're a coach, after we
            // have the branch's coach list.
            if coachID == nil, let userID = session.currentUser?.id,
               coachesInBranch.contains(where: { $0.id == userID }) {
                coachID = userID
            }
        } catch {
            print("ScheduleClassView.load:", error)
        }
    }

    private func loadCoaches() async {
        guard let branchID else { coachesInBranch = []; return }
        do {
            coachesInBranch = try await session.repository.coaches(branchID: branchID)
        } catch {
            print("ScheduleClassView.loadCoaches:", error)
        }
    }

    private func save() async {
        guard let branchID, let coachID else { return }
        saving = true
        defer { saving = false }
        let s = ClassSession(
            id: editing?.id ?? UUID(),
            title: title,
            discipline: discipline,
            branchID: branchID,
            coachID: coachID,
            startsAt: startsAt,
            endsAt: endsAt,
            capacity: capacity,
            enrolledAthleteIDs: editing?.enrolledAthleteIDs ?? [],
            ageGroup: ageGroup
        )
        do {
            try await session.repository.upsert(s)
            onSaved(s)
            dismiss()
        } catch {
            print("ScheduleClassView.save:", error)
            self.error = error.localizedDescription
            showErrorAlert = true
        }
    }
}

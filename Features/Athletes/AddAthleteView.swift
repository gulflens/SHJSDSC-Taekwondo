import SwiftUI

public struct AddAthleteView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let initialBranchID: EntityID?
    public let onCreated: (Athlete) -> Void

    @State private var memberNumber: Int = 1001
    @State private var fullName: String = ""
    @State private var fullNameAr: String = ""
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -12, to: Date()) ?? Date()
    @State private var gender: Gender = .male
    @State private var branchID: EntityID?
    @State private var primaryCoachID: EntityID?
    @State private var weightKg: Double = 35
    @State private var status: AthleteStatus = .active
    @State private var beltColor: BeltColor = .white
    @State private var beltKind: BeltKind = .gup
    @State private var beltNumber: Int = 10

    @State private var branches: [Branch] = []
    @State private var coachesInBranch: [Coach] = []
    @State private var saving = false
    @State private var error: String?

    public init(initialBranchID: EntityID? = nil, onCreated: @escaping (Athlete) -> Void) {
        self.initialBranchID = initialBranchID
        self.onCreated = onCreated
    }

    public var body: some View {
        Form {
            Section(header: Text("athlete.identity")) {
                Stepper(value: $memberNumber, in: 1001...1999) {
                    HStack {
                        Text("athlete.member_number")
                        Spacer()
                        Text(verbatim: "#\(memberNumber)")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
                TextField("auth.full_name", text: $fullName)
                TextField("auth.full_name_ar", text: $fullNameAr)
                DatePicker("athlete.date_of_birth", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                Picker(selection: $gender) {
                    Text("athlete.gender.male").tag(Gender.male)
                    Text("athlete.gender.female").tag(Gender.female)
                } label: {
                    Text("athlete.gender")
                }
            }

            Section(header: Text("athlete.placement")) {
                Picker(selection: $branchID) {
                    Text("filter.all").tag(EntityID?.none)
                    ForEach(branches) { b in
                        Text(verbatim: b.name).tag(Optional(b.id))
                    }
                } label: {
                    Text("tab.branches")
                }
                .onChange(of: branchID) { _, _ in
                    Task { await loadCoaches() }
                }
                if !coachesInBranch.isEmpty {
                    Picker(selection: $primaryCoachID) {
                        Text("admin.no_branch").tag(EntityID?.none)
                        ForEach(coachesInBranch) { c in
                            Text(verbatim: c.fullName).tag(Optional(c.id))
                        }
                    } label: {
                        Text("tab.coaches")
                    }
                }
                Picker(selection: $status) {
                    ForEach(AthleteStatus.allCases, id: \.self) { st in
                        Text(LocalizedStringKey(st.labelKey)).tag(st)
                    }
                } label: {
                    Text("athlete.status")
                }
            }

            Section(header: Text("heading.belt_journey")) {
                Picker(selection: $beltColor) {
                    ForEach(BeltColor.allCases, id: \.self) { c in
                        Text(LocalizedStringKey(c.labelKey)).tag(c)
                    }
                } label: {
                    Text("athlete.belt_color")
                }
                Picker(selection: $beltKind) {
                    ForEach(BeltKind.allCases, id: \.self) { k in
                        Text(LocalizedStringKey(k.labelKey)).tag(k)
                    }
                } label: {
                    Text("athlete.belt_kind")
                }
                Stepper(value: $beltNumber, in: 1...10) {
                    HStack {
                        Text("athlete.belt_number")
                        Spacer()
                        Text(verbatim: "\(beltNumber)")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
            }

            Section(header: Text("kpi.weight")) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("kpi.weight")
                        Spacer()
                        Text(verbatim: String(format: "%.1f kg", weightKg))
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    Slider(value: $weightKg, in: 15...100, step: 0.5)
                }
            }

            if let error {
                Section {
                    Text(verbatim: error).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(Text("athlete.add"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task { await save() }
                } label: {
                    if saving {
                        ProgressView()
                    } else {
                        Text("action.save")
                    }
                }
                .disabled(saving || !isValid)
            }
        }
        .task { await load() }
    }

    private var isValid: Bool {
        !fullName.isEmpty && branchID != nil && weightKg > 0
    }

    private func load() async {
        do {
            branches = try await session.repository.branches()
            if branchID == nil {
                branchID = initialBranchID ?? branches.first?.id
            }
            await loadCoaches()
            memberNumber = (try? await session.repository.nextMemberNumber()) ?? 1001
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadCoaches() async {
        guard let branchID else { coachesInBranch = []; return }
        do {
            coachesInBranch = try await session.repository.coaches(branchID: branchID)
        } catch {
            print("AddAthleteView.loadCoaches:", error)
        }
    }

    private func save() async {
        guard let branchID else { return }
        saving = true
        defer { saving = false }
        let belt = Belt(color: beltColor, kind: beltKind, number: beltNumber, awardedAt: Date())
        let athlete = Athlete(
            memberNumber: memberNumber,
            fullName: fullName,
            fullNameAr: fullNameAr.isEmpty ? fullName : fullNameAr,
            dateOfBirth: dateOfBirth,
            gender: gender,
            branchID: branchID,
            primaryCoachID: primaryCoachID,
            joinedAt: Date(),
            currentBelt: belt,
            beltHistory: [belt],
            weightKg: weightKg,
            status: status,
            avatarSeed: String(fullName.prefix(2)).lowercased()
        )
        do {
            try await session.repository.upsert(athlete)
            onCreated(athlete)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

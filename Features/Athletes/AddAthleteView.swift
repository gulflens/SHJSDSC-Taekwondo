import SwiftUI

public struct AddAthleteView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let initialBranchID: EntityID?
    public let onCreated: (Athlete) -> Void

    // === Identity ===
    @State private var memberNumber: Int = 1001
    @State private var fullName: String = ""
    @State private var fullNameAr: String = ""
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -12, to: Date()) ?? Date()
    @State private var gender: Gender = .male
    @State private var nationality: String = "AE"
    @State private var emiratesID: String = ""
    @State private var passportNumber: String = ""
    @State private var bloodType: BloodType = .unknown
    @State private var federationLicenceNumber: String = ""
    @State private var branchID: EntityID?
    @State private var joinedAt: Date = Date()

    // === Family / consent ===
    @State private var emergencyContacts: [EmergencyContact] = []
    @State private var school: String = ""
    @State private var imageRightsConsent: Bool = false
    @State private var travelPermission: Bool = false

    // === Medical ===
    @State private var heightCm: Double = 140
    @State private var weightKg: Double = 35
    @State private var allergiesText: String = ""
    @State private var medicalConditionsText: String = ""
    @State private var medicationsText: String = ""
    @State private var fitToTrain: Bool = true

    // === Technical ===
    @State private var beltColor: BeltColor = .white
    @State private var beltKind: BeltKind = .gup
    @State private var beltNumber: Int = 10
    @State private var status: AthleteStatus = .active
    @State private var weightClass: WeightCategory?
    @State private var dominantStance: Stance = .orthodox
    @State private var poomsaeSyllabus: String = ""
    @State private var kyorugiTier: KyorugiTier = .recreational
    @State private var primaryCoachID: EntityID?

    // === Loaded data + UI state ===
    @State private var branches: [Branch] = []
    @State private var coachesInBranch: [Coach] = []
    @State private var saving = false
    @State private var error: String?
    @State private var expandedIdentity = true
    @State private var expandedFamily = false
    @State private var expandedMedical = false
    @State private var expandedTechnical = false

    public init(initialBranchID: EntityID? = nil, onCreated: @escaping (Athlete) -> Void) {
        self.initialBranchID = initialBranchID
        self.onCreated = onCreated
    }

    public var body: some View {
        Form {
            DisclosureGroup(isExpanded: $expandedIdentity) {
                identitySection
            } label: {
                Label("athlete.section.identity", systemImage: "person.text.rectangle")
                    .font(.headline)
            }

            DisclosureGroup(isExpanded: $expandedFamily) {
                familySection
            } label: {
                Label("athlete.section.family", systemImage: "person.2")
                    .font(.headline)
            }

            DisclosureGroup(isExpanded: $expandedMedical) {
                medicalSection
            } label: {
                Label("athlete.section.medical", systemImage: "heart.text.square")
                    .font(.headline)
            }

            DisclosureGroup(isExpanded: $expandedTechnical) {
                technicalSection
            } label: {
                Label("athlete.section.technical", systemImage: "figure.taekwondo")
                    .font(.headline)
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
                    if saving { ProgressView() } else { Text("action.save") }
                }
                .disabled(saving || !isValid)
            }
        }
        .task { await load() }
    }

    // MARK: Identity

    @ViewBuilder
    private var identitySection: some View {
        Stepper(value: $memberNumber, in: 1001...1999) {
            HStack {
                Text("athlete.member_number")
                Spacer()
                Text(verbatim: "#\(memberNumber)").foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        TextField("auth.full_name", text: $fullName)
        TextField("auth.full_name_ar", text: $fullNameAr)
        DatePicker("athlete.date_of_birth", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
        Picker(selection: $gender) {
            Text("athlete.gender.male").tag(Gender.male)
            Text("athlete.gender.female").tag(Gender.female)
        } label: { Text("athlete.gender") }
        TextField("athlete.nationality", text: $nationality)
        TextField("athlete.emirates_id", text: $emiratesID)
        TextField("athlete.passport_number", text: $passportNumber)
        Picker(selection: $bloodType) {
            ForEach(BloodType.allCases, id: \.self) { b in
                Text(verbatim: b.display).tag(b)
            }
        } label: { Text("athlete.blood_type") }
        TextField("athlete.federation_licence", text: $federationLicenceNumber)
        Picker(selection: $branchID) {
            Text("filter.all").tag(EntityID?.none)
            ForEach(branches) { b in
                Text(verbatim: b.name).tag(Optional(b.id))
            }
        } label: { Text("tab.branches") }
        .onChange(of: branchID) { _, _ in
            Task { await loadCoaches() }
        }
        DatePicker("athlete.joined_at", selection: $joinedAt, displayedComponents: .date)
    }

    // MARK: Family

    @ViewBuilder
    private var familySection: some View {
        TextField("athlete.school", text: $school)
        Toggle("athlete.image_rights", isOn: $imageRightsConsent)
        Toggle("athlete.travel_permission", isOn: $travelPermission)

        ForEach(emergencyContacts.indices, id: \.self) { idx in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("athlete.emergency_contact").font(.subheadline.bold())
                    Spacer()
                    Button(role: .destructive) {
                        emergencyContacts.remove(at: idx)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                }
                TextField("athlete.emergency_name", text: $emergencyContacts[idx].name)
                TextField("athlete.emergency_relationship", text: $emergencyContacts[idx].relationship)
                TextField("athlete.emergency_phone", text: $emergencyContacts[idx].phone)
                    #if os(iOS)
                    .keyboardType(.phonePad)
                    #endif
            }
        }
        Button {
            emergencyContacts.append(EmergencyContact(name: "", relationship: "", phone: ""))
        } label: {
            Label("athlete.add_emergency", systemImage: "plus.circle")
        }
    }

    // MARK: Medical

    @ViewBuilder
    private var medicalSection: some View {
        Toggle("athlete.fit_to_train", isOn: $fitToTrain)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("athlete.height")
                Spacer()
                Text(verbatim: String(format: "%.0f cm", heightCm)).foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Slider(value: $heightCm, in: 80...210, step: 1)
        }
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("kpi.weight")
                Spacer()
                Text(verbatim: String(format: "%.1f kg", weightKg)).foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Slider(value: $weightKg, in: 15...120, step: 0.5)
        }
        VStack(alignment: .leading, spacing: 2) {
            Text("athlete.allergies").font(.caption).foregroundStyle(.secondary)
            TextField("athlete.allergies_placeholder", text: $allergiesText, axis: .vertical)
                .lineLimit(2, reservesSpace: true)
        }
        VStack(alignment: .leading, spacing: 2) {
            Text("athlete.medical_conditions").font(.caption).foregroundStyle(.secondary)
            TextField("athlete.medical_conditions_placeholder", text: $medicalConditionsText, axis: .vertical)
                .lineLimit(2, reservesSpace: true)
        }
        VStack(alignment: .leading, spacing: 2) {
            Text("athlete.medications").font(.caption).foregroundStyle(.secondary)
            TextField("athlete.medications_placeholder", text: $medicationsText, axis: .vertical)
                .lineLimit(2, reservesSpace: true)
        }
    }

    // MARK: Technical

    @ViewBuilder
    private var technicalSection: some View {
        Picker(selection: $beltColor) {
            ForEach(BeltColor.allCases, id: \.self) { c in
                Text(LocalizedStringKey(c.labelKey)).tag(c)
            }
        } label: { Text("athlete.belt_color") }
        Picker(selection: $beltKind) {
            ForEach(BeltKind.allCases, id: \.self) { k in
                Text(LocalizedStringKey(k.labelKey)).tag(k)
            }
        } label: { Text("athlete.belt_kind") }
        Stepper(value: $beltNumber, in: 1...10) {
            HStack {
                Text("athlete.belt_number")
                Spacer()
                Text(verbatim: "\(beltNumber)").foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        Picker(selection: $status) {
            ForEach(AthleteStatus.allCases, id: \.self) { s in
                Text(LocalizedStringKey(s.labelKey)).tag(s)
            }
        } label: { Text("athlete.status") }
        Picker(selection: $weightClass) {
            Text("filter.all").tag(WeightCategory?.none)
            ForEach(WeightCategory.allCases, id: \.self) { c in
                Text(verbatim: c.shortLabel).tag(Optional(c))
            }
        } label: { Text("tournament.weight_category") }
        Picker(selection: $dominantStance) {
            ForEach(Stance.allCases, id: \.self) { s in
                Text(LocalizedStringKey(s.labelKey)).tag(s)
            }
        } label: { Text("athlete.dominant_stance") }
        Picker(selection: $kyorugiTier) {
            ForEach(KyorugiTier.allCases, id: \.self) { t in
                Text(LocalizedStringKey(t.labelKey)).tag(t)
            }
        } label: { Text("athlete.kyorugi_tier") }
        TextField("athlete.poomsae_syllabus", text: $poomsaeSyllabus)
        if !coachesInBranch.isEmpty {
            Picker(selection: $primaryCoachID) {
                Text("admin.no_branch").tag(EntityID?.none)
                ForEach(coachesInBranch) { c in
                    Text(verbatim: c.fullName).tag(Optional(c.id))
                }
            } label: { Text("tab.coaches") }
        }
    }

    // MARK: Validation + persistence

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
        } catch { print("AddAthleteView.loadCoaches:", error) }
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
            nationality: nationality.isEmpty ? "AE" : nationality,
            emiratesID: emiratesID.isEmpty ? nil : emiratesID,
            branchID: branchID,
            primaryCoachID: primaryCoachID,
            joinedAt: joinedAt,
            currentBelt: belt,
            beltHistory: [belt],
            weightKg: weightKg,
            status: status,
            avatarSeed: String(fullName.prefix(2)).lowercased(),
            avatarURL: nil,
            passportNumber: passportNumber.isEmpty ? nil : passportNumber,
            bloodType: bloodType == .unknown ? nil : bloodType,
            federationLicenceNumber: federationLicenceNumber.isEmpty ? nil : federationLicenceNumber,
            parentUserIDs: [],
            emergencyContacts: emergencyContacts.filter { !$0.name.isEmpty },
            school: school.isEmpty ? nil : school,
            imageRightsConsent: imageRightsConsent,
            imageRightsConsentDate: imageRightsConsent ? Date() : nil,
            travelPermission: travelPermission,
            travelPermissionDate: travelPermission ? Date() : nil,
            heightCm: heightCm > 0 ? heightCm : nil,
            weightHistory: [WeightEntry(weightKg: weightKg)],
            allergies: parseList(allergiesText),
            medicalConditions: parseList(medicalConditionsText),
            medications: parseList(medicationsText),
            fitToTrain: fitToTrain,
            injuries: [],
            weightClass: weightClass,
            dominantStance: dominantStance,
            poomsaeSyllabus: poomsaeSyllabus.isEmpty ? nil : poomsaeSyllabus,
            kyorugiTier: kyorugiTier
        )
        do {
            try await session.repository.upsert(athlete)
            onCreated(athlete)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Comma-separated text → trimmed non-empty list.
    private func parseList(_ raw: String) -> [String] {
        raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

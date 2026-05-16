import SwiftUI

public struct AddAthleteView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    public let initialBranchID: EntityID?
    public let editing: Athlete?
    public let onCreated: (Athlete) -> Void

    // === Identity ===
    /// nil while the form is open and the user hasn't saved yet — only
    /// reserved (consuming a sequence value) at the moment of save.
    @State private var memberNumber: Int?
    @State private var fullName: String = ""
    @State private var fullNameAr: String = ""
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -12, to: Date()) ?? Date()
    @State private var nationality: String = "AE"
    @State private var emiratesID: String = ""
    @State private var passportNumber: String = ""
    @State private var bloodType: BloodType = .unknown
    @State private var federationLicenceNumber: String = ""
    @State private var worldTaekwondoID: String = ""
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
    @State private var dominantLeg: DominantLeg?
    @State private var dominantStance: Stance = .open
    @State private var specialty: Specialty = .kyorugi
    @State private var yearsTraining: Int = 0
    @State private var poomsaeSyllabus: String = ""
    @State private var kyorugiTier: KyorugiTier = .recreational
    @State private var primaryCoachID: EntityID?

    // === Loaded data + UI state ===
    @State private var branches: [Branch] = []
    @State private var coachesInBranch: [Coach] = []
    @State private var saving = false
    @State private var error: String?
    @State private var showErrorAlert = false
    @State private var showNationalityPicker = false
    @State private var nationalitySearch = ""

    public init(initialBranchID: EntityID? = nil, editing: Athlete? = nil, onCreated: @escaping (Athlete) -> Void) {
        self.initialBranchID = initialBranchID
        self.editing = editing
        self.onCreated = onCreated
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                identityCard
                familyCard
                medicalCard
                technicalCard

                Color.clear.frame(height: 16)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color.appBackground)
        .navigationTitle(Text(editing == nil ? "athlete.add" : "athlete.edit"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
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
        .alert("athlete.save_error", isPresented: $showErrorAlert) {
            Button("action.ok", role: .cancel) {}
        } message: {
            Text(verbatim: error ?? "")
        }
        .task { await load() }
    }

    // MARK: - Identity

    private var identityCard: some View {
        SectionCard("athlete.section.identity", icon: "person.text.rectangle.fill") {
            memberNumberRow

            FieldRow {
                InlineField(label: "auth.full_name") {
                    compactTextField($fullName, placeholder: "auth.full_name")
                }
                InlineField(label: "auth.full_name_ar") {
                    arabicTextField($fullNameAr, placeholder: "auth.full_name_ar")
                }
            }

            FieldRow {
                InlineField(label: "athlete.date_of_birth") {
                    DropdownDatePicker(date: $dateOfBirth, minYear: 1950, maxYear: currentYear)
                }
                InlineField(label: "athlete.nationality") {
                    Button {
                        nationalitySearch = ""
                        showNationalityPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(verbatim: flagEmoji(for: nationality))
                                .scaledFont(.callout)
                            Text(verbatim: countryName(for: nationality))
                                .scaledFont(.callout)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .scaledFont(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .popover(isPresented: $showNationalityPicker) {
                        nationalityPickerContent
                    }
                }
            }

            FieldRow {
                InlineField(label: "athlete.emirates_id") {
                    emiratesIDField
                }
                InlineField(label: "athlete.passport_number") {
                    compactTextField($passportNumber, placeholder: "athlete.passport_number")
                }
            }

            FieldRow {
                InlineField(label: "athlete.federation_licence") {
                    compactTextField($federationLicenceNumber, placeholder: "athlete.federation_licence")
                }
                InlineField(label: "athlete.id.world_taekwondo") {
                    compactTextField($worldTaekwondoID, placeholder: "athlete.id.world_taekwondo")
                }
            }

            FieldRow {
                InlineField(label: "athlete.joined_at") {
                    DropdownDatePicker(date: $joinedAt, minYear: 1990, maxYear: currentYear)
                }
                InlineField(label: "tab.branches") {
                    Menu {
                        ForEach(branches) { b in
                            Button {
                                branchID = b.id
                                Task { await loadCoaches() }
                            } label: { Text(verbatim: b.name) }
                        }
                    } label: {
                        compactMenuLabel(
                            text: branches.first(where: { $0.id == branchID })?.name
                                ?? String(localized: "filter.all")
                        )
                    }
                }
            }
        }
    }

    private var memberNumberRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "number.circle.fill")
                .scaledFont(.subheadline)
                .foregroundStyle(.tint.opacity(0.6))
            VStack(alignment: .leading, spacing: 0) {
                Text("athlete.member_number")
                    .scaledFont(.caption2, weight: .medium)
                    .foregroundStyle(.secondary)
                if let memberNumber {
                    Text(verbatim: "#\(memberNumber)")
                        .scaledFont(.callout, weight: .bold, monospacedDigit: true)
                        .foregroundStyle(.tint)
                        .environment(\.layoutDirection, .leftToRight)
                } else {
                    Text("athlete.member_number_pending")
                        .scaledFont(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.tint.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Family & consent

    private var familyCard: some View {
        SectionCard("athlete.section.family", icon: "person.2.fill") {
            InlineField(label: "athlete.school") {
                compactTextField($school, placeholder: "athlete.school")
            }

            FieldRow {
                compactToggle(label: "athlete.image_rights", binding: $imageRightsConsent, icon: "camera.fill")
                compactToggle(label: "athlete.travel_permission", binding: $travelPermission, icon: "airplane")
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("athlete.emergency_contact")
                        .scaledFont(.caption2, weight: .bold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        emergencyContacts.append(EmergencyContact(name: "", relationship: "", phone: ""))
                    } label: {
                        Label("athlete.add_emergency", systemImage: "plus.circle.fill")
                            .scaledFont(.caption2)
                            .labelStyle(.titleAndIcon)
                    }
                }
                if emergencyContacts.isEmpty {
                    Text("athlete.no_emergency_contacts_yet")
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                } else {
                    ForEach(emergencyContacts.indices, id: \.self) { idx in
                        emergencyContactRow(at: idx)
                    }
                }
            }
        }
    }

    private func emergencyContactRow(at idx: Int) -> some View {
        HStack(alignment: .top, spacing: 6) {
            InlineField(label: "athlete.emergency_name") {
                compactTextField(Binding(
                    get: { emergencyContacts[idx].name },
                    set: { emergencyContacts[idx].name = $0 }
                ), placeholder: "athlete.emergency_name")
            }
            InlineField(label: "athlete.emergency_relationship") {
                compactTextField(Binding(
                    get: { emergencyContacts[idx].relationship },
                    set: { emergencyContacts[idx].relationship = $0 }
                ), placeholder: "athlete.emergency_relationship")
            }
            InlineField(label: "athlete.emergency_phone") {
                TextField("athlete.emergency_phone", text: Binding(
                    get: { emergencyContacts[idx].phone },
                    set: { emergencyContacts[idx].phone = $0 }
                ))
                #if os(iOS)
                .keyboardType(.phonePad)
                #endif
                .textFieldStyle(.plain)
                .scaledFont(.callout)
                .environment(\.locale, Self.englishLocale)
            }
            Button(role: .destructive) {
                emergencyContacts.remove(at: idx)
            } label: {
                Image(systemName: "trash")
                    .scaledFont(.caption)
                    .foregroundStyle(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
            }
            .padding(.top, 6)
        }
    }

    // MARK: - Medical

    private var medicalCard: some View {
        SectionCard("athlete.section.medical", icon: "heart.text.square.fill") {
            HStack(spacing: 6) {
                Image(systemName: fitToTrain ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .scaledFont(.caption)
                    .foregroundStyle(fitToTrain ? .green : .orange)
                Text("athlete.fit_to_train").scaledFont(.caption2, weight: .bold)
                Spacer()
                Toggle("", isOn: $fitToTrain).labelsHidden()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background((fitToTrain ? Color.green : Color.orange).opacity(0.08), in: RoundedRectangle(cornerRadius: 6))

            FieldRow {
                InlineField(label: "athlete.height") {
                    compactSlider(value: $heightCm, range: 80...210, step: 1, suffix: "cm", format: "%.0f")
                }
                InlineField(label: "kpi.weight") {
                    compactSlider(value: $weightKg, range: 15...120, step: 0.5, suffix: "kg", format: "%.1f")
                }
                InlineField(label: "athlete.blood_type") {
                    Menu {
                        ForEach(BloodType.allCases, id: \.self) { b in
                            Button { bloodType = b } label: { Text(verbatim: b.display) }
                        }
                    } label: {
                        compactMenuLabel(text: bloodType.display)
                    }
                }
            }

            FieldRow {
                InlineField(label: "athlete.allergies") {
                    compactMultiline($allergiesText, placeholder: "athlete.allergies_placeholder")
                }
                InlineField(label: "athlete.medical_conditions") {
                    compactMultiline($medicalConditionsText, placeholder: "athlete.medical_conditions_placeholder")
                }
            }

            InlineField(label: "athlete.medications") {
                compactMultiline($medicationsText, placeholder: "athlete.medications_placeholder")
            }
        }
    }

    // MARK: - Technical

    private var technicalCard: some View {
        SectionCard("athlete.section.technical", icon: "figure.taekwondo") {
            FieldRow {
                InlineField(label: "athlete.belt_color") {
                    Menu {
                        ForEach(BeltColor.allCases, id: \.self) { c in
                            Button(action: { beltColor = c }) {
                                HStack {
                                    Circle().fill(c.swiftUIColor).frame(width: 10, height: 10)
                                    Text(localizedKey: c.labelKey)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle().fill(beltColor.swiftUIColor).frame(width: 10, height: 10)
                            Text(localizedKey: beltColor.labelKey)
                                .scaledFont(.callout)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .scaledFont(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                InlineField(label: "athlete.belt_kind") {
                    Menu {
                        ForEach(BeltKind.allCases, id: \.self) { k in
                            Button {
                                beltKind = k
                                beltNumber = clamp(beltNumber, to: beltNumberRange(for: k))
                            } label: {
                                Text(localizedKey: k.labelKey)
                            }
                        }
                    } label: {
                        compactMenuLabel(text: NSLocalizedString(beltKind.labelKey, comment: ""))
                    }
                }
                InlineField(label: "athlete.belt_number") {
                    CompactStepper(value: $beltNumber, range: beltNumberRange(for: beltKind))
                }
            }

            FieldRow {
                InlineField(label: "athlete.status") {
                    Menu {
                        ForEach(AthleteStatus.allCases, id: \.self) { s in
                            Button { status = s } label: {
                                Text(localizedKey: s.labelKey)
                            }
                        }
                    } label: {
                        compactMenuLabel(text: NSLocalizedString(status.labelKey, comment: ""))
                    }
                }
                InlineField(label: "tournament.weight_category") {
                    Menu {
                        Button("filter.all") { weightClass = nil }
                        Divider()
                        ForEach(WeightCategory.allCases, id: \.self) { c in
                            Button { weightClass = c } label: { Text(verbatim: c.shortLabel) }
                        }
                    } label: {
                        compactMenuLabel(text: weightClass?.shortLabel ?? String(localized: "filter.all"))
                    }
                }
            }

            FieldRow {
                InlineField(label: "athlete.dominant_leg") {
                    Picker("", selection: $dominantLeg) {
                        Text("–").tag(DominantLeg?.none)
                        ForEach(DominantLeg.allCases, id: \.self) { l in
                            Text(localizedKey: l.labelKey).tag(DominantLeg?.some(l))
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                InlineField(label: "athlete.dominant_stance") {
                    Picker("", selection: $dominantStance) {
                        ForEach(Stance.allCases, id: \.self) { s in
                            Text(localizedKey: s.labelKey).tag(s)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
            }

            FieldRow {
                InlineField(label: "athlete.specialty") {
                    Picker("", selection: $specialty) {
                        ForEach(Specialty.allCases, id: \.self) { s in
                            Text(localizedKey: s.labelKey).tag(s)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                InlineField(label: "athlete.years_training") {
                    CompactStepper(value: $yearsTraining, range: 0...40)
                }
            }

            FieldRow {
                InlineField(label: "athlete.kyorugi_tier") {
                    Menu {
                        ForEach(KyorugiTier.allCases, id: \.self) { t in
                            Button { kyorugiTier = t } label: {
                                Text(localizedKey: t.labelKey)
                            }
                        }
                    } label: {
                        compactMenuLabel(text: NSLocalizedString(kyorugiTier.labelKey, comment: ""))
                    }
                }
                InlineField(label: "athlete.poomsae_syllabus") {
                    compactTextField($poomsaeSyllabus, placeholder: "athlete.poomsae_syllabus")
                }
                InlineField(label: "tab.coaches") {
                    Menu {
                        Button("admin.no_branch") { primaryCoachID = nil }
                        if !coachesInBranch.isEmpty { Divider() }
                        ForEach(coachesInBranch) { c in
                            Button { primaryCoachID = c.id } label: { Text(verbatim: c.fullName) }
                        }
                    } label: {
                        compactMenuLabel(
                            text: coachesInBranch.first(where: { $0.id == primaryCoachID })?.fullName
                                ?? String(localized: "admin.no_branch")
                        )
                    }
                }
            }
        }
    }

    // MARK: - Belt helpers

    /// Valid rank ranges per IBSF/WT convention:
    /// gup 10–1 (10 = white, 1 = highest pre-black), poom 1–4 (junior black),
    /// dan 1–9. Stepper clamps + bumps the displayed number when kind changes.
    private func beltNumberRange(for kind: BeltKind) -> ClosedRange<Int> {
        switch kind {
        case .gup: 1...10
        case .poom: 1...4
        case .dan: 1...9
        }
    }

    private func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }

    // MARK: - Field helpers

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }
    private static let englishLocale = Locale(identifier: "en")
    private static let arabicLocale = Locale(identifier: "ar")

    private func compactTextField(_ binding: Binding<String>, placeholder: LocalizedStringKey) -> some View {
        TextField(placeholder, text: binding)
            .textFieldStyle(.plain)
            .scaledFont(.callout)
            .environment(\.locale, Self.englishLocale)
    }

    private func arabicTextField(_ binding: Binding<String>, placeholder: LocalizedStringKey) -> some View {
        TextField(placeholder, text: binding)
            .textFieldStyle(.plain)
            .scaledFont(.callout)
            .environment(\.locale, Self.arabicLocale)
    }

    private func compactMultiline(_ binding: Binding<String>, placeholder: LocalizedStringKey) -> some View {
        TextField(placeholder, text: binding, axis: .vertical)
            .textFieldStyle(.plain)
            .scaledFont(.callout)
            .lineLimit(1...3)
            .environment(\.locale, Self.englishLocale)
    }

    private func compactMenuLabel(text: String) -> some View {
        HStack {
            Text(verbatim: text).scaledFont(.callout).foregroundStyle(.primary).lineLimit(1)
            Spacer()
            Image(systemName: "chevron.up.chevron.down").scaledFont(.caption2).foregroundStyle(.secondary)
        }
    }

    private func compactSlider(value: Binding<Double>, range: ClosedRange<Double>, step: Double, suffix: String, format: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: String(format: "\(format) \(suffix)", value.wrappedValue))
                .scaledFont(.caption, weight: .bold, monospacedDigit: true)
                .foregroundStyle(.tint)
                .environment(\.layoutDirection, .leftToRight)
                .tappableDouble(value, in: range, decimals: step < 1 ? 1 : 0)
            Slider(value: value, in: range, step: step)
        }
    }

    private func compactToggle(label: LocalizedStringKey, binding: Binding<Bool>, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).scaledFont(.caption).foregroundStyle(.tint)
            Text(label).scaledFont(.caption2, weight: .semibold).foregroundStyle(.primary.opacity(0.55))
            Spacer()
            Toggle("", isOn: binding).labelsHidden()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Emirates ID

    private var emiratesIDField: some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField("784-0000-0000000-0", text: $emiratesID)
                .textFieldStyle(.plain)
                .scaledFont(.callout, monospacedDigit: true)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .environment(\.locale, Self.englishLocale)
                .environment(\.layoutDirection, .leftToRight)
                .onChange(of: emiratesID) { _, newValue in
                    let formatted = formatEmiratesID(newValue)
                    if formatted != newValue { emiratesID = formatted }
                }
            if !emiratesID.isEmpty && !isValidEmiratesID(emiratesID) {
                Text("athlete.emirates_id_format")
                    .scaledFont(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }

    private func formatEmiratesID(_ input: String) -> String {
        let digits = input.filter(\.isWholeNumber)
        let capped = String(digits.prefix(15))
        var result = ""
        for (i, ch) in capped.enumerated() {
            if i == 3 || i == 7 || i == 14 { result.append("-") }
            result.append(ch)
        }
        return result
    }

    private func isValidEmiratesID(_ value: String) -> Bool {
        let digits = value.filter(\.isWholeNumber)
        return digits.count == 15 && digits.hasPrefix("784")
    }

    // MARK: - Nationality picker

    private func flagEmoji(for code: String) -> String {
        let base: UInt32 = 127397
        return code.uppercased().unicodeScalars.compactMap {
            UnicodeScalar(base + $0.value).map(String.init)
        }.joined()
    }

    private func countryName(for code: String) -> String {
        locale.localizedString(forRegionCode: code) ?? code
    }

    private var nationalityPickerContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                TextField("action.search", text: $nationalitySearch)
                    .textFieldStyle(.plain)
                    .scaledFont(.callout)
                    .environment(\.locale, Self.englishLocale)
            }
            .padding(10)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredCountries, id: \.code) { country in
                        Button {
                            nationality = country.code
                            showNationalityPicker = false
                        } label: {
                            HStack(spacing: 8) {
                                Text(verbatim: flagEmoji(for: country.code))
                                    .scaledFont(.callout)
                                Text(verbatim: country.name)
                                    .scaledFont(.callout)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(verbatim: country.code)
                                    .scaledFont(.caption, design: .monospaced)
                                    .foregroundStyle(.secondary)
                                if country.code == nationality {
                                    Image(systemName: "checkmark")
                                        .scaledFont(.caption, weight: .bold)
                                        .foregroundStyle(.tint)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 44)
                    }
                }
            }
        }
        .frame(width: 320, height: 400)
    }

    private var filteredCountries: [(code: String, name: String)] {
        let displayLocale = locale
        let all = Locale.Region.isoRegions
            .map(\.identifier)
            .filter { $0.count == 2 }
            .compactMap { code -> (code: String, name: String)? in
                guard let name = displayLocale.localizedString(forRegionCode: code) else { return nil }
                return (code, name)
            }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }

        if nationalitySearch.isEmpty { return all }
        let query = nationalitySearch.lowercased()
        return all.filter {
            $0.name.lowercased().contains(query) || $0.code.lowercased().contains(query)
        }
    }

    // MARK: - Validation + persistence

    private var isValid: Bool {
        !fullName.isEmpty
    }

    private func load() async {
        do {
            branches = try await session.repository.branches()
            if let editing {
                hydrate(from: editing)
            } else if branchID == nil {
                branchID = initialBranchID ?? branches.first?.id
            }
            await loadCoaches()
        } catch {
            print("AddAthleteView.load failed:", error)
            self.error = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func hydrate(from a: Athlete) {
        memberNumber = a.memberNumber
        fullName = a.fullName
        fullNameAr = a.fullNameAr
        dateOfBirth = a.dateOfBirth
        nationality = a.nationality
        emiratesID = a.emiratesID ?? ""
        passportNumber = a.passportNumber ?? ""
        bloodType = a.bloodType ?? .unknown
        federationLicenceNumber = a.federationLicenceNumber ?? ""
        worldTaekwondoID = a.worldTaekwondoID ?? ""
        branchID = a.branchID
        joinedAt = a.joinedAt
        emergencyContacts = a.emergencyContacts
        school = a.school ?? ""
        imageRightsConsent = a.imageRightsConsent
        travelPermission = a.travelPermission
        heightCm = a.heightCm ?? 140
        weightKg = a.weightKg
        allergiesText = a.allergies.joined(separator: ", ")
        medicalConditionsText = a.medicalConditions.joined(separator: ", ")
        medicationsText = a.medications.joined(separator: ", ")
        fitToTrain = a.fitToTrain
        beltColor = a.currentBelt.color
        beltKind = a.currentBelt.kind
        beltNumber = a.currentBelt.number
        status = a.status
        weightClass = a.weightClass
        dominantLeg = a.dominantLeg
        dominantStance = a.dominantStance ?? .open
        specialty = a.specialty ?? .kyorugi
        yearsTraining = a.yearsTraining ?? 0
        poomsaeSyllabus = a.poomsaeSyllabus ?? ""
        kyorugiTier = a.kyorugiTier ?? .recreational
        primaryCoachID = a.primaryCoachID
    }

    private func loadCoaches() async {
        guard let branchID else { coachesInBranch = []; return }
        do {
            coachesInBranch = try await session.repository.coaches(branchID: branchID)
        } catch { print("AddAthleteView.loadCoaches:", error) }
    }

    private func save() async {
        let resolvedBranchID = branchID ?? branches.first?.id
        guard let resolvedBranchID else {
            self.error = String(localized: "athlete.error_no_branch")
            showErrorAlert = true
            return
        }
        saving = true
        defer { saving = false }

        let assignedNumber: Int
        if let memberNumber {
            assignedNumber = memberNumber
        } else {
            do {
                assignedNumber = try await session.repository.nextMemberNumber()
                memberNumber = assignedNumber
            } catch {
                print("AddAthleteView.nextMemberNumber failed:", error)
                assignedNumber = 1001 + Int.random(in: 0...8998)
                memberNumber = assignedNumber
            }
        }

        let belt = Belt(color: beltColor, kind: beltKind, number: beltNumber, awardedAt: editing?.currentBelt.awardedAt ?? Date())
        let athlete = Athlete(
            id: editing?.id ?? UUID(),
            memberNumber: assignedNumber,
            fullName: fullName,
            fullNameAr: fullNameAr.isEmpty ? fullName : fullNameAr,
            dateOfBirth: dateOfBirth,
            nationality: nationality.isEmpty ? "AE" : nationality,
            emiratesID: emiratesID.isEmpty ? nil : emiratesID,
            branchID: resolvedBranchID,
            primaryCoachID: primaryCoachID,
            joinedAt: joinedAt,
            currentBelt: belt,
            beltHistory: editing?.beltHistory ?? [belt],
            weightKg: weightKg,
            status: status,
            avatarSeed: editing?.avatarSeed ?? String(fullName.prefix(2)).lowercased(),
            avatarURL: editing?.avatarURL,
            passportNumber: passportNumber.isEmpty ? nil : passportNumber,
            bloodType: bloodType == .unknown ? nil : bloodType,
            federationLicenceNumber: federationLicenceNumber.isEmpty ? nil : federationLicenceNumber,
            worldTaekwondoID: worldTaekwondoID.isEmpty ? nil : worldTaekwondoID,
            parentUserIDs: editing?.parentUserIDs ?? [],
            emergencyContacts: emergencyContacts.filter { !$0.name.isEmpty },
            school: school.isEmpty ? nil : school,
            imageRightsConsent: imageRightsConsent,
            imageRightsConsentDate: imageRightsConsent ? Date() : nil,
            travelPermission: travelPermission,
            travelPermissionDate: travelPermission ? Date() : nil,
            heightCm: heightCm > 0 ? heightCm : nil,
            weightHistory: appendedWeightHistory(),
            allergies: parseList(allergiesText),
            medicalConditions: parseList(medicalConditionsText),
            medications: parseList(medicationsText),
            fitToTrain: fitToTrain,
            injuries: editing?.injuries ?? [],
            weightClass: weightClass,
            dominantLeg: dominantLeg,
            dominantStance: dominantStance,
            specialty: specialty,
            yearsTraining: yearsTraining > 0 ? yearsTraining : nil,
            poomsaeSyllabus: poomsaeSyllabus.isEmpty ? nil : poomsaeSyllabus,
            kyorugiTier: kyorugiTier,
            coachNotes: editing?.coachNotes ?? [],
            documents: editing?.documents ?? [],
            ranking: editing?.ranking
        )
        do {
            try await session.repository.upsert(athlete)
            onCreated(athlete)
            dismiss()
        } catch {
            print("AddAthleteView.save upsert failed:", error)
            self.error = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func parseList(_ raw: String) -> [String] {
        raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func appendedWeightHistory() -> [WeightEntry] {
        guard let editing else { return [WeightEntry(weightKg: weightKg)] }
        let last = editing.weightHistory.max(by: { $0.recordedAt < $1.recordedAt })
        if let last, abs(last.weightKg - weightKg) < 0.01 {
            return editing.weightHistory
        }
        return editing.weightHistory + [WeightEntry(weightKg: weightKg)]
    }
}

// MARK: - Layout primitives

private struct InlineField<Content: View>: View {
    let label: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .scaledFont(.caption2, weight: .semibold)
                .foregroundStyle(.primary.opacity(0.55))
            content
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct FieldRow<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            content
        }
    }
}

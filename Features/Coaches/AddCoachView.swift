import SwiftUI

public struct AddCoachView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let initialBranchID: EntityID?
    public let editing: Coach?
    public let onSaved: (Coach) -> Void

    // === Identity ===
    @State private var fullName: String = ""
    @State private var fullNameAr: String = ""
    @State private var contractType: ContractType = .fullTime
    @State private var hiredAt: Date = Date()
    @State private var danRank: Int = 1
    @State private var bio: String = ""
    @State private var bioAr: String = ""

    // === Assignment ===
    @State private var primaryBranchID: EntityID?
    @State private var secondaryBranchIDs: Set<EntityID> = []
    @State private var weeklyHoursTarget: Int = 0
    @State private var weeklyHoursSet: Bool = false
    @State private var onCall: Bool = false

    // === Credentials ===
    @State private var kukkiwonCertNumber: String = ""
    @State private var kukkiwonIssuedAt: Date = Date()
    @State private var kukkiwonIssuedSet: Bool = false
    @State private var wtCoachLicenceLevel: Int = 1
    @State private var wtLicenceExpiry: Date = Date().addingTimeInterval(365 * 24 * 3600)
    @State private var wtLicenceExpirySet: Bool = false
    @State private var poomsaeRefereeLevel: Int = 0    // 0 == none
    @State private var poomsaeRefereeExpiry: Date = Date().addingTimeInterval(365 * 24 * 3600)
    @State private var poomsaeRefereeExpirySet: Bool = false
    @State private var kyorugiRefereeLevel: Int = 0    // 0 == none
    @State private var kyorugiRefereeExpiry: Date = Date().addingTimeInterval(365 * 24 * 3600)
    @State private var kyorugiRefereeExpirySet: Bool = false
    @State private var firstAidExpiry: Date = Date().addingTimeInterval(365 * 24 * 3600)
    @State private var safeguardingExpiry: Date = Date().addingTimeInterval(365 * 24 * 3600)
    @State private var antiDopingExpiry: Date = Date().addingTimeInterval(365 * 24 * 3600)
    @State private var antiDopingSet: Bool = false

    // === Performance (snapshot) ===
    @State private var cpdHoursThisYear: Double = 0
    @State private var parentSatisfactionAvg: Double = 4
    @State private var parentSatisfactionSet: Bool = false
    @State private var peerReviewAvg: Double = 4
    @State private var peerReviewSet: Bool = false

    // === Loaded data + UI state ===
    @State private var branches: [Branch] = []
    @State private var saving = false
    @State private var error: String?
    @State private var showErrorAlert = false
    @State private var hydrated = false

    public init(initialBranchID: EntityID? = nil, editing: Coach? = nil, onSaved: @escaping (Coach) -> Void) {
        self.initialBranchID = initialBranchID
        self.editing = editing
        self.onSaved = onSaved
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                identityCard
                assignmentCard
                credentialsCard
                performanceCard

                Color.clear.frame(height: 16)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color.appBackground)
        .navigationTitle(Text(editing == nil ? "coach.add" : "coach.edit"))
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
        .alert("coach.save_error", isPresented: $showErrorAlert) {
            Button("action.ok", role: .cancel) {}
        } message: {
            Text(verbatim: error ?? "")
        }
        .task { await load() }
    }

    // MARK: - Identity

    private var identityCard: some View {
        FormSectionCard(icon: "person.text.rectangle.fill", title: "coach.section.identity") {
            FieldRow {
                InlineField(label: "auth.full_name") {
                    compactTextField($fullName, placeholder: "auth.full_name")
                }
                InlineField(label: "auth.full_name_ar") {
                    arabicTextField($fullNameAr, placeholder: "auth.full_name_ar")
                }
            }

            FieldRow {
                InlineField(label: "coach.contract_type") {
                    Menu {
                        ForEach(ContractType.allCases, id: \.self) { t in
                            Button { contractType = t } label: { Text(localizedKey: t.labelKey) }
                        }
                    } label: {
                        compactMenuLabel(text: NSLocalizedString(contractType.labelKey, comment: ""))
                    }
                }
                InlineField(label: "coach.hired_at") {
                    DropdownDatePicker(date: $hiredAt, minYear: 1990, maxYear: currentYear)
                }
                InlineField(label: "coach.dan_rank") {
                    CompactStepper(value: $danRank, range: 1...10, suffix: " Dan")
                        .help(Text("tooltip.dan"))
                }
            }

            InlineField(label: "coach.bio") {
                bioField($bio, placeholder: "coach.bio_placeholder")
            }
            InlineField(label: "coach.bio_ar") {
                bioField($bioAr, placeholder: "coach.bio_placeholder")
            }
        }
    }

    // MARK: - Assignment

    private var assignmentCard: some View {
        FormSectionCard(icon: "building.2.fill", title: "coach.section.assignment") {
            FieldRow {
                InlineField(label: "coach.primary_branch") {
                    Menu {
                        ForEach(branches) { b in
                            Button {
                                primaryBranchID = b.id
                                secondaryBranchIDs.remove(b.id)
                            } label: { Text(verbatim: b.name) }
                        }
                    } label: {
                        compactMenuLabel(text: branches.first(where: { $0.id == primaryBranchID })?.name
                                         ?? String(localized: "filter.all"))
                    }
                }
                InlineField(label: "coach.weekly_hours") {
                    HStack(spacing: 6) {
                        CompactStepper(value: $weeklyHoursTarget, range: 0...80, suffix: " h")
                            .onChange(of: weeklyHoursTarget) { _, v in
                                if v > 0 { weeklyHoursSet = true }
                            }
                        if weeklyHoursSet {
                            Button {
                                weeklyHoursSet = false
                                weeklyHoursTarget = 0
                            } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                InlineField(label: "coach.on_call") {
                    Toggle("", isOn: $onCall)
                        .labelsHidden()
                }
            }

            InlineField(label: "coach.secondary_branches", footer: secondaryBranchFooter) {
                secondaryBranchPicker
            }
        }
    }

    private var secondaryBranchFooter: LocalizedStringKey? {
        secondaryBranchIDs.isEmpty ? "coach.secondary_branches_hint" : nil
    }

    private var secondaryBranchPicker: some View {
        Menu {
            ForEach(branches) { b in
                if b.id != primaryBranchID {
                    Button {
                        if secondaryBranchIDs.contains(b.id) {
                            secondaryBranchIDs.remove(b.id)
                        } else {
                            secondaryBranchIDs.insert(b.id)
                        }
                    } label: {
                        HStack {
                            Text(verbatim: b.name)
                            Spacer()
                            if secondaryBranchIDs.contains(b.id) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                if secondaryBranchIDs.isEmpty {
                    Text("filter.all").foregroundStyle(.secondary)
                } else {
                    Text(verbatim: branches
                        .filter { secondaryBranchIDs.contains($0.id) }
                        .map(\.name)
                        .joined(separator: ", ")
                    )
                    .lineLimit(1)
                    .truncationMode(.tail)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Credentials

    private var credentialsCard: some View {
        FormSectionCard(icon: "checkmark.seal.fill", title: "coach.section.credentials") {
            FieldRow {
                InlineField(label: "coach.kukkiwon_cert") {
                    compactTextField($kukkiwonCertNumber, placeholder: "coach.kukkiwon_cert")
                }
                InlineField(label: "coach.kukkiwon_issued") {
                    optionalDateField(date: $kukkiwonIssuedAt, isSet: $kukkiwonIssuedSet, isPast: true)
                }
            }

            FieldRow {
                InlineField(label: "coach.wt_coach_licence_level") {
                    CompactStepper(value: $wtCoachLicenceLevel, range: 1...4, prefix: "L")
                }
                InlineField(label: "coach.wt_coach_licence_expiry") {
                    optionalDateField(date: $wtLicenceExpiry, isSet: $wtLicenceExpirySet)
                }
            }

            FieldRow {
                InlineField(label: "coach.poomsae_referee_level") {
                    refereeLevelMenu(value: $poomsaeRefereeLevel)
                }
                InlineField(label: "coach.poomsae_referee_expiry") {
                    optionalDateField(date: $poomsaeRefereeExpiry, isSet: $poomsaeRefereeExpirySet)
                        .disabled(poomsaeRefereeLevel == 0)
                        .opacity(poomsaeRefereeLevel == 0 ? 0.4 : 1)
                }
            }

            FieldRow {
                InlineField(label: "coach.kyorugi_referee_level") {
                    refereeLevelMenu(value: $kyorugiRefereeLevel)
                }
                InlineField(label: "coach.kyorugi_referee_expiry") {
                    optionalDateField(date: $kyorugiRefereeExpiry, isSet: $kyorugiRefereeExpirySet)
                        .disabled(kyorugiRefereeLevel == 0)
                        .opacity(kyorugiRefereeLevel == 0 ? 0.4 : 1)
                }
            }

            FieldRow {
                InlineField(label: "coach.first_aid_expiry") {
                    DropdownDatePicker(date: $firstAidExpiry, minYear: currentYear, maxYear: currentYear + 10)
                }
                InlineField(label: "coach.safeguarding_expiry") {
                    DropdownDatePicker(date: $safeguardingExpiry, minYear: currentYear, maxYear: currentYear + 10)
                }
                InlineField(label: "coach.anti_doping_expiry") {
                    optionalDateField(date: $antiDopingExpiry, isSet: $antiDopingSet)
                }
            }
        }
    }

    private func refereeLevelMenu(value: Binding<Int>) -> some View {
        Menu {
            Button { value.wrappedValue = 0 } label: { Text("filter.none") }
            Divider()
            ForEach(1...7, id: \.self) { lvl in
                Button { value.wrappedValue = lvl } label: { Text(verbatim: "Class \(lvl)") }
            }
        } label: {
            compactMenuLabel(text: value.wrappedValue == 0 ? String(localized: "filter.none") : "Class \(value.wrappedValue)")
        }
    }

    // MARK: - Performance

    private var performanceCard: some View {
        FormSectionCard(icon: "chart.bar.fill", title: "coach.section.performance") {
            InlineField(label: "coach.cpd_hours", footer: "coach.cpd_hours_hint") {
                HStack {
                    Slider(value: $cpdHoursThisYear, in: 0...100, step: 1)
                    Text(verbatim: "\(Int(cpdHoursThisYear)) h")
                        .scaledFont(.callout, monospacedDigit: true)
                        .frame(minWidth: 56, alignment: .trailing)
                        .environment(\.layoutDirection, .leftToRight)
                        .tappableDouble($cpdHoursThisYear, in: 0...100)
                }
            }

            FieldRow {
                InlineField(label: "coach.parent_satisfaction") {
                    ratingRow(value: $parentSatisfactionAvg, isSet: $parentSatisfactionSet)
                }
                InlineField(label: "coach.peer_review") {
                    ratingRow(value: $peerReviewAvg, isSet: $peerReviewSet)
                }
            }
        }
    }

    private func ratingRow(value: Binding<Double>, isSet: Binding<Bool>) -> some View {
        HStack(spacing: 8) {
            if isSet.wrappedValue {
                Slider(value: value, in: 0...5, step: 0.1)
                Text(verbatim: String(format: "%.1f", value.wrappedValue))
                    .scaledFont(.callout, monospacedDigit: true)
                    .frame(minWidth: 36, alignment: .trailing)
                    .environment(\.layoutDirection, .leftToRight)
                    .tappableDouble(value, in: 0...5, decimals: 1)
                Button { isSet.wrappedValue = false } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    isSet.wrappedValue = true
                } label: {
                    Label("coach.set_rating", systemImage: "plus.circle")
                        .scaledFont(.callout)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Field helpers

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    private func compactTextField(_ binding: Binding<String>, placeholder: LocalizedStringKey) -> some View {
        TextField(placeholder, text: binding)
            .textFieldStyle(.plain)
            .scaledFont(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func arabicTextField(_ binding: Binding<String>, placeholder: LocalizedStringKey) -> some View {
        TextField(placeholder, text: binding)
            .textFieldStyle(.plain)
            .scaledFont(.callout)
            .multilineTextAlignment(.trailing)
            .environment(\.layoutDirection, .rightToLeft)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func bioField(_ binding: Binding<String>, placeholder: LocalizedStringKey) -> some View {
        TextField(placeholder, text: binding, axis: .vertical)
            .textFieldStyle(.plain)
            .scaledFont(.callout)
            .lineLimit(2...4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactMenuLabel(text: String) -> some View {
        HStack(spacing: 6) {
            Text(verbatim: text)
                .scaledFont(.callout)
                .foregroundStyle(.primary)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func optionalDateField(date: Binding<Date>, isSet: Binding<Bool>, isPast: Bool = false) -> some View {
        HStack(spacing: 6) {
            if isSet.wrappedValue {
                DropdownDatePicker(
                    date: date,
                    minYear: isPast ? 1990 : currentYear - 2,
                    maxYear: isPast ? currentYear : currentYear + 10
                )
                Button { isSet.wrappedValue = false } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    isSet.wrappedValue = true
                } label: {
                    Label("coach.set_date", systemImage: "calendar.badge.plus").scaledFont(.callout)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Validation + persistence

    private var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func load() async {
        do {
            branches = try await session.repository.branches()
            if !hydrated {
                hydrate()
                hydrated = true
            }
        } catch {
            print("AddCoachView.load failed:", error)
            self.error = String(describing: error)
            showErrorAlert = true
        }
    }

    private func hydrate() {
        if let editing {
            fullName = editing.fullName
            fullNameAr = editing.fullNameAr
            contractType = editing.contractType
            hiredAt = editing.hiredAt
            danRank = editing.danRank
            bio = editing.bio ?? ""
            bioAr = editing.bioAr ?? ""

            primaryBranchID = editing.primaryBranchID
            secondaryBranchIDs = Set(editing.secondaryBranchIDs)
            if let h = editing.weeklyHoursTarget {
                weeklyHoursTarget = h
                weeklyHoursSet = true
            }
            onCall = editing.onCall

            kukkiwonCertNumber = editing.kukkiwonCertNumber ?? ""
            if let d = editing.kukkiwonIssuedAt { kukkiwonIssuedAt = d; kukkiwonIssuedSet = true }
            wtCoachLicenceLevel = editing.wtCoachLicenceLevel
            if let d = editing.wtCoachLicenceExpiry { wtLicenceExpiry = d; wtLicenceExpirySet = true }
            poomsaeRefereeLevel = editing.poomsaeRefereeLevel ?? 0
            if let d = editing.poomsaeRefereeExpiry { poomsaeRefereeExpiry = d; poomsaeRefereeExpirySet = true }
            kyorugiRefereeLevel = editing.kyorugiRefereeLevel ?? 0
            if let d = editing.kyorugiRefereeExpiry { kyorugiRefereeExpiry = d; kyorugiRefereeExpirySet = true }
            firstAidExpiry = editing.firstAidExpiry
            safeguardingExpiry = editing.safeguardingExpiry
            if let d = editing.antiDopingExpiry { antiDopingExpiry = d; antiDopingSet = true }

            cpdHoursThisYear = editing.cpdHoursThisYear
            if let v = editing.parentSatisfactionAvg { parentSatisfactionAvg = v; parentSatisfactionSet = true }
            if let v = editing.peerReviewAvg { peerReviewAvg = v; peerReviewSet = true }
        } else if let initialBranchID {
            primaryBranchID = initialBranchID
        }
    }

    private func save() async {
        guard isValid else { return }
        let resolvedBranchID = primaryBranchID ?? branches.first?.id
        guard let resolvedBranchID else {
            self.error = String(localized: "athlete.error_no_branch")
            showErrorAlert = true
            return
        }
        saving = true
        defer { saving = false }

        let trimmedName = fullName.trimmingCharacters(in: .whitespaces)
        let coach = Coach(
            id: editing?.id ?? UUID(),
            fullName: trimmedName,
            fullNameAr: fullNameAr.trimmingCharacters(in: .whitespaces).isEmpty ? trimmedName : fullNameAr.trimmingCharacters(in: .whitespaces),
            primaryBranchID: resolvedBranchID,
            secondaryBranchIDs: Array(secondaryBranchIDs),
            danRank: danRank,
            wtCoachLicenceLevel: wtCoachLicenceLevel,
            firstAidExpiry: firstAidExpiry,
            safeguardingExpiry: safeguardingExpiry,
            contractType: contractType,
            hiredAt: hiredAt,
            avatarSeed: editing?.avatarSeed ?? fullName.lowercased().split(separator: " ").first.map(String.init) ?? "coach",
            avatarURL: editing?.avatarURL,
            kukkiwonCertNumber: kukkiwonCertNumber.isEmpty ? nil : kukkiwonCertNumber,
            kukkiwonIssuedAt: kukkiwonIssuedSet ? kukkiwonIssuedAt : nil,
            wtCoachLicenceExpiry: wtLicenceExpirySet ? wtLicenceExpiry : nil,
            poomsaeRefereeLevel: poomsaeRefereeLevel == 0 ? nil : poomsaeRefereeLevel,
            poomsaeRefereeExpiry: poomsaeRefereeLevel == 0 ? nil : (poomsaeRefereeExpirySet ? poomsaeRefereeExpiry : nil),
            kyorugiRefereeLevel: kyorugiRefereeLevel == 0 ? nil : kyorugiRefereeLevel,
            kyorugiRefereeExpiry: kyorugiRefereeLevel == 0 ? nil : (kyorugiRefereeExpirySet ? kyorugiRefereeExpiry : nil),
            antiDopingExpiry: antiDopingSet ? antiDopingExpiry : nil,
            weeklyHoursTarget: weeklyHoursSet ? weeklyHoursTarget : nil,
            onCall: onCall,
            bio: bio.isEmpty ? nil : bio,
            bioAr: bioAr.isEmpty ? nil : bioAr,
            cpdHoursThisYear: cpdHoursThisYear,
            parentSatisfactionAvg: parentSatisfactionSet ? parentSatisfactionAvg : nil,
            peerReviewAvg: peerReviewSet ? peerReviewAvg : nil,
            // Stage 1.6 dossier — preserve any data set elsewhere (the
            // detail-view edits federation IDs / role / status / notes via
            // a future expanded form). Defaults preserve `editing` state so
            // a save here doesn't wipe the new identity/role fields.
            dateOfBirth: editing?.dateOfBirth,
            gender: editing?.gender,
            nationality: editing?.nationality ?? "AE",
            mobileNumber: editing?.mobileNumber,
            email: editing?.email,
            emiratesID: editing?.emiratesID,
            passportNumber: editing?.passportNumber,
            bloodType: editing?.bloodType,
            federationCoachID: editing?.federationCoachID,
            worldTaekwondoCoachID: editing?.worldTaekwondoCoachID,
            coachLevel: editing?.coachLevel,
            licenseLevel: editing?.licenseLevel,
            specialisation: editing?.specialisation,
            employmentStatus: editing?.employmentStatus ?? .active,
            nationalTeamStatus: editing?.nationalTeamStatus ?? .none,
            olympicProgramStatus: editing?.olympicProgramStatus ?? .none,
            technicalLevel: editing?.technicalLevel,
            sparringLevel: editing?.sparringLevel,
            poomsaeLevel: editing?.poomsaeLevel,
            fitnessLevel: editing?.fitnessLevel,
            coachNotes: editing?.coachNotes ?? [],
            ranking: editing?.ranking
        )

        do {
            try await session.repository.upsert(coach)
            onSaved(coach)
            dismiss()
        } catch {
            print("AddCoachView.save upsert failed:", error)
            self.error = String(describing: error)
            showErrorAlert = true
        }
    }
}

// MARK: - Layout primitives

private struct FormSectionCard<Content: View>: View {
    let icon: String
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .scaledFont(.caption, weight: .bold)
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 5))
                Text(title)
                    .scaledFont(.subheadline, weight: .bold)
                    .foregroundStyle(.primary)
                Spacer()
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                content
            }
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

private struct InlineField<Content: View>: View {
    let label: LocalizedStringKey
    var footer: LocalizedStringKey?
    @ViewBuilder let content: Content

    init(label: LocalizedStringKey, footer: LocalizedStringKey? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .scaledFont(.caption2, weight: .semibold)
                .foregroundStyle(.primary.opacity(0.55))
            content
            if let footer {
                Text(footer)
                    .scaledFont(.caption2)
                    .foregroundStyle(.tertiary)
            }
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

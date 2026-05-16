import SwiftUI

public struct CreateSquadView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    private let existing: AthleteGroup?
    private let onSave: (AthleteGroup) -> Void

    @State private var name = ""
    @State private var nameAr = ""
    @State private var purpose: SquadPurpose = .custom
    @State private var expiresAt: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var hasExpiry = false
    @State private var linkedTournamentID: EntityID?
    @State private var nationalityFilter: String?
    @State private var ageGroupFilter: AgeGroup?
    @State private var genderFilter: Gender?
    @State private var notes = ""
    @State private var selectedAthleteIDs: Set<EntityID> = []

    @State private var allAthletes: [Athlete] = []
    @State private var tournaments: [Tournament] = []

    public init(existing: AthleteGroup? = nil, onSave: @escaping (AthleteGroup) -> Void) {
        self.existing = existing
        self.onSave = onSave
    }

    public var body: some View {
        Form {
            detailsSection
            filtersSection
            expirySection
            athletePickerSection
            if !notes.isEmpty || existing != nil {
                notesSection
            }
        }
        .navigationTitle(Text(existing == nil ? "squad.create" : "squad.edit"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
                    .bareToolbarButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("action.save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedAthleteIDs.isEmpty)
                    .bareToolbarButton()
            }
        }
        .task {
            do {
                allAthletes = try await session.repository.athletes()
                tournaments = try await session.repository.tournaments()
            } catch {
                print("CreateSquadView.load:", error)
            }
            if let existing {
                name = existing.name
                nameAr = existing.nameAr ?? ""
                purpose = existing.purpose
                if let exp = existing.expiresAt {
                    hasExpiry = true
                    expiresAt = exp
                }
                linkedTournamentID = existing.linkedTournamentID
                nationalityFilter = existing.nationalityFilter
                ageGroupFilter = existing.ageGroupFilter
                genderFilter = existing.genderFilter
                notes = existing.notes ?? ""
                selectedAthleteIDs = Set(existing.athleteIDs)
            }
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section(header: Text("squad.details")) {
            TextField(String(localized: "squad.name"), text: $name)
            TextField(String(localized: "squad.name_ar"), text: $nameAr)
            Picker(selection: $purpose) {
                ForEach(SquadPurpose.allCases, id: \.self) { p in
                    Text(localizedKey: p.labelKey).tag(p)
                }
            } label: {
                Text("squad.purpose")
            }
        }
    }

    private var filtersSection: some View {
        Section(header: Text("squad.filters")) {
            Picker(selection: $ageGroupFilter) {
                Text("squad.filter.all_ages").tag(AgeGroup?.none)
                ForEach(AgeGroup.allCases, id: \.self) { ag in
                    Text(localizedKey: ag.labelKey).tag(AgeGroup?.some(ag))
                }
            } label: {
                Text("squad.filter.age_group")
            }
            Picker(selection: $genderFilter) {
                Text("squad.filter.all_genders").tag(Gender?.none)
                ForEach(Gender.allCases, id: \.self) { g in
                    Text(verbatim: g.rawValue.capitalized).tag(Gender?.some(g))
                }
            } label: {
                Text("squad.filter.gender")
            }
            Picker(selection: $nationalityFilter) {
                Text("squad.filter.all_nationalities").tag(String?.none)
                Text("squad.filter.emirati_only").tag(String?.some("AE"))
            } label: {
                Text("squad.filter.nationality")
            }
        }
    }

    private var expirySection: some View {
        Section(header: Text("squad.expiry")) {
            Toggle(isOn: $hasExpiry) {
                Text("squad.has_expiry")
            }
            if hasExpiry {
                DatePicker(
                    String(localized: "squad.expires_at"),
                    selection: $expiresAt,
                    in: Date()...,
                    displayedComponents: .date
                )
            }
            if !upcomingTournaments.isEmpty {
                Picker(selection: $linkedTournamentID) {
                    Text("squad.no_tournament").tag(EntityID?.none)
                    ForEach(upcomingTournaments) { t in
                        Text(verbatim: t.name).tag(EntityID?.some(t.id))
                    }
                } label: {
                    Text("squad.link_tournament")
                }
                .onChange(of: linkedTournamentID) { _, newID in
                    if let t = tournaments.first(where: { $0.id == newID }) {
                        hasExpiry = true
                        expiresAt = t.endsAt
                    }
                }
            }
        }
    }

    private var athletePickerSection: some View {
        Section(header: HStack {
            Text("squad.select_athletes")
            Spacer()
            Text(verbatim: "\(selectedAthleteIDs.count)/\(filteredAthletes.count)")
                .scaledFont(.caption).foregroundStyle(.secondary)
        }) {
            if filteredAthletes.isEmpty {
                Text("squad.no_athletes_match").foregroundStyle(.secondary)
            } else {
                Button(allFilteredSelected ? "squad.deselect_all" : "squad.select_all") {
                    if allFilteredSelected {
                        for a in filteredAthletes { selectedAthleteIDs.remove(a.id) }
                    } else {
                        for a in filteredAthletes { selectedAthleteIDs.insert(a.id) }
                    }
                }
                .scaledFont(.caption)

                ForEach(filteredAthletes) { athlete in
                    Button {
                        toggleAthlete(athlete.id)
                    } label: {
                        HStack(spacing: 10) {
                            Avatar(seed: athlete.avatarSeed, label: athlete.initials, size: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: athlete.fullName)
                                    .foregroundStyle(.primary)
                                HStack(spacing: 4) {
                                    Text(localizedKey: athlete.currentBelt.label)
                                    Text(verbatim: "·")
                                    Text(localizedKey: athlete.ageGroup.labelKey)
                                }
                                .scaledFont(.caption2)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: selectedAthleteIDs.contains(athlete.id)
                                  ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedAthleteIDs.contains(athlete.id)
                                                 ? .blue : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var notesSection: some View {
        Section(header: Text("squad.notes")) {
            TextField(String(localized: "squad.notes_placeholder"), text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Computed

    private var filteredAthletes: [Athlete] {
        allAthletes.filter { a in
            if let ag = ageGroupFilter, a.ageGroup != ag { return false }
            if let g = genderFilter, a.gender != g { return false }
            if let nat = nationalityFilter, a.nationality != nat { return false }
            return true
        }
        .sorted { $0.fullName < $1.fullName }
    }

    private var allFilteredSelected: Bool {
        !filteredAthletes.isEmpty && filteredAthletes.allSatisfy { selectedAthleteIDs.contains($0.id) }
    }

    private var upcomingTournaments: [Tournament] {
        tournaments.filter { $0.endsAt > Date() }.sorted { $0.startsAt < $1.startsAt }
    }

    // MARK: - Actions

    private func toggleAthlete(_ id: EntityID) {
        if selectedAthleteIDs.contains(id) {
            selectedAthleteIDs.remove(id)
        } else {
            selectedAthleteIDs.insert(id)
        }
    }

    private func save() {
        let coachID = session.currentUser?.id ?? UUID()
        let group = AthleteGroup(
            id: existing?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            nameAr: nameAr.isEmpty ? nil : nameAr,
            purpose: purpose,
            createdByCoachID: existing?.createdByCoachID ?? coachID,
            athleteIDs: Array(selectedAthleteIDs),
            createdAt: existing?.createdAt ?? Date(),
            expiresAt: hasExpiry ? expiresAt : nil,
            linkedTournamentID: linkedTournamentID,
            isArchived: existing?.isArchived ?? false,
            nationalityFilter: nationalityFilter,
            ageGroupFilter: ageGroupFilter,
            genderFilter: genderFilter,
            notes: notes.isEmpty ? nil : notes
        )
        onSave(group)
        dismiss()
    }
}

import SwiftUI

public struct ImprovementPlanCard: View {
    @Environment(AppSession.self) private var session
    public let athlete: Athlete

    @State private var plans: [ImprovementPlan] = []
    @State private var drills: [DrillLibraryEntry] = []
    @State private var loading = true
    @State private var editing: ImprovementPlan?
    @State private var showingEditor = false
    @State private var autoFlagging = false

    public init(athlete: Athlete) {
        self.athlete = athlete
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if loading {
                ProgressView().frame(maxWidth: .infinity)
            } else if plans.isEmpty {
                Text("plan.empty")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                ForEach(plans) { plan in
                    planRow(plan)
                }
            }
        }
        .task { await load() }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                ImprovementPlanEditor(
                    athleteID: athlete.id,
                    drills: drills,
                    initial: editing,
                    onSave: { p in Task { await save(p) } },
                    onDelete: editing.map { e in
                        { Task { await delete(id: e.id) } }
                    }
                )
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("athlete.section.improvement_plans").scaledFont(.headline)
            Spacer()
            if canEdit {
                Button {
                    Task { await autoFlag() }
                } label: {
                    if autoFlagging {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("plan.auto_flag", systemImage: "sparkles")
                            .scaledFont(.subheadline)
                            .labelStyle(.titleAndIcon)
                    }
                }
                .disabled(autoFlagging)
                Button {
                    editing = nil
                    showingEditor = true
                } label: {
                    Label("plan.add", systemImage: "plus.circle.fill")
                        .scaledFont(.subheadline)
                        .labelStyle(.titleAndIcon)
                }
            }
        }
    }

    // MARK: - Plan row

    private func planRow(_ plan: ImprovementPlan) -> some View {
        Button {
            guard canEdit else { return }
            editing = plan
            showingEditor = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    statusPill(plan)
                    if plan.isReviewDue {
                        Text("plan.review_due")
                            .scaledFont(.caption2, weight: .semibold)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.red.opacity(0.15), in: Capsule())
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    if let target = plan.targetDate {
                        HStack(spacing: 3) {
                            Image(systemName: "target").scaledFont(.caption2)
                            Text(target, style: .date).scaledFont(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                if !plan.weaknesses.isEmpty {
                    weaknessChips(plan.weaknesses)
                }

                if !plan.recommendedDrillIDs.isEmpty {
                    drillChips(plan.recommendedDrillIDs)
                }

                if !plan.notes.isEmpty {
                    Text(verbatim: plan.notes)
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let review = plan.reviewDate {
                    HStack(spacing: 3) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .scaledFont(.caption2)
                        Text("plan.review_on").scaledFont(.caption2)
                        Text(review, style: .date).scaledFont(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func statusPill(_ plan: ImprovementPlan) -> some View {
        let (color, key): (Color, String) = switch plan.status {
        case .active: (.blue, plan.status.labelKey)
        case .completed: (.green, plan.status.labelKey)
        case .archived: (.gray, plan.status.labelKey)
        }
        return Text(localizedKey: key)
            .scaledFont(.caption2, weight: .semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private func weaknessChips(_ ws: [Weakness]) -> some View {
        HStack(alignment: .top) {
            Image(systemName: "exclamationmark.bubble.fill")
                .scaledFont(.caption2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 3) {
                ForEach(ws) { w in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(severityColor(w.severity))
                            .frame(width: 6, height: 6)
                        Text(localizedKey: w.label)
                            .scaledFont(.caption)
                            .lineLimit(1)
                        if w.source == .peer {
                            Image(systemName: "sparkles")
                                .scaledFont(.caption2)
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
    }

    private func drillChips(_ ids: [EntityID]) -> some View {
        let names = ids.compactMap { id in
            drills.first(where: { $0.id == id })?.name
        }
        return HStack(alignment: .top) {
            Image(systemName: "list.bullet.rectangle.fill")
                .scaledFont(.caption2)
                .foregroundStyle(.tint)
            Text(verbatim: names.joined(separator: ", "))
                .scaledFont(.caption)
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
    }

    private func severityColor(_ severity: WeaknessSeverity) -> Color {
        switch severity {
        case .low: .yellow
        case .medium: .orange
        case .high: .red
        }
    }

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editAthlete)
    }

    // MARK: - Persistence

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            async let p = session.repository.improvementPlans(athleteID: athlete.id)
            async let d = session.repository.drills()
            plans = try await p
            drills = try await d
        } catch {
            print("ImprovementPlanCard.load:", error)
        }
    }

    private func save(_ plan: ImprovementPlan) async {
        do {
            try await session.repository.upsert(plan: plan)
            await load()
        } catch {
            print("ImprovementPlanCard.save:", error)
        }
    }

    private func delete(id: EntityID) async {
        do {
            try await session.repository.deletePlan(id: id)
            await load()
        } catch {
            print("ImprovementPlanCard.delete:", error)
        }
    }

    private func autoFlag() async {
        autoFlagging = true
        defer { autoFlagging = false }
        do {
            // Cohort = athletes in same age group from across the club.
            let allAthletes = try await session.repository.athletes()
            let cohort = allAthletes.filter { $0.ageGroup == athlete.ageGroup && $0.id != athlete.id }

            let athleteMetrics = try await session.repository.physicalMetrics(athleteID: athlete.id)
            var cohortMetrics: [PhysicalMetric] = []
            for peer in cohort {
                let m = try await session.repository.physicalMetrics(athleteID: peer.id)
                cohortMetrics.append(contentsOf: m)
            }

            let weaknesses = WeaknessAnalyzer.flag(
                athleteID: athlete.id,
                athleteMetrics: athleteMetrics,
                cohortMetrics: cohortMetrics,
                labelFor: { kind in kind.labelKey }
            )

            // Open the editor pre-populated with the flagged weaknesses.
            editing = ImprovementPlan(
                athleteID: athlete.id,
                createdByCoachID: session.currentUser?.id,
                weaknesses: weaknesses,
                notes: weaknesses.isEmpty
                    ? String(localized: "plan.auto_flag_empty")
                    : ""
            )
            showingEditor = true
        } catch {
            print("ImprovementPlanCard.autoFlag:", error)
        }
    }
}

// MARK: - Editor sheet

private struct ImprovementPlanEditor: View {
    @Environment(\.dismiss) private var dismiss

    let athleteID: EntityID
    let drills: [DrillLibraryEntry]
    let initial: ImprovementPlan?
    let onSave: (ImprovementPlan) -> Void
    let onDelete: (() -> Void)?

    @State private var weaknesses: [Weakness]
    @State private var selectedDrillIDs: Set<EntityID>
    @State private var notes: String
    @State private var hasTargetDate: Bool
    @State private var targetDate: Date
    @State private var hasReviewDate: Bool
    @State private var reviewDate: Date
    @State private var status: PlanStatus
    @State private var newWeakness: String = ""

    init(
        athleteID: EntityID,
        drills: [DrillLibraryEntry],
        initial: ImprovementPlan?,
        onSave: @escaping (ImprovementPlan) -> Void,
        onDelete: (() -> Void)?
    ) {
        self.athleteID = athleteID
        self.drills = drills
        self.initial = initial
        self.onSave = onSave
        self.onDelete = onDelete
        _weaknesses = State(initialValue: initial?.weaknesses ?? [])
        _selectedDrillIDs = State(initialValue: Set(initial?.recommendedDrillIDs ?? []))
        _notes = State(initialValue: initial?.notes ?? "")
        _hasTargetDate = State(initialValue: initial?.targetDate != nil)
        _targetDate = State(initialValue: initial?.targetDate
            ?? Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date())
        _hasReviewDate = State(initialValue: initial?.reviewDate != nil)
        _reviewDate = State(initialValue: initial?.reviewDate
            ?? Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date())
        _status = State(initialValue: initial?.status ?? .active)
    }

    var body: some View {
        Form {
            weaknessesSection
            drillsSection
            notesSection
            datesSection
            statusSection
            if let onDelete {
                Section {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label("action.delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle(Text(initial == nil ? "plan.add" : "plan.edit"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
                .bareToolbarButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("action.save") { commit() }
                .bareToolbarButton()
            }
        }
    }

    private var weaknessesSection: some View {
        Section {
            ForEach(weaknesses) { w in
                HStack(spacing: 6) {
                    Circle().fill(severityColor(w.severity)).frame(width: 8, height: 8)
                    if w.source == .peer {
                        Text(localizedKey: w.label)
                    } else {
                        Text(verbatim: w.label)
                    }
                    Spacer()
                    if w.source == .peer {
                        Image(systemName: "sparkles").scaledFont(.caption2).foregroundStyle(.tint)
                    }
                    Button {
                        weaknesses.removeAll { $0.id == w.id }
                    } label: {
                        Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                TextField("plan.add_weakness", text: $newWeakness)
                Button {
                    let trimmed = newWeakness.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    weaknesses.append(Weakness(
                        kind: "manual.\(UUID().uuidString.prefix(8))",
                        label: trimmed,
                        severity: .medium,
                        source: .manual
                    ))
                    newWeakness = ""
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .disabled(newWeakness.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Text("plan.weaknesses")
        }
    }

    private var drillsSection: some View {
        Section {
            if drills.isEmpty {
                Text("plan.no_drills")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedDrills) { drill in
                    drillRow(drill)
                }
            }
        } header: {
            Text("plan.recommended_drills")
        }
    }

    /// Sort recommended-for-current-weaknesses drills to the top.
    private var sortedDrills: [DrillLibraryEntry] {
        let weaknessKinds = Set(weaknesses.map(\.kind))
        return drills.sorted { lhs, rhs in
            let lMatch = !Set(lhs.addressesWeaknessTags).isDisjoint(with: weaknessKinds)
            let rMatch = !Set(rhs.addressesWeaknessTags).isDisjoint(with: weaknessKinds)
            if lMatch != rMatch { return lMatch }
            return lhs.name < rhs.name
        }
    }

    private func drillRow(_ drill: DrillLibraryEntry) -> some View {
        let weaknessKinds = Set(weaknesses.map(\.kind))
        let recommended = !Set(drill.addressesWeaknessTags).isDisjoint(with: weaknessKinds)
        let selected = selectedDrillIDs.contains(drill.id)
        return Button {
            if selected {
                selectedDrillIDs.remove(drill.id)
            } else {
                selectedDrillIDs.insert(drill.id)
            }
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: selected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(selected ? Color.tint : Color.secondary)
                    .padding(.top, 1)
                Image(systemName: drill.category.systemIcon)
                    .scaledFont(.caption).foregroundStyle(.tint)
                    .frame(width: 18)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(verbatim: drill.name).scaledFont(.subheadline)
                        if recommended {
                            Text("plan.recommended_for_weaknesses")
                                .scaledFont(.caption2, weight: .semibold)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.green.opacity(0.18), in: Capsule())
                                .foregroundStyle(.green)
                        }
                    }
                    Text(verbatim: drill.summary)
                        .scaledFont(.caption2).foregroundStyle(.secondary).lineLimit(2)
                    HStack(spacing: 4) {
                        if let diff = drill.difficulty {
                            difficultyPill(diff)
                        }
                        if let min = drill.minBelt {
                            metaTag(systemImage: "circle.lefthalf.filled",
                                    textKey: min.label,
                                    color: .blue)
                        }
                        if !drill.equipmentRequired.isEmpty {
                            metaTag(systemImage: "shippingbox.fill",
                                    text: drill.equipmentRequired.joined(separator: ", "),
                                    color: .purple)
                        }
                    }
                }
                Spacer(minLength: 0)
                if let mins = drill.durationMinutes {
                    Text(verbatim: "\(mins)m")
                        .scaledFont(.caption2, monospacedDigit: true)
                        .foregroundStyle(.secondary)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func difficultyPill(_ d: DrillDifficulty) -> some View {
        let color: Color = switch d {
        case .beginner: .green
        case .intermediate: .orange
        case .advanced: .red
        }
        return Text(localizedKey: d.labelKey)
            .scaledFont(.caption2, weight: .semibold)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private func metaTag(systemImage: String, text: String? = nil, textKey: String? = nil, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: systemImage)
                .scaledFont(.caption2)
                .foregroundStyle(color)
            if let textKey {
                Text(localizedKey: textKey)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            } else if let text {
                Text(verbatim: text)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var notesSection: some View {
        Section {
            TextField("plan.notes", text: $notes, axis: .vertical)
                .lineLimit(2...5)
        } header: {
            Text("plan.notes")
        }
    }

    private var datesSection: some View {
        Section {
            Toggle("plan.has_target_date", isOn: $hasTargetDate)
            if hasTargetDate {
                DatePicker("plan.target_date", selection: $targetDate, displayedComponents: .date)
            }
            Toggle("plan.has_review_date", isOn: $hasReviewDate)
            if hasReviewDate {
                DatePicker("plan.review_date", selection: $reviewDate, displayedComponents: .date)
            }
        }
    }

    private var statusSection: some View {
        Section {
            Picker("plan.status", selection: $status) {
                ForEach(PlanStatus.allCases, id: \.self) { s in
                    Text(localizedKey: s.labelKey).tag(s)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func severityColor(_ s: WeaknessSeverity) -> Color {
        switch s {
        case .low: .yellow
        case .medium: .orange
        case .high: .red
        }
    }

    private func commit() {
        let plan = ImprovementPlan(
            id: initial?.id ?? UUID(),
            athleteID: athleteID,
            createdAt: initial?.createdAt ?? Date(),
            createdByCoachID: initial?.createdByCoachID,
            weaknesses: weaknesses,
            recommendedDrillIDs: Array(selectedDrillIDs),
            notes: notes,
            targetDate: hasTargetDate ? targetDate : nil,
            reviewDate: hasReviewDate ? reviewDate : nil,
            status: status
        )
        onSave(plan)
        dismiss()
    }
}


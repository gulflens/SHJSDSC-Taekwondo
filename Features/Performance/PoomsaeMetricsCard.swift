import SwiftUI

public struct PoomsaeMetricsCard: View {
    @Environment(AppSession.self) private var session
    @Binding var athlete: Athlete

    @State private var assessments: [PoomsaeAssessment] = []
    @State private var loading = true
    @State private var sheetTarget: SheetTarget?

    public init(athlete: Binding<Athlete>) {
        self._athlete = athlete
    }

    private struct SheetTarget: Identifiable {
        let editing: PoomsaeAssessment?
        let initialForm: PoomsaeForm?
        var id: String {
            if let editing { return "edit.\(editing.id.uuidString)" }
            if let initialForm { return "new.\(initialForm.rawValue)" }
            return "new"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if loading {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                repertoireGrid
                if !assessments.isEmpty {
                    recentAssessments
                }
            }
        }
        .task { await load() }
        .sheet(item: $sheetTarget) { target in
            NavigationStack {
                PoomsaeAssessmentEditor(
                    athlete: athlete,
                    initialForm: target.initialForm,
                    editing: target.editing,
                    onSave: { a in Task { await save(a) } },
                    onDelete: target.editing.map { entry in
                        { Task { await delete(id: entry.id) } }
                    }
                )
            }
        }
    }

    private var header: some View {
        HStack {
            Text("athlete.section.poomsae").scaledFont(.headline)
            Spacer()
            if canEdit {
                Button {
                    sheetTarget = SheetTarget(editing: nil, initialForm: nil)
                } label: {
                    Label("poomsae.add_assessment", systemImage: "plus.circle.fill")
                        .scaledFont(.subheadline)
                        .labelStyle(.titleAndIcon)
                }
            }
        }
    }

    // MARK: - Repertoire grid

    private var repertoireGrid: some View {
        let cols = [GridItem(.adaptive(minimum: 130), spacing: 8)]
        let latest = assessments.latestPerForm()
        let lookup = Dictionary(uniqueKeysWithValues: latest.map { ($0.form, $0) })
        return VStack(alignment: .leading, spacing: 6) {
            Text("poomsae.repertoire").scaledFont(.subheadline, weight: .bold)
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(PoomsaeForm.allCases, id: \.self) { form in
                    repertoireTile(form: form, latestAssessment: lookup[form])
                }
            }
        }
    }

    private func repertoireTile(form: PoomsaeForm, latestAssessment: PoomsaeAssessment?) -> some View {
        let isKnown = athlete.poomsaeKnown.contains(form)
        let isRequired = form.isRequired(for: athlete.currentBelt)
        return Button {
            guard canEdit else { return }
            sheetTarget = SheetTarget(editing: latestAssessment, initialForm: form)
        } label: {
            HStack(alignment: .top, spacing: 6) {
                Button {
                    guard canEdit else { return }
                    Task { await toggleKnown(form) }
                } label: {
                    Image(systemName: isKnown ? "checkmark.circle.fill" : "circle")
                        .scaledFont(.callout)
                        .foregroundStyle(isKnown ? Color.green : Color.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizedKey: form.labelKey)
                        .scaledFont(.caption, weight: .semibold)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        if isRequired && !isKnown {
                            Text("poomsae.required")
                                .scaledFont(.caption2, weight: .semibold)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.orange.opacity(0.18), in: Capsule())
                                .foregroundStyle(.orange)
                        }
                        if let latestAssessment {
                            Text(verbatim: String(format: "%.1f", latestAssessment.averageScore))
                                .scaledFont(.caption2, monospacedDigit: true)
                                .foregroundStyle(scoreColor(latestAssessment.averageScore))
                                .environment(\.layoutDirection, .leftToRight)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isKnown ? Color.green.opacity(0.4) : Color.primary.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent assessments

    private var recentAssessments: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("poomsae.recent_assessments").scaledFont(.subheadline, weight: .bold)
            ForEach(assessments.prefix(5)) { a in
                Button {
                    guard canEdit else { return }
                    sheetTarget = SheetTarget(editing: a, initialForm: nil)
                } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localizedKey: a.form.labelKey)
                                .scaledFont(.subheadline)
                                .foregroundStyle(.primary)
                            HStack(spacing: 4) {
                                Text(a.recordedAt, style: .date)
                                if a.timeSeconds > 0 {
                                    Text(verbatim: "·")
                                    Text(verbatim: "\(a.timeSeconds)s")
                                        .environment(\.layoutDirection, .leftToRight)
                                }
                                if a.videoURL?.isEmpty == false {
                                    Image(systemName: "video.fill")
                                }
                            }
                            .scaledFont(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        averagePill(a.averageScore)
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func averagePill(_ avg: Double) -> some View {
        Text(verbatim: String(format: "%.1f", avg))
            .scaledFont(.callout, weight: .bold, monospacedDigit: true)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(scoreColor(avg).opacity(0.15), in: Capsule())
            .foregroundStyle(scoreColor(avg))
            .environment(\.layoutDirection, .leftToRight)
    }

    private func scoreColor(_ avg: Double) -> Color {
        switch avg {
        case ..<5: .red
        case 5..<7: .orange
        case 7..<9: .blue
        default: .green
        }
    }

    // MARK: - Permissions + persistence

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editAthlete)
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            assessments = try await session.repository.poomsaeAssessments(athleteID: athlete.id)
        } catch {
            print("PoomsaeMetricsCard.load:", error)
        }
    }

    private func save(_ a: PoomsaeAssessment) async {
        // Recording an assessment implicitly adds the form to the repertoire.
        if !athlete.poomsaeKnown.contains(a.form) {
            athlete.poomsaeKnown.insert(a.form)
            do {
                try await session.repository.upsert(athlete)
            } catch {
                print("PoomsaeMetricsCard.save athlete:", error)
            }
        }
        do {
            try await session.repository.upsert(poomsae: a)
            await load()
        } catch {
            print("PoomsaeMetricsCard.save:", error)
        }
    }

    private func delete(id: EntityID) async {
        do {
            try await session.repository.deletePoomsaeAssessment(id: id)
            await load()
        } catch {
            print("PoomsaeMetricsCard.delete:", error)
        }
    }

    private func toggleKnown(_ form: PoomsaeForm) async {
        if athlete.poomsaeKnown.contains(form) {
            athlete.poomsaeKnown.remove(form)
        } else {
            athlete.poomsaeKnown.insert(form)
        }
        do {
            try await session.repository.upsert(athlete)
        } catch {
            print("PoomsaeMetricsCard.toggleKnown:", error)
        }
    }
}

// MARK: - Editor sheet

private struct PoomsaeAssessmentEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var session

    let athlete: Athlete
    let initialForm: PoomsaeForm?
    let editing: PoomsaeAssessment?
    let onSave: (PoomsaeAssessment) -> Void
    let onDelete: (() -> Void)?

    @State private var form: PoomsaeForm
    @State private var recordedAt: Date
    @State private var accuracy: Int
    @State private var presentation: Int
    @State private var balance: Int
    @State private var expression: Int
    @State private var timeSeconds: Int
    @State private var videoURL: String
    @State private var notes: String

    init(
        athlete: Athlete,
        initialForm: PoomsaeForm?,
        editing: PoomsaeAssessment?,
        onSave: @escaping (PoomsaeAssessment) -> Void,
        onDelete: (() -> Void)?
    ) {
        self.athlete = athlete
        self.initialForm = initialForm
        self.editing = editing
        self.onSave = onSave
        self.onDelete = onDelete
        let resolvedForm = editing?.form ?? initialForm ?? .taegeuk1
        _form = State(initialValue: resolvedForm)
        _recordedAt = State(initialValue: editing?.recordedAt ?? Date())
        _accuracy = State(initialValue: editing?.accuracy ?? 7)
        _presentation = State(initialValue: editing?.presentation ?? 7)
        _balance = State(initialValue: editing?.balance ?? 7)
        _expression = State(initialValue: editing?.expression ?? 7)
        _timeSeconds = State(initialValue: editing?.timeSeconds ?? 60)
        _videoURL = State(initialValue: editing?.videoURL ?? "")
        _notes = State(initialValue: editing?.notes ?? "")
    }

    var body: some View {
        Form {
            Section {
                Picker("poomsae.form", selection: $form) {
                    ForEach(PoomsaeForm.allCases, id: \.self) { f in
                        Text(localizedKey: f.labelKey).tag(f)
                    }
                }
                DatePicker("athlete.weight_recorded_at", selection: $recordedAt, displayedComponents: .date)
            }

            Section {
                scoreRow(title: "poomsae.accuracy", value: $accuracy)
                scoreRow(title: "poomsae.presentation", value: $presentation)
                scoreRow(title: "poomsae.balance", value: $balance)
                scoreRow(title: "poomsae.expression", value: $expression)
            } footer: {
                Text("poomsae.score_help").scaledFont(.caption2).foregroundStyle(.secondary)
            }

            Section {
                Stepper(value: $timeSeconds, in: 0...300) {
                    HStack {
                        Text("poomsae.time_seconds")
                        Spacer()
                        Text(verbatim: "\(timeSeconds) s")
                            .scaledFont(.callout, monospacedDigit: true)
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
            }

            Section {
                TextField("technique.video_url", text: $videoURL)
                    #if os(iOS)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif
            } header: {
                Text("technique.video_url")
            }

            Section {
                TextField("athlete.injury_notes", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

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
        .navigationTitle(Text(editing == nil ? "poomsae.add_assessment" : "poomsae.edit_assessment"))
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
                    .disabled(session.currentUser == nil)
                .bareToolbarButton()
            }
        }
    }

    private func scoreRow(title: LocalizedStringKey, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).scaledFont(.subheadline)
                Spacer()
                Text(verbatim: "\(value.wrappedValue) / 10")
                    .scaledFont(.callout, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(.tint)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0.rounded()) }
                ),
                in: 1...10,
                step: 1
            )
        }
    }

    private func commit() {
        guard let coachID = session.currentUser?.id else { return }
        let trimmed = videoURL.trimmingCharacters(in: .whitespaces)
        let a = PoomsaeAssessment(
            id: editing?.id ?? UUID(),
            athleteID: athlete.id,
            recordedAt: recordedAt,
            recordedByCoachID: editing?.recordedByCoachID ?? coachID,
            form: form,
            accuracy: accuracy,
            presentation: presentation,
            balance: balance,
            expression: expression,
            timeSeconds: timeSeconds,
            videoURL: trimmed.isEmpty ? nil : trimmed,
            notes: notes.isEmpty ? nil : notes
        )
        onSave(a)
        dismiss()
    }
}

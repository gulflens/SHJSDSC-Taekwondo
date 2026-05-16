import SwiftUI

public struct TrainingLoadCard: View {
    @Environment(AppSession.self) private var session
    public let athleteID: EntityID

    @State private var entries: [TrainingLoadEntry] = []
    @State private var loading = true
    @State private var editing: TrainingLoadEntry?
    @State private var showingAdd = false

    public init(athleteID: EntityID) {
        self.athleteID = athleteID
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if loading {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                kpiStrip
                if entries.isEmpty {
                    Text("training_load.empty")
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                } else {
                    recentEntries
                }
            }
        }
        .task { await load() }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                TrainingLoadEditor(
                    athleteID: athleteID,
                    initial: editing,
                    onSave: { entry in Task { await save(entry) } },
                    onDelete: editing.map { e in
                        { Task { await delete(id: e.id) } }
                    }
                )
            }
        }
    }

    private var header: some View {
        HStack {
            Text("athlete.section.training_load").scaledFont(.headline)
            Spacer()
            if canEdit {
                Button {
                    editing = nil
                    showingAdd = true
                } label: {
                    Label("training_load.add", systemImage: "plus.circle.fill")
                        .scaledFont(.subheadline)
                        .labelStyle(.titleAndIcon)
                }
            }
        }
    }

    @ViewBuilder
    private var kpiStrip: some View {
        let acute = entries.acuteLoad()
        let chronic = entries.chronicLoad()
        let acwr = entries.acwr()
        let risk = entries.loadRisk()

        HStack(spacing: 8) {
            kpiTile(label: "training_load.acute", value: String(format: "%.0f", acute), suffix: "AU")
                .help(Text("tooltip.au"))
            kpiTile(label: "training_load.chronic", value: String(format: "%.0f", chronic), suffix: "AU")
                .help(Text("tooltip.au"))
            acwrTile(value: acwr, risk: risk)
                .help(Text("tooltip.acwr"))
        }
    }

    private func kpiTile(label: LocalizedStringKey, value: String, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(verbatim: value)
                    .scaledFont(.title3, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(.primary)
                Text(verbatim: suffix)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 8))
    }

    private func acwrTile(value: Double?, risk: LoadRisk) -> some View {
        let color = riskColor(risk)
        return VStack(alignment: .leading, spacing: 2) {
            Text("training_load.acwr")
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: value.map { String(format: "%.2f", $0) } ?? "—")
                    .scaledFont(.title3, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(color)
                    .environment(\.layoutDirection, .leftToRight)
                Text(localizedKey: risk.labelKey)
                    .scaledFont(.caption2, weight: .semibold)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(color.opacity(0.18), in: Capsule())
                    .foregroundStyle(color)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.3), lineWidth: 0.5)
        )
    }

    private func riskColor(_ risk: LoadRisk) -> Color {
        switch risk {
        case .undertrained: .blue
        case .sweet: .green
        case .elevated: .orange
        case .danger: .red
        case .unknown: .gray
        }
    }

    private var recentEntries: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(entries.prefix(8)) { entry in
                entryRow(entry)
            }
        }
    }

    private func entryRow(_ entry: TrainingLoadEntry) -> some View {
        Button {
            guard canEdit else { return }
            editing = entry
            showingAdd = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: entry.sessionType.systemIcon)
                    .scaledFont(.callout)
                    .foregroundStyle(.tint)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(localizedKey: entry.sessionType.labelKey)
                            .scaledFont(.subheadline)
                        Text(verbatim: "·").foregroundStyle(.secondary)
                        Text(verbatim: "\(entry.durationMinutes) min")
                            .scaledFont(.caption2)
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                        Text(verbatim: "·").foregroundStyle(.secondary)
                        Text(verbatim: "RPE \(entry.rpe)")
                            .scaledFont(.caption2)
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                            .help(Text("tooltip.rpe"))
                    }
                    Text(entry.recordedAt, style: .date)
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(verbatim: String(format: "%.0f AU", entry.sessionLoad))
                    .scaledFont(.callout, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(.tint)
                    .environment(\.layoutDirection, .leftToRight)
                    .help(Text("tooltip.au"))
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editAthlete)
    }

    private func load() async {
        loading = true
        defer { loading = false }
        let since = Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date()
        do {
            entries = try await session.repository.trainingLoad(athleteID: athleteID, since: since)
        } catch {
            print("TrainingLoadCard.load:", error)
        }
    }

    private func save(_ entry: TrainingLoadEntry) async {
        do {
            try await session.repository.upsert(load: entry)
            await load()
        } catch {
            print("TrainingLoadCard.save:", error)
        }
    }

    private func delete(id: EntityID) async {
        do {
            try await session.repository.deleteTrainingLoad(id: id)
            await load()
        } catch {
            print("TrainingLoadCard.delete:", error)
        }
    }
}

// MARK: - Editor sheet

private struct TrainingLoadEditor: View {
    @Environment(\.dismiss) private var dismiss

    let athleteID: EntityID
    let initial: TrainingLoadEntry?
    let onSave: (TrainingLoadEntry) -> Void
    let onDelete: (() -> Void)?

    @State private var recordedAt: Date
    @State private var sessionType: SessionType
    @State private var durationMinutes: Int
    @State private var rpe: Int
    @State private var notes: String

    init(
        athleteID: EntityID,
        initial: TrainingLoadEntry?,
        onSave: @escaping (TrainingLoadEntry) -> Void,
        onDelete: (() -> Void)?
    ) {
        self.athleteID = athleteID
        self.initial = initial
        self.onSave = onSave
        self.onDelete = onDelete
        _recordedAt = State(initialValue: initial?.recordedAt ?? Date())
        _sessionType = State(initialValue: initial?.sessionType ?? .technique)
        _durationMinutes = State(initialValue: initial?.durationMinutes ?? 60)
        _rpe = State(initialValue: initial?.rpe ?? 6)
        _notes = State(initialValue: initial?.notes ?? "")
    }

    var body: some View {
        Form {
            Section {
                DatePicker("training_load.date", selection: $recordedAt, displayedComponents: .date)
                Picker("training_load.session_type", selection: $sessionType) {
                    ForEach(SessionType.allCases, id: \.self) { t in
                        Label {
                            Text(localizedKey: t.labelKey)
                        } icon: {
                            Image(systemName: t.systemIcon)
                        }
                        .tag(t)
                    }
                }
            }

            Section {
                Stepper(value: $durationMinutes, in: 0...300, step: 5) {
                    HStack {
                        Text("training_load.duration")
                        Spacer()
                        Text(verbatim: "\(durationMinutes) min")
                            .scaledFont(.callout, monospacedDigit: true)
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("training_load.rpe").scaledFont(.subheadline)
                            .help(Text("tooltip.rpe"))
                        Spacer()
                        Text(verbatim: "\(rpe) / 10")
                            .scaledFont(.callout, weight: .bold, monospacedDigit: true)
                            .foregroundStyle(.tint)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(rpe) },
                            set: { rpe = Int($0.rounded()) }
                        ),
                        in: 1...10,
                        step: 1
                    )
                }
            } footer: {
                let load = Double(durationMinutes) * Double(rpe)
                Text(verbatim: String(format: NSLocalizedString("training_load.session_load", comment: ""), load))
                    .scaledFont(.caption2, monospacedDigit: true)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
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
        .navigationTitle(Text(initial == nil ? "training_load.add" : "training_load.edit"))
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

    private func commit() {
        let entry = TrainingLoadEntry(
            id: initial?.id ?? UUID(),
            athleteID: athleteID,
            sessionID: initial?.sessionID,
            recordedAt: recordedAt,
            sessionType: sessionType,
            durationMinutes: durationMinutes,
            rpe: rpe,
            notes: notes.isEmpty ? nil : notes
        )
        onSave(entry)
        dismiss()
    }
}

import SwiftUI

public struct InjuryLogCard: View {
    @Environment(AppSession.self) private var session
    @Binding var athlete: Athlete
    @State private var showingEditor = false
    @State private var editingEntry: InjuryEntry?

    public init(athlete: Binding<Athlete>) {
        self._athlete = athlete
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if athlete.injuries.isEmpty {
                Text("athlete.no_injuries_yet")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                ForEach(sortedInjuries) { entry in
                    InjuryRow(entry: entry)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard canEdit else { return }
                            editingEntry = entry
                            showingEditor = true
                        }
                        .contextMenu {
                            if canEdit {
                                Button {
                                    editingEntry = entry
                                    showingEditor = true
                                } label: {
                                    Label("action.edit", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    Task { await delete(id: entry.id) }
                                } label: {
                                    Label("action.delete", systemImage: "trash")
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                InjuryEditorSheet(
                    initial: editingEntry,
                    onSave: { entry in Task { await save(entry) } },
                    onDelete: editingEntry.map { entry in
                        { Task { await delete(id: entry.id) } }
                    }
                )
            }
        }
    }

    private var header: some View {
        HStack {
            Text("athlete.section.injuries").scaledFont(.headline)
            Spacer()
            if canEdit {
                Button {
                    editingEntry = nil
                    showingEditor = true
                } label: {
                    Label("athlete.add_injury", systemImage: "plus.circle.fill")
                        .scaledFont(.subheadline)
                        .labelStyle(.titleAndIcon)
                }
            }
        }
    }

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editAthlete)
    }

    private var sortedInjuries: [InjuryEntry] {
        athlete.injuries.sorted { $0.recordedAt > $1.recordedAt }
    }

    private func save(_ entry: InjuryEntry) async {
        if let idx = athlete.injuries.firstIndex(where: { $0.id == entry.id }) {
            athlete.injuries[idx] = entry
        } else {
            athlete.injuries.append(entry)
        }
        do {
            try await session.repository.upsert(athlete)
        } catch {
            print("InjuryLogCard.save:", error)
        }
    }

    private func delete(id: EntityID) async {
        athlete.injuries.removeAll { $0.id == id }
        do {
            try await session.repository.upsert(athlete)
        } catch {
            print("InjuryLogCard.delete:", error)
        }
    }
}

// MARK: - Row

private struct InjuryRow: View {
    let entry: InjuryEntry

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            severityBadge
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.recordedAt, style: .date)
                        .scaledFont(.caption, weight: .bold)
                    Text(verbatim: "·").scaledFont(.caption2).foregroundStyle(.secondary)
                    statePill
                }
                Text(verbatim: entry.description.isEmpty ? "—" : entry.description)
                    .scaledFont(.subheadline)
                if let returnDate = entry.returnToTrainAt {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.checkmark")
                            .scaledFont(.caption2)
                            .foregroundStyle(.green)
                        Text("athlete.return_to_train").scaledFont(.caption2).foregroundStyle(.secondary)
                        Text(returnDate, style: .date).scaledFont(.caption2).foregroundStyle(.secondary)
                    }
                }
                if let notes = entry.notes, !notes.isEmpty {
                    Text(verbatim: notes)
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(10)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 8))
    }

    private var severityBadge: some View {
        VStack(spacing: 2) {
            Image(systemName: severityIcon)
                .scaledFont(.caption, weight: .bold)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(severityColor, in: Circle())
            Text(localizedKey: entry.severity.labelKey)
                .scaledFont(.caption2)
                .foregroundStyle(severityColor)
        }
    }

    private var statePill: some View {
        let isActive = entry.returnToTrainAt == nil || (entry.returnToTrainAt ?? Date()) > Date()
        return Text(isActive ? "athlete.injury_active" : "athlete.injury_recovered")
            .scaledFont(.caption2, weight: .semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background((isActive ? Color.orange : Color.green).opacity(0.15), in: Capsule())
            .foregroundStyle(isActive ? .orange : .green)
    }

    private var severityColor: Color {
        switch entry.severity {
        case .minor: .yellow
        case .moderate: .orange
        case .severe: .red
        }
    }

    private var severityIcon: String {
        switch entry.severity {
        case .minor: "bandage.fill"
        case .moderate: "cross.case.fill"
        case .severe: "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Editor sheet

private struct InjuryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let initial: InjuryEntry?
    let onSave: (InjuryEntry) -> Void
    let onDelete: (() -> Void)?

    @State private var recordedAt: Date
    @State private var description: String
    @State private var severity: InjurySeverity
    @State private var hasReturnDate: Bool
    @State private var returnToTrainAt: Date
    @State private var notes: String

    init(initial: InjuryEntry?, onSave: @escaping (InjuryEntry) -> Void, onDelete: (() -> Void)?) {
        self.initial = initial
        self.onSave = onSave
        self.onDelete = onDelete
        _recordedAt = State(initialValue: initial?.recordedAt ?? Date())
        _description = State(initialValue: initial?.description ?? "")
        _severity = State(initialValue: initial?.severity ?? .minor)
        _hasReturnDate = State(initialValue: initial?.returnToTrainAt != nil)
        _returnToTrainAt = State(initialValue: initial?.returnToTrainAt
            ?? Calendar.current.date(byAdding: .day, value: 14, to: Date())
            ?? Date())
        _notes = State(initialValue: initial?.notes ?? "")
    }

    var body: some View {
        Form {
            Section {
                DatePicker("athlete.weight_recorded_at", selection: $recordedAt, displayedComponents: .date)
                Picker("athlete.injury_severity", selection: $severity) {
                    ForEach(InjurySeverity.allCases, id: \.self) { s in
                        Text(localizedKey: s.labelKey).tag(s)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                TextField("athlete.injury_description", text: $description, axis: .vertical)
                    .lineLimit(2...5)
            }

            Section {
                Toggle("athlete.return_to_train", isOn: $hasReturnDate)
                if hasReturnDate {
                    DatePicker("athlete.return_to_train", selection: $returnToTrainAt, displayedComponents: .date)
                }
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
        .navigationTitle(initial == nil ? Text("athlete.add_injury") : Text("athlete.section.injuries"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
                .bareToolbarButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("action.save") {
                    let entry = InjuryEntry(
                        id: initial?.id ?? UUID(),
                        recordedAt: recordedAt,
                        description: description,
                        severity: severity,
                        returnToTrainAt: hasReturnDate ? returnToTrainAt : nil,
                        notes: notes.isEmpty ? nil : notes
                    )
                    onSave(entry)
                    dismiss()
                }
                .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty)
                .bareToolbarButton()
            }
        }
    }
}

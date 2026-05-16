import SwiftUI

public struct GoalsCard: View {
    @Environment(AppSession.self) private var session
    public let athleteID: EntityID

    @State private var goals: [Goal] = []
    @State private var loading = true
    @State private var editing: Goal?
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
                completionRow
                if goals.isEmpty {
                    Text("goals.empty")
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                } else {
                    ForEach(goals) { goal in
                        goalRow(goal)
                    }
                }
            }
        }
        .task { await load() }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                GoalEditorSheet(
                    athleteID: athleteID,
                    initial: editing,
                    onSave: { g in Task { await save(g) } },
                    onDelete: editing.map { entry in
                        { Task { await delete(id: entry.id) } }
                    }
                )
            }
        }
    }

    private var header: some View {
        HStack {
            Text("athlete.section.goals").scaledFont(.headline)
            Spacer()
            if canEdit {
                Button {
                    editing = nil
                    showingAdd = true
                } label: {
                    Label("goals.add", systemImage: "plus.circle.fill")
                        .scaledFont(.subheadline)
                        .labelStyle(.titleAndIcon)
                }
            }
        }
    }

    @ViewBuilder
    private var completionRow: some View {
        if let rate = goals.completionRate {
            let pct = Int((rate * 100).rounded())
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .foregroundStyle(.tint)
                Text("goals.completion_rate")
                    .scaledFont(.caption, weight: .semibold)
                Spacer()
                Text(verbatim: "\(pct)%")
                    .scaledFont(.callout, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(.tint)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .padding(8)
            .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func goalRow(_ goal: Goal) -> some View {
        Button {
            guard canEdit else { return }
            editing = goal
            showingAdd = true
        } label: {
            HStack(alignment: .top, spacing: 10) {
                statusIcon(goal)
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: goal.title)
                        .scaledFont(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        statusPill(goal)
                        if let target = goal.targetDate {
                            Text(target, style: .date)
                                .scaledFont(.caption2)
                                .foregroundStyle(goal.isOverdue ? .red : .secondary)
                        }
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func statusIcon(_ goal: Goal) -> some View {
        let (icon, color): (String, Color) = switch goal.status {
        case .active: ("circle", goal.isOverdue ? Color.red : Color.tint)
        case .completed: ("checkmark.circle.fill", Color.green)
        case .abandoned: ("xmark.circle.fill", Color.secondary)
        }
        return Image(systemName: icon)
            .scaledFont(.title3)
            .foregroundStyle(color)
    }

    private func statusPill(_ goal: Goal) -> some View {
        let (color, key): (Color, String) = {
            if goal.isOverdue { return (.red, "goal.status.overdue") }
            switch goal.status {
            case .active: return (.blue, goal.status.labelKey)
            case .completed: return (.green, goal.status.labelKey)
            case .abandoned: return (.gray, goal.status.labelKey)
            }
        }()
        return Text(localizedKey: key)
            .scaledFont(.caption2, weight: .semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editAthlete)
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            goals = try await session.repository.goals(athleteID: athleteID)
        } catch {
            print("GoalsCard.load:", error)
        }
    }

    private func save(_ g: Goal) async {
        do {
            try await session.repository.upsert(goal: g)
            await load()
        } catch {
            print("GoalsCard.save:", error)
        }
    }

    private func delete(id: EntityID) async {
        do {
            try await session.repository.deleteGoal(id: id)
            await load()
        } catch {
            print("GoalsCard.delete:", error)
        }
    }
}

// MARK: - Editor sheet

private struct GoalEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let athleteID: EntityID
    let initial: Goal?
    let onSave: (Goal) -> Void
    let onDelete: (() -> Void)?

    @State private var title: String
    @State private var hasTargetDate: Bool
    @State private var targetDate: Date
    @State private var status: GoalStatus
    @State private var notes: String

    init(athleteID: EntityID, initial: Goal?, onSave: @escaping (Goal) -> Void, onDelete: (() -> Void)?) {
        self.athleteID = athleteID
        self.initial = initial
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: initial?.title ?? "")
        _hasTargetDate = State(initialValue: initial?.targetDate != nil)
        _targetDate = State(initialValue: initial?.targetDate
            ?? Calendar.current.date(byAdding: .month, value: 3, to: Date())
            ?? Date())
        _status = State(initialValue: initial?.status ?? .active)
        _notes = State(initialValue: initial?.notes ?? "")
    }

    var body: some View {
        Form {
            Section {
                TextField("goal.title", text: $title, axis: .vertical)
                    .lineLimit(1...3)
            }
            Section {
                Toggle("goal.has_target_date", isOn: $hasTargetDate)
                if hasTargetDate {
                    DatePicker("goal.target_date", selection: $targetDate, displayedComponents: .date)
                }
            }
            Section {
                Picker("goal.status", selection: $status) {
                    ForEach(GoalStatus.allCases, id: \.self) { s in
                        Text(localizedKey: s.labelKey).tag(s)
                    }
                }
                .pickerStyle(.segmented)
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
        .navigationTitle(Text(initial == nil ? "goals.add" : "goals.edit"))
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
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                .bareToolbarButton()
            }
        }
    }

    private func commit() {
        let completedAt: Date? = (status == .completed)
            ? (initial?.completedAt ?? Date())
            : nil
        let g = Goal(
            id: initial?.id ?? UUID(),
            athleteID: athleteID,
            title: title,
            targetDate: hasTargetDate ? targetDate : nil,
            status: status,
            createdAt: initial?.createdAt ?? Date(),
            completedAt: completedAt,
            notes: notes.isEmpty ? nil : notes
        )
        onSave(g)
        dismiss()
    }
}

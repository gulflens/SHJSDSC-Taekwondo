import SwiftUI

public struct PhysicalMetricsCard: View {
    @Environment(AppSession.self) private var session
    @Binding var athlete: Athlete

    @State private var metrics: [PhysicalMetric] = []
    @State private var loading = true
    @State private var sheet: SheetTarget?

    public init(athlete: Binding<Athlete>) {
        self._athlete = athlete
    }

    /// Body weight is captured under `Athlete.weightHistory` (its own card +
    /// schema). The metrics card surfaces it for freshness tracking but routes
    /// reads + writes through the weight-history pipeline so there's a single
    /// source of truth.
    private enum SheetTarget: Identifiable {
        case metric(PhysicalMetricKind, PhysicalMetric?)
        case weight(WeightEntry?)

        var id: String {
            switch self {
            case .metric(let kind, let entry):
                return "metric.\(kind.rawValue).\(entry?.id.uuidString ?? "new")"
            case .weight(let entry):
                return "weight.\(entry?.id.uuidString ?? "new")"
            }
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("athlete.section.physical_metrics").scaledFont(.headline)
            if loading {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                ForEach(PhysicalCategory.allCases, id: \.self) { category in
                    categorySection(category)
                }
            }
        }
        .task { await load() }
        .sheet(item: $sheet) { target in
            NavigationStack {
                switch target {
                case .metric(let kind, let initial):
                    PhysicalMetricEntrySheet(
                        athleteID: athlete.id,
                        kind: kind,
                        initial: initial,
                        onSave: { m in Task { await save(m) } },
                        onDelete: initial.map { entry in
                            { Task { await delete(id: entry.id) } }
                        }
                    )
                case .weight(let initial):
                    WeightEditorSheet(
                        initial: initial,
                        onSave: { entry in Task { await saveWeight(entry) } },
                        onDelete: initial.map { entry in
                            { Task { await deleteWeight(id: entry.id) } }
                        }
                    )
                }
            }
        }
    }

    private static let tileColumns = [GridItem(.adaptive(minimum: 150), spacing: 8)]

    private func categorySection(_ category: PhysicalCategory) -> some View {
        let kinds = PhysicalMetricKind.allCases.filter { $0.category == category }
        let latest = metrics.latestPerKind()
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: category.systemIcon)
                    .scaledFont(.caption, weight: .bold)
                    .foregroundStyle(.tint)
                    .frame(width: 20, height: 20)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                Text(localizedKey: category.labelKey)
                    .scaledFont(.subheadline, weight: .bold)
                Spacer()
            }
            LazyVGrid(columns: Self.tileColumns, spacing: 6) {
                ForEach(kinds, id: \.self) { kind in
                    if kind == .bodyWeightKg {
                        weightTile()
                    } else if kind.isUnilateral {
                        let entries = latest.filter { $0.kind == kind }
                        ForEach(BodySide.allCases, id: \.self) { side in
                            metricTile(kind: kind, leg: side, entry: entries.first { $0.leg == side })
                        }
                    } else {
                        metricTile(kind: kind, leg: nil, entry: latest.first { $0.kind == kind })
                    }
                }
            }
        }
    }

    private func metricTile(kind: PhysicalMetricKind, leg: BodySide?, entry: PhysicalMetric?) -> some View {
        let state = freshness(date: entry?.recordedAt, frequency: kind.frequency)
        return Button {
            guard canEdit else { return }
            sheet = .metric(kind, entry)
        } label: {
            tileBody(
                titleKey: kind.labelKey,
                leg: leg,
                value: AnyView(valueLabel(kind: kind, entry: entry)),
                state: state
            )
        }
        .buttonStyle(.plain)
    }

    private func weightTile() -> some View {
        let latest = athlete.weightHistory.max(by: { $0.recordedAt < $1.recordedAt })
        let state = freshness(date: latest?.recordedAt, frequency: .weekly)
        return Button {
            guard canEdit else { return }
            sheet = .weight(latest)
        } label: {
            tileBody(
                titleKey: PhysicalMetricKind.bodyWeightKg.labelKey,
                leg: nil,
                value: AnyView(weightValueLabel(latest)),
                state: state
            )
        }
        .buttonStyle(.plain)
    }

    private func tileBody(
        titleKey: String,
        leg: BodySide?,
        value: AnyView,
        state: FreshnessState
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 3) {
                Text(localizedKey: titleKey)
                    .scaledFont(.caption2, weight: .semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if let leg {
                    Text(localizedKey: leg.labelKey)
                        .scaledFont(size: 9, weight: .bold)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.18), in: Capsule())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            value
            HStack(spacing: 3) {
                Circle().fill(state.color).frame(width: 6, height: 6)
                Text(localizedKey: state.labelKey)
                    .scaledFont(size: 10, weight: .semibold)
                    .foregroundStyle(state.color)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
        .padding(8)
        .background(state.color.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(state.color.opacity(0.35), lineWidth: 0.8)
        )
    }

    @ViewBuilder
    private func valueLabel(kind: PhysicalMetricKind, entry: PhysicalMetric?) -> some View {
        if let entry {
            if kind.isPassFail {
                Image(systemName: entry.value >= 0.5 ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(entry.value >= 0.5 ? Color.green : Color.red)
                    .scaledFont(.title3)
            } else {
                let formatted = format(value: entry.value, step: kind.inputRange.step)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(verbatim: formatted)
                        .scaledFont(.title3, weight: .bold, monospacedDigit: true)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if !kind.unit.isEmpty {
                        Text(verbatim: kind.unit)
                            .scaledFont(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
                .environment(\.layoutDirection, .leftToRight)
            }
        } else {
            Text(verbatim: "—")
                .scaledFont(.title3, monospacedDigit: true)
                .foregroundStyle(Color.secondary.opacity(0.5))
        }
    }

    @ViewBuilder
    private func weightValueLabel(_ entry: WeightEntry?) -> some View {
        if let entry {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(verbatim: String(format: "%.1f", entry.weightKg))
                    .scaledFont(.title3, weight: .bold, monospacedDigit: true)
                Text(verbatim: "kg")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .environment(\.layoutDirection, .leftToRight)
        } else {
            Text(verbatim: "—")
                .scaledFont(.title3, monospacedDigit: true)
                .foregroundStyle(Color.secondary.opacity(0.5))
        }
    }

    private enum FreshnessState {
        case missing, overdue, due, ok
        var labelKey: String {
            switch self {
            case .missing: "metric.status.missing"
            case .overdue: "metric.status.overdue"
            case .due: "metric.status.due"
            case .ok: "metric.status.ok"
            }
        }
        var color: Color {
            switch self {
            case .missing: .gray
            case .overdue: .red
            case .due: .orange
            case .ok: .green
            }
        }
    }

    private func freshness(date: Date?, frequency: TestFrequency) -> FreshnessState {
        guard let date else { return .missing }
        let age = Date().timeIntervalSince(date) / 86_400
        let interval = Double(frequency.dayInterval)
        let grace = Double(frequency.graceDays)
        if age > interval + grace { return .overdue }
        if age > interval { return .due }
        return .ok
    }

    private func format(value: Double, step: Double) -> String {
        if step >= 1 { return String(format: "%.0f", value) }
        if step >= 0.1 { return String(format: "%.1f", value) }
        return String(format: "%.2f", value)
    }

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editAthlete)
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            metrics = try await session.repository.physicalMetrics(athleteID: athlete.id)
        } catch {
            print("PhysicalMetricsCard.load:", error)
        }
    }

    private func save(_ metric: PhysicalMetric) async {
        do {
            try await session.repository.upsert(metric: metric)
            await load()
        } catch {
            print("PhysicalMetricsCard.save:", error)
        }
    }

    private func delete(id: EntityID) async {
        do {
            try await session.repository.deletePhysicalMetric(id: id)
            await load()
        } catch {
            print("PhysicalMetricsCard.delete:", error)
        }
    }

    private func saveWeight(_ entry: WeightEntry) async {
        if let idx = athlete.weightHistory.firstIndex(where: { $0.id == entry.id }) {
            athlete.weightHistory[idx] = entry
        } else {
            athlete.weightHistory.append(entry)
        }
        athlete.weightKg = athlete.weightHistory
            .max(by: { $0.recordedAt < $1.recordedAt })?.weightKg ?? athlete.weightKg
        do {
            try await session.repository.upsert(athlete)
        } catch {
            print("PhysicalMetricsCard.saveWeight:", error)
        }
    }

    private func deleteWeight(id: EntityID) async {
        athlete.weightHistory.removeAll { $0.id == id }
        athlete.weightKg = athlete.weightHistory
            .max(by: { $0.recordedAt < $1.recordedAt })?.weightKg ?? athlete.weightKg
        do {
            try await session.repository.upsert(athlete)
        } catch {
            print("PhysicalMetricsCard.deleteWeight:", error)
        }
    }
}

extension PhysicalMetricKind: Identifiable {
    public var id: String { rawValue }
}

// MARK: - Entry sheet

private struct PhysicalMetricEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var session

    let athleteID: EntityID
    let kind: PhysicalMetricKind
    let initial: PhysicalMetric?
    let onSave: (PhysicalMetric) -> Void
    let onDelete: (() -> Void)?

    @State private var recordedAt: Date
    @State private var value: Double
    @State private var passFail: Bool
    @State private var leg: BodySide
    @State private var notes: String

    init(
        athleteID: EntityID,
        kind: PhysicalMetricKind,
        initial: PhysicalMetric?,
        onSave: @escaping (PhysicalMetric) -> Void,
        onDelete: (() -> Void)?
    ) {
        self.athleteID = athleteID
        self.kind = kind
        self.initial = initial
        self.onSave = onSave
        self.onDelete = onDelete
        _recordedAt = State(initialValue: initial?.recordedAt ?? Date())
        let r = kind.inputRange
        _value = State(initialValue: initial?.value ?? (r.lower + (r.upper - r.lower) / 2))
        _passFail = State(initialValue: (initial?.value ?? 0) >= 0.5)
        _leg = State(initialValue: initial?.leg ?? .right)
        _notes = State(initialValue: initial?.notes ?? "")
    }

    var body: some View {
        Form {
            Section {
                DatePicker("athlete.weight_recorded_at", selection: $recordedAt, displayedComponents: .date)
                if kind.isUnilateral {
                    Picker("body_side", selection: $leg) {
                        ForEach(BodySide.allCases, id: \.self) { side in
                            Text(localizedKey: side.labelKey).tag(side)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section {
                if kind.isPassFail {
                    Toggle(isOn: $passFail) {
                        Label {
                            Text(localizedKey: kind.labelKey)
                        } icon: {
                            Image(systemName: passFail ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(passFail ? .green : .red)
                        }
                    }
                } else {
                    valueSlider
                }
            } header: {
                HStack {
                    Text(localizedKey: kind.labelKey)
                    Spacer()
                    Text(localizedKey: kind.frequency.labelKey)
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                if !kind.unit.isEmpty {
                    Text(verbatim: kind.unit).scaledFont(.caption2).foregroundStyle(.secondary)
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
        .navigationTitle(Text(localizedKey: kind.labelKey))
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

    private var valueSlider: some View {
        let r = kind.inputRange
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(verbatim: format(value, step: r.step))
                    .scaledFont(.title3, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(.tint)
                if !kind.unit.isEmpty {
                    Text(verbatim: kind.unit).scaledFont(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .environment(\.layoutDirection, .leftToRight)
            Slider(value: $value, in: r.lower...r.upper, step: r.step)
        }
    }

    private func format(_ v: Double, step: Double) -> String {
        if step >= 1 { return String(format: "%.0f", v) }
        if step >= 0.1 { return String(format: "%.1f", v) }
        return String(format: "%.2f", v)
    }

    private func commit() {
        guard let coachID = session.currentUser?.id else { return }
        let stored: Double = kind.isPassFail ? (passFail ? 1 : 0) : value
        let metric = PhysicalMetric(
            id: initial?.id ?? UUID(),
            athleteID: athleteID,
            recordedAt: recordedAt,
            recordedByCoachID: initial?.recordedByCoachID ?? coachID,
            kind: kind,
            value: stored,
            leg: kind.isUnilateral ? leg : nil,
            notes: notes.isEmpty ? nil : notes
        )
        onSave(metric)
        dismiss()
    }
}

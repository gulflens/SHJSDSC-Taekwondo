import SwiftUI
import Charts

public struct WeightHistoryCard: View {
    @Environment(AppSession.self) private var session
    @Binding var athlete: Athlete
    @State private var showingEditor = false
    @State private var editingEntry: WeightEntry?

    public init(athlete: Binding<Athlete>) {
        self._athlete = athlete
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if athlete.weightHistory.isEmpty {
                Text("athlete.no_weight_history_yet")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                chart
                latestRow
            }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                WeightEditorSheet(
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
            Text("athlete.section.weight_history").scaledFont(.headline)
            Spacer()
            if canEdit {
                Button {
                    editingEntry = nil
                    showingEditor = true
                } label: {
                    Label("athlete.add_weight", systemImage: "plus.circle.fill")
                        .scaledFont(.subheadline)
                        .labelStyle(.titleAndIcon)
                }
            }
        }
    }

    @ViewBuilder
    private var chart: some View {
        let sorted = athlete.weightHistory.sorted { $0.recordedAt < $1.recordedAt }
        let band = athlete.weightClass?.range
        let xDomain = (sorted.first?.recordedAt ?? Date())...(sorted.last?.recordedAt ?? Date())
        let yLow = (sorted.map(\.weightKg).min() ?? 0) - 2
        let yHigh = (sorted.map(\.weightKg).max() ?? 0) + 2
        let lo = min(yLow, band?.lower ?? yLow)
        let hi = max(yHigh, band?.upper ?? yHigh)

        Chart {
            if let band, let lower = band.lower, let upper = band.upper {
                RectangleMark(
                    xStart: .value("x.start", xDomain.lowerBound),
                    xEnd: .value("x.end", xDomain.upperBound),
                    yStart: .value("y.lower", lower),
                    yEnd: .value("y.upper", upper)
                )
                .foregroundStyle(Color.green.opacity(0.10))
            }
            ForEach(sorted) { entry in
                LineMark(
                    x: .value("x.date", entry.recordedAt),
                    y: .value("y.weight", entry.weightKg)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(Color.accentColor)
                PointMark(
                    x: .value("x.date", entry.recordedAt),
                    y: .value("y.weight", entry.weightKg)
                )
                .foregroundStyle(Color.accentColor)
                .symbolSize(40)
            }
        }
        .chartYScale(domain: lo...hi)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: 160)
        .environment(\.layoutDirection, .leftToRight)
    }

    private var latestRow: some View {
        let sorted = athlete.weightHistory.sorted { $0.recordedAt > $1.recordedAt }
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(sorted.prefix(5))) { entry in
                HStack {
                    Image(systemName: "scalemass.fill")
                        .scaledFont(.caption)
                        .foregroundStyle(.tint)
                    Text(verbatim: String(format: "%.1f kg", entry.weightKg))
                        .scaledFont(.callout, weight: .bold, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                    Spacer()
                    Text(entry.recordedAt, style: .date)
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                }
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

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editAthlete)
    }

    private func save(_ entry: WeightEntry) async {
        if let idx = athlete.weightHistory.firstIndex(where: { $0.id == entry.id }) {
            athlete.weightHistory[idx] = entry
        } else {
            athlete.weightHistory.append(entry)
        }
        athlete.weightKg = latestWeight() ?? athlete.weightKg
        do {
            try await session.repository.upsert(athlete)
        } catch {
            print("WeightHistoryCard.save:", error)
        }
    }

    private func delete(id: EntityID) async {
        athlete.weightHistory.removeAll { $0.id == id }
        athlete.weightKg = latestWeight() ?? athlete.weightKg
        do {
            try await session.repository.upsert(athlete)
        } catch {
            print("WeightHistoryCard.delete:", error)
        }
    }

    private func latestWeight() -> Double? {
        athlete.weightHistory.max(by: { $0.recordedAt < $1.recordedAt })?.weightKg
    }
}


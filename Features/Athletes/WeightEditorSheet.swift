import SwiftUI

struct WeightEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let initial: WeightEntry?
    let onSave: (WeightEntry) -> Void
    let onDelete: (() -> Void)?

    @State private var recordedAt: Date
    @State private var weightKg: Double

    init(initial: WeightEntry?, onSave: @escaping (WeightEntry) -> Void, onDelete: (() -> Void)?) {
        self.initial = initial
        self.onSave = onSave
        self.onDelete = onDelete
        _recordedAt = State(initialValue: initial?.recordedAt ?? Date())
        _weightKg = State(initialValue: initial?.weightKg ?? 50)
    }

    var body: some View {
        Form {
            Section {
                DatePicker("athlete.weight_recorded_at", selection: $recordedAt, displayedComponents: .date)
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: String(format: "%.1f kg", weightKg))
                        .scaledFont(.title3, weight: .bold, monospacedDigit: true)
                        .foregroundStyle(.tint)
                        .environment(\.layoutDirection, .leftToRight)
                    Slider(value: $weightKg, in: 15...140, step: 0.1)
                }
            } header: {
                Text("kpi.weight")
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
        .navigationTitle(initial == nil ? Text("athlete.add_weight") : Text("athlete.section.weight_history"))
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
                    let entry = WeightEntry(
                        id: initial?.id ?? UUID(),
                        recordedAt: recordedAt,
                        weightKg: weightKg
                    )
                    onSave(entry)
                    dismiss()
                }
                .bareToolbarButton()
            }
        }
    }
}

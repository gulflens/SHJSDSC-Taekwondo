import SwiftUI

public struct PomodoroEditorView: View {
    @Environment(\.dismiss) private var dismiss

    public let plan: TrainingPomodoro?
    public let onSaved: (TrainingPomodoro) -> Void

    @State private var name: String
    @State private var nameAr: String
    @State private var whistleSeconds: Double
    @State private var groups: [PomodoroGroup]

    public init(plan: TrainingPomodoro?, onSaved: @escaping (TrainingPomodoro) -> Void) {
        self.plan = plan
        self.onSaved = onSaved
        _name = State(initialValue: plan?.name ?? "")
        _nameAr = State(initialValue: plan?.nameAr ?? "")
        _whistleSeconds = State(initialValue: plan?.whistleSeconds ?? 2)
        _groups = State(initialValue: plan?.groups ?? [PomodoroEditorView.makeStarterGroup()])
    }

    public var body: some View {
        Form {
            Section(header: Text("pomodoro.name")) {
                TextField("pomodoro.name", text: $name)
                TextField("auth.full_name_ar", text: $nameAr)
                    .multilineTextAlignment(.trailing)
            }

            Section(header: Text("pomodoro.whistle"),
                    footer: Text("pomodoro.whistle.hint")) {
                HStack {
                    Slider(value: $whistleSeconds, in: 1...5, step: 0.5)
                    Text(verbatim: String(format: "%.1fs", whistleSeconds))
                        .scaledFont(.callout, monospacedDigit: true)
                        .frame(width: 50, alignment: .trailing)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }

            ForEach(groups.indices, id: \.self) { gi in
                Section(header: groupHeader(at: gi)) {
                    Stepper(value: Binding(
                        get: { groups[gi].repetitions },
                        set: { groups[gi].repetitions = max(1, $0) }
                    ), in: 1...20) {
                        HStack {
                            Text("pomodoro.repetitions")
                            Spacer()
                            Text(verbatim: "×\(groups[gi].repetitions)")
                                .scaledFont(.callout, monospacedDigit: true)
                                .environment(\.layoutDirection, .leftToRight)
                        }
                    }

                    ForEach(groups[gi].intervals.indices, id: \.self) { ii in
                        intervalRow(groupIdx: gi, intervalIdx: ii)
                    }
                    .onDelete { idx in
                        groups[gi].intervals.remove(atOffsets: idx)
                    }

                    HStack {
                        Button {
                            groups[gi].intervals.append(PomodoroInterval(kind: .work, durationSeconds: 30))
                        } label: { Label("pomodoro.add_work", systemImage: "plus.circle.fill") }
                        Spacer()
                        Button {
                            groups[gi].intervals.append(PomodoroInterval(kind: .rest, durationSeconds: 10))
                        } label: { Label("pomodoro.add_rest", systemImage: "plus.circle") }
                    }
                    .scaledFont(.caption, weight: .bold)
                }
            }

            Section {
                Button {
                    groups.append(PomodoroEditorView.makeStarterGroup())
                } label: {
                    Label("pomodoro.add_group", systemImage: "plus.rectangle.fill")
                }
                if groups.count > 1 {
                    Button(role: .destructive) {
                        groups.removeLast()
                    } label: {
                        Label("pomodoro.remove_last_group", systemImage: "minus.rectangle")
                    }
                }
            }
        }
        .navigationTitle(Text(plan == nil ? "pomodoro.new" : "pomodoro.edit"))
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
                    save()
                }
                .disabled(!isValid)
                .bareToolbarButton()
            }
        }
    }

    private func groupHeader(at i: Int) -> some View {
        HStack {
            Text(verbatim: "Group \(i + 1)")
            Spacer()
            Text(verbatim: formatGroupSummary(groups[i]))
                .scaledFont(.caption2).foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private func formatGroupSummary(_ g: PomodoroGroup) -> String {
        let work = g.intervals.filter { $0.kind == .work }.count
        let rest = g.intervals.filter { $0.kind == .rest }.count
        return "W:\(work) R:\(rest) · \(g.totalSeconds)s"
    }

    private func intervalRow(groupIdx gi: Int, intervalIdx ii: Int) -> some View {
        let interval = groups[gi].intervals[ii]
        let kind = interval.kind
        let step = kind == .work ? 10 : 5
        let minVal = kind == .work ? 30 : 5
        return HStack(spacing: 8) {
            Image(systemName: kind == .work ? "bolt.fill" : "pause.fill")
                .foregroundStyle(kind == .work ? .red : .blue)
                .frame(width: 22)
            Text(localizedKey: kind.labelKey)
                .scaledFont(.callout, weight: .bold)
                .frame(width: 56, alignment: .leading)
            Spacer()
            Stepper(value: Binding(
                get: { groups[gi].intervals[ii].durationSeconds },
                set: { groups[gi].intervals[ii].durationSeconds = PomodoroInterval.snap($0, kind: kind) }
            ), in: minVal...600, step: step) {
                Text(verbatim: "\(interval.durationSeconds)s")
                    .scaledFont(.callout, monospacedDigit: true)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && groups.contains { !$0.intervals.isEmpty }
    }

    private func save() {
        let saved = TrainingPomodoro(
            id: plan?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            nameAr: nameAr.trimmingCharacters(in: .whitespaces),
            groups: groups.filter { !$0.intervals.isEmpty },
            whistleSeconds: whistleSeconds,
            createdByCoachID: plan?.createdByCoachID,
            createdAt: plan?.createdAt ?? Date()
        )
        onSaved(saved)
        dismiss()
    }

    private static func makeStarterGroup() -> PomodoroGroup {
        PomodoroGroup(
            repetitions: 4,
            intervals: [
                PomodoroInterval(kind: .work, durationSeconds: 30),
                PomodoroInterval(kind: .rest, durationSeconds: 10)
            ]
        )
    }
}

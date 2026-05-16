import SwiftUI

public struct PomodoroLibraryView: View {
    @Environment(AppSession.self) private var session
    @State private var plans: [TrainingPomodoro] = []
    @State private var showingEditor = false
    @State private var editing: TrainingPomodoro?
    @State private var running: TrainingPomodoro?

    public init() {}

    public var body: some View {
        Group {
            if plans.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(plans) { plan in
                        Button {
                            running = plan
                        } label: {
                            row(plan: plan)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await delete(plan) }
                            } label: { Label("action.delete", systemImage: "trash") }
                            Button {
                                editing = plan
                            } label: { Label("action.edit", systemImage: "pencil") }
                            .tint(.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle(Text("pomodoro.title"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditor = true
                } label: { Image(systemName: "plus") }
                    .accessibilityLabel(Text("pomodoro.new"))
                .bareToolbarButton()
            }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                PomodoroEditorView(plan: nil) { saved in
                    Task {
                        await PomodoroLibrary.shared.save(saved)
                        await reload()
                    }
                }
            }
        }
        .sheet(item: $editing) { plan in
            NavigationStack {
                PomodoroEditorView(plan: plan) { saved in
                    Task {
                        await PomodoroLibrary.shared.save(saved)
                        await reload()
                    }
                }
            }
        }
        #if os(iOS)
        .fullScreenCover(item: $running) { plan in
            PomodoroRunView(plan: plan)
        }
        #else
        .sheet(item: $running) { plan in
            PomodoroRunView(plan: plan)
        }
        #endif
        .task { await reload() }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "timer").scaledFont(.largeTitle).foregroundStyle(.secondary)
            Text("pomodoro.empty.title").scaledFont(.headline)
            Text("pomodoro.empty.body").scaledFont(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button {
                showingEditor = true
            } label: {
                Label("pomodoro.new", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 6)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    private func row(plan: TrainingPomodoro) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: plan.name).scaledFont(.headline)
            HStack(spacing: 8) {
                Label(verbatim: "\(plan.groups.count) groups", icon: "rectangle.stack.fill")
                    .scaledFont(.caption2).foregroundStyle(.secondary)
                Label(verbatim: formatDuration(plan.totalSeconds), icon: "clock.fill")
                    .scaledFont(.caption2).foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
                Label(verbatim: String(format: "%.0fs whistle", plan.whistleSeconds), icon: "wind")
                    .scaledFont(.caption2).foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ secs: Int) -> String {
        let m = secs / 60
        let s = secs % 60
        return m == 0 ? "\(s)s" : "\(m)m \(s)s"
    }

    private func reload() async {
        plans = await PomodoroLibrary.shared.all().sorted { $0.createdAt > $1.createdAt }
    }

    private func delete(_ plan: TrainingPomodoro) async {
        await PomodoroLibrary.shared.delete(id: plan.id)
        await reload()
    }
}

private extension Label where Title == Text, Icon == Image {
    init(verbatim: String, icon: String) {
        self.init {
            Text(verbatim: verbatim)
        } icon: {
            Image(systemName: icon)
        }
    }
}

import SwiftUI

/// Coach's on-mat unified screen for a single class. Three phases:
/// Roll Call (tap-to-cycle attendance), Drills (embedded pomodoro timer),
/// Wrap-up (per-athlete 1...5 engagement rating + save). Launched as a
/// full-screen cover from a class row on the coach home dashboard.
public struct LiveClassView: View {
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    public let session: ClassSession

    @State private var store: LiveClassStore?
    @State private var phase: LiveClassPhase = .rollCall
    @State private var plans: [TrainingPomodoro] = []
    @State private var selectedPlan: TrainingPomodoro?
    @State private var engine = PomodoroEngine()
    @State private var audio = PomodoroAudioService()
    @State private var showExitConfirm = false

    public init(session: ClassSession) {
        self.session = session
    }

    public var body: some View {
        Group {
            if let store {
                content(store: store)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground.ignoresSafeArea())
            }
        }
        .task {
            if store == nil {
                store = LiveClassStore(session: session, repository: appSession.repository)
            }
            await store?.load()
            plans = await PomodoroLibrary.shared.all().sorted { $0.createdAt > $1.createdAt }
        }
        .onDisappear {
            engine.stop()
            audio.stopAll()
        }
        .confirmationDialog(
            Text("live_class.exit.title"),
            isPresented: $showExitConfirm,
            titleVisibility: .visible
        ) {
            Button("live_class.exit.discard", role: .destructive) { dismiss() }
            Button("live_class.exit.save_and_exit") {
                Task {
                    await store?.save()
                    dismiss()
                }
            }
            Button("action.cancel", role: .cancel) { }
        }
    }

    private var isWide: Bool { sizeClass == .regular }

    @ViewBuilder
    private func content(store: LiveClassStore) -> some View {
        VStack(spacing: 0) {
            header(store: store)
            Divider().opacity(0.25)
            ScrollView {
                VStack(spacing: 16) {
                    switch phase {
                    case .rollCall:
                        RollCallSection(store: store, isWide: isWide)
                    case .drills:
                        DrillsSection(
                            plans: plans,
                            selectedPlan: $selectedPlan,
                            engine: engine,
                            audio: audio
                        )
                    case .wrapUp:
                        WrapUpSection(store: store)
                    }
                }
                .padding(.horizontal, isWide ? 20 : 14)
                .padding(.top, 14)
                .padding(.bottom, 120)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            phaseBar(store: store)
        }
    }

    // MARK: - Header

    private func header(store: LiveClassStore) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: session.title)
                    .scaledFont(.title3, weight: .bold)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(localizedKey: session.discipline.labelKey)
                    Text(verbatim: "·")
                    Text(localizedKey: session.ageGroup.labelKey)
                    Text(verbatim: "·")
                    Text(session.startsAt, style: .time)
                        .environment(\.layoutDirection, .leftToRight)
                    Text(verbatim: "→")
                    Text(session.endsAt, style: .time)
                        .environment(\.layoutDirection, .leftToRight)
                }
                .scaledFont(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button {
                if store.saved {
                    dismiss()
                } else {
                    showExitConfirm = true
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .scaledFont(.title2)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel(Text("action.close"))
            .buttonStyle(.plain)
        }
        .padding(.horizontal, isWide ? 20 : 14)
        .padding(.vertical, 12)
        .background(.thinMaterial)
    }

    // MARK: - Phase bar

    private func phaseBar(store: LiveClassStore) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(LiveClassPhase.allCases) { p in
                    phaseChip(p, store: store)
                }
            }
            primaryAction(store: store)
        }
        .padding(.horizontal, isWide ? 20 : 14)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(.thinMaterial)
        .overlay(alignment: .top) {
            Divider().opacity(0.25)
        }
    }

    private func phaseChip(_ p: LiveClassPhase, store: LiveClassStore) -> some View {
        let isCurrent = p == phase
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { phase = p }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: p.icon)
                    .scaledFont(.caption, weight: .semibold)
                Text(localizedKey: p.titleKey)
                    .scaledFont(.caption, weight: .semibold)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                isCurrent ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.10),
                in: Capsule()
            )
            .foregroundStyle(isCurrent ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func primaryAction(store: LiveClassStore) -> some View {
        switch phase {
        case .rollCall:
            advanceButton(labelKey: "live_class.action.next_drills") {
                withAnimation(.easeInOut(duration: 0.2)) { phase = .drills }
            }
        case .drills:
            advanceButton(labelKey: "live_class.action.next_wrap_up") {
                engine.stop()
                audio.stopAll()
                withAnimation(.easeInOut(duration: 0.2)) { phase = .wrapUp }
            }
        case .wrapUp:
            Button {
                Task {
                    await store.save()
                    if store.saved { dismiss() }
                }
            } label: {
                HStack(spacing: 8) {
                    if store.isSaving {
                        ProgressView().tint(.white)
                    } else if store.saved {
                        Image(systemName: "checkmark.circle.fill")
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                    }
                    Text(store.saved ? "action.saved" : "live_class.action.finish")
                        .scaledFont(.subheadline, weight: .semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    (store.saved ? Color.green : Color.accentColor),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(store.isSaving)
        }
    }

    private func advanceButton(labelKey: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(labelKey)
                    .scaledFont(.subheadline, weight: .semibold)
                Image(systemName: "arrow.right")
                    .scaledFont(.caption, weight: .bold)
                    .flipsForRightToLeftLayoutDirection(true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Phase enum

private enum LiveClassPhase: Int, CaseIterable, Identifiable, Hashable {
    case rollCall, drills, wrapUp

    var id: Int { rawValue }

    var titleKey: String {
        switch self {
        case .rollCall: "live_class.phase.roll_call"
        case .drills:   "live_class.phase.drills"
        case .wrapUp:   "live_class.phase.wrap_up"
        }
    }

    var icon: String {
        switch self {
        case .rollCall: "checklist"
        case .drills:   "timer"
        case .wrapUp:   "star.fill"
        }
    }
}

// MARK: - Roll Call

private struct RollCallSection: View {
    let store: LiveClassStore
    let isWide: Bool

    var body: some View {
        VStack(spacing: 14) {
            summaryStrip
            SectionCard("live_class.roll_call.title", icon: "checklist") {
                if store.athletes.isEmpty {
                    EmptyStateCard(
                        icon: "person.3",
                        titleKey: "empty.no_athletes_flagged",
                        messageKey: "live_class.roll_call.empty.message"
                    )
                } else {
                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible(), spacing: 10),
                            count: isWide ? 3 : 2
                        ),
                        spacing: 10
                    ) {
                        ForEach(store.athletes) { a in
                            athleteTile(a)
                        }
                    }
                }
            }
            if !store.athletes.isEmpty {
                Button {
                    store.markAllPresent()
                } label: {
                    Label("live_class.roll_call.mark_all_present", systemImage: "checkmark.circle")
                        .scaledFont(.subheadline, weight: .semibold)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var summaryStrip: some View {
        let total = store.athletes.count
        let present = store.presentCount
        let absent = store.absentCount
        return HStack(spacing: 10) {
            summaryTile(
                icon: "person.fill.checkmark",
                titleKey: "live_class.roll_call.present",
                value: "\(present)/\(total)",
                tint: .green
            )
            summaryTile(
                icon: "person.fill.xmark",
                titleKey: "live_class.roll_call.absent",
                value: "\(absent)",
                tint: .red
            )
        }
    }

    private func summaryTile(
        icon: String,
        titleKey: LocalizedStringKey,
        value: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .scaledFont(.title3, weight: .semibold)
                .foregroundStyle(tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(titleKey)
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: value)
                    .scaledFont(.title3, weight: .bold, monospacedDigit: true)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private func athleteTile(_ athlete: Athlete) -> some View {
        let state = store.marks[athlete.id] ?? .present
        return Button {
            store.cycleState(for: athlete.id)
        } label: {
            VStack(spacing: 8) {
                Avatar(seed: athlete.avatarSeed, label: athlete.initials, size: 44, urlString: athlete.avatarURL)
                Text(verbatim: athlete.fullName)
                    .scaledFont(.caption, weight: .semibold)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                AttendanceStatePill(state: state)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                Color.cardBackground,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(stateColor(state).opacity(0.5), lineWidth: 1.5)
            }
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func stateColor(_ s: AttendanceState) -> Color {
        switch s {
        case .present: .green
        case .late: .orange
        case .absent: .red
        case .excused: .gray
        }
    }
}

private struct AttendanceStatePill: View {
    let state: AttendanceState

    var body: some View {
        Text(localizedKey: state.labelKey)
            .scaledFont(.caption2, weight: .semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch state {
        case .present: .green
        case .late: .orange
        case .absent: .red
        case .excused: .gray
        }
    }
}

// MARK: - Drills

private struct DrillsSection: View {
    let plans: [TrainingPomodoro]
    @Binding var selectedPlan: TrainingPomodoro?
    let engine: PomodoroEngine
    let audio: PomodoroAudioService

    var body: some View {
        VStack(spacing: 14) {
            if let plan = selectedPlan {
                LiveTimerPanel(
                    plan: plan,
                    engine: engine,
                    audio: audio,
                    onChangePlan: {
                        engine.stop()
                        audio.stopAll()
                        selectedPlan = nil
                    }
                )
            } else {
                planPicker
            }
        }
    }

    private var planPicker: some View {
        SectionCard("live_class.drills.pick_plan", icon: "timer") {
            if plans.isEmpty {
                EmptyStateCard(
                    icon: "timer",
                    titleKey: "pomodoro.empty.title",
                    messageKey: "live_class.drills.empty.message"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(plans) { plan in
                        Button {
                            selectedPlan = plan
                        } label: {
                            planRow(plan)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func planRow(_ plan: TrainingPomodoro) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.14))
                Image(systemName: "timer")
                    .scaledFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.tint)
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: plan.name)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                Text(verbatim: formatDuration(plan.totalSeconds))
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Spacer(minLength: 0)
            Image(systemName: "play.fill")
                .scaledFont(.subheadline, weight: .bold)
                .foregroundStyle(.tint)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func formatDuration(_ secs: Int) -> String {
        let m = secs / 60
        let s = secs % 60
        return m == 0 ? "\(s)s" : "\(m)m \(s)s"
    }
}

private struct LiveTimerPanel: View {
    let plan: TrainingPomodoro
    let engine: PomodoroEngine
    let audio: PomodoroAudioService
    let onChangePlan: () -> Void

    @State private var didStart = false

    var body: some View {
        let snap = engine.snapshot
        return VStack(spacing: 16) {
            timerCard(snap: snap)
            controlRow(snap: snap)
            Button {
                engine.stop()
                audio.stopAll()
                onChangePlan()
            } label: {
                Label("live_class.drills.change_plan", systemImage: "arrow.left.arrow.right")
                    .scaledFont(.caption, weight: .semibold)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.10), in: Capsule())
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            if !didStart {
                engine.load(plan)
                engine.onPhaseChange = { phase in handlePhase(phase) }
                engine.start()
                didStart = true
            }
        }
        .onDisappear {
            audio.stopAll()
        }
    }

    private func timerCard(snap: PomodoroSnapshot) -> some View {
        let seconds = Int(snap.phaseSecondsRemaining.rounded(.up))
        return VStack(spacing: 10) {
            phaseBadge(snap.phase)
            Text(verbatim: "\(seconds)")
                .scaledFont(size: 120, weight: .heavy, design: .rounded, monospacedDigit: true)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(.white)
                .environment(\.layoutDirection, .leftToRight)
            Text(verbatim: plan.name)
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
            Text(verbatim: "\(String(localized: "pomodoro.session")) \(snap.groupIndex + 1)/\(plan.groups.count)")
                .scaledFont(.caption)
                .foregroundStyle(.white.opacity(0.75))
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(phaseGradient(snap.phase), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }

    private func phaseBadge(_ phase: PomodoroPhase) -> some View {
        let label: String = switch phase {
        case .work:     String(localized: "pomodoro.work")
        case .rest:     String(localized: "pomodoro.rest")
        case .whistle:  String(localized: "pomodoro.transition")
        case .finished: String(localized: "pomodoro.finished")
        case .idle:     String(localized: "pomodoro.idle")
        }
        return Text(verbatim: label.uppercased())
            .scaledFont(.caption2, weight: .bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.20), in: Capsule())
            .foregroundStyle(.white)
    }

    private func controlRow(snap: PomodoroSnapshot) -> some View {
        HStack(spacing: 14) {
            controlButton(icon: "backward.end.fill") {
                engine.skipToPreviousGroup()
            }
            .disabled(snap.groupIndex == 0)
            .opacity(snap.groupIndex == 0 ? 0.4 : 1)

            Button {
                engine.togglePause()
                if !engine.isRunning {
                    audio.stopAll()
                } else {
                    handlePhase(engine.snapshot.phase)
                }
            } label: {
                Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                    .scaledFont(.title2, weight: .bold)
                    .frame(width: 64, height: 64)
                    .background(Color.accentColor, in: Circle())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            controlButton(icon: "forward.end.fill") {
                engine.skipToNextGroup()
            }
            .disabled(snap.groupIndex >= plan.groups.count - 1)
            .opacity(snap.groupIndex >= plan.groups.count - 1 ? 0.4 : 1)
        }
    }

    private func controlButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .scaledFont(.title3, weight: .semibold)
                .frame(width: 48, height: 48)
                .background(Color.secondary.opacity(0.15), in: Circle())
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    private func phaseGradient(_ phase: PomodoroPhase) -> LinearGradient {
        switch phase {
        case .work:
            LinearGradient(colors: [Color.red, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .rest:
            LinearGradient(colors: [Color.blue, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .whistle:
            LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .finished:
            LinearGradient(colors: [Color.green, Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .idle:
            LinearGradient(colors: [Color.gray, Color.gray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func handlePhase(_ phase: PomodoroPhase) {
        switch phase {
        case .work:     audio.playWork()
        case .rest:     audio.playRest()
        case .whistle:  audio.playWhistle(seconds: plan.whistleSeconds)
        case .idle, .finished: audio.stopAll()
        }
    }
}

// MARK: - Wrap-up

private struct WrapUpSection: View {
    let store: LiveClassStore

    var body: some View {
        VStack(spacing: 14) {
            SectionCard("live_class.wrap_up.title", icon: "star.fill") {
                if store.athletes.isEmpty {
                    EmptyStateCard(
                        icon: "person.3",
                        titleKey: "empty.no_athletes_flagged",
                        messageKey: "live_class.wrap_up.empty.message"
                    )
                } else {
                    VStack(spacing: 10) {
                        Text("live_class.wrap_up.help")
                            .scaledFont(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(store.athletes) { a in
                            ratingRow(a)
                            if a.id != store.athletes.last?.id {
                                Divider().opacity(0.25)
                            }
                        }
                    }
                }
            }
        }
    }

    private func ratingRow(_ athlete: Athlete) -> some View {
        let rating = store.ratings[athlete.id] ?? 0
        let state = store.marks[athlete.id] ?? .present
        let disabled = (state == .absent || state == .excused)
        return HStack(spacing: 12) {
            Avatar(
                seed: athlete.avatarSeed,
                label: athlete.initials,
                size: 36,
                urlString: athlete.avatarURL
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: athlete.fullName)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                AttendanceStatePill(state: state)
            }
            Spacer(minLength: 0)
            ratingControls(athleteID: athlete.id, rating: rating, disabled: disabled)
        }
        .padding(.vertical, 6)
        .opacity(disabled ? 0.45 : 1)
    }

    private func ratingControls(athleteID: EntityID, rating: Int, disabled: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    guard !disabled else { return }
                    store.setRating(value, for: athleteID)
                } label: {
                    Image(systemName: value <= rating ? "star.fill" : "star")
                        .scaledFont(.subheadline, weight: .semibold)
                        .foregroundStyle(value <= rating ? Color.orange : Color.secondary.opacity(0.5))
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(disabled)
            }
        }
    }
}

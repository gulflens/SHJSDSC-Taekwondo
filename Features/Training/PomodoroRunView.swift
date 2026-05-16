import SwiftUI

public struct PomodoroRunView: View {
    @Environment(\.dismiss) private var dismiss

    public let plan: TrainingPomodoro

    @State private var engine = PomodoroEngine()
    @State private var audio = PomodoroAudioService()

    public init(plan: TrainingPomodoro) {
        self.plan = plan
    }

    private func sessionIntervals(groupIndex: Int) -> [SessionInterval] {
        guard groupIndex < plan.groups.count else { return [] }
        let group = plan.groups[groupIndex]
        var result: [SessionInterval] = []
        var seq = 1
        for round in 0..<group.repetitions {
            for (ii, interval) in group.intervals.enumerated() {
                result.append(SessionInterval(
                    seq: seq,
                    roundIndex: round,
                    intervalIndex: ii,
                    kind: interval.kind,
                    durationSeconds: interval.durationSeconds
                ))
                seq += 1
            }
        }
        return result
    }

    private func currentIntervalSeq(in intervals: [SessionInterval], snap: PomodoroSnapshot) -> Int {
        intervals.first(where: {
            $0.roundIndex == snap.roundIndex && $0.intervalIndex == snap.intervalIndex
        })?.seq ?? 0
    }

    private var sessionName: String {
        let snap = engine.snapshot
        guard snap.groupIndex < plan.groups.count else { return plan.name }
        let group = plan.groups[snap.groupIndex]
        return group.name ?? String(localized: "pomodoro.session_n \(snap.groupIndex + 1)")
    }

    public var body: some View {
        let snap = engine.snapshot
        let intervals = sessionIntervals(groupIndex: snap.groupIndex)
        let currentSeq = currentIntervalSeq(in: intervals, snap: snap)

        ZStack {
            phaseColor(snap.phase).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar(snap: snap)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                progressBar(snap: snap)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                countdownNumber(snap: snap)
                    .padding(.top, 4)

                phaseBadge(snap: snap)
                    .padding(.top, 4)

                sessionHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                intervalList(intervals: intervals, currentSeq: currentSeq)
                    .padding(.top, 8)

                Spacer(minLength: 8)

                bottomNav(snap: snap)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
            .foregroundStyle(.white)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            engine.load(plan)
            engine.onPhaseChange = { phase in
                handlePhaseChange(phase)
            }
            engine.start()
        }
        .onDisappear {
            engine.stop()
            audio.stopAll()
        }
        #if os(iOS)
        .statusBarHidden()
        #endif
    }

    // MARK: - Top bar

    private func topBar(snap: PomodoroSnapshot) -> some View {
        HStack {
            Button {
                engine.stop()
                audio.stopAll()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .scaledFont(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Text(verbatim: elapsedString(snap.elapsedTotalSeconds))
                .scaledFont(.subheadline, weight: .bold, monospacedDigit: true)
                .foregroundStyle(.white.opacity(0.85))
                .environment(\.layoutDirection, .leftToRight)

            Spacer()

            Button {
                engine.togglePause()
                if !engine.isRunning { audio.stopAll() }
                else { handlePhaseChange(engine.snapshot.phase) }
            } label: {
                Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                    .scaledFont(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Progress bar

    private func progressBar(snap: PomodoroSnapshot) -> some View {
        let progress = snap.phaseTotalSeconds > 0
            ? max(0, min(1, 1.0 - snap.phaseSecondsRemaining / snap.phaseTotalSeconds))
            : 0
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.6))
                    .frame(width: geo.size.width * progress)
                    .animation(.linear(duration: 0.1), value: progress)
            }
        }
        .frame(height: 6)
    }

    // MARK: - Countdown

    private func countdownNumber(snap: PomodoroSnapshot) -> some View {
        let seconds = Int(snap.phaseSecondsRemaining.rounded(.up))
        return Text(verbatim: "\(seconds)")
            .scaledFont(size: 320, weight: .heavy, design: .rounded, monospacedDigit: true)
            .minimumScaleFactor(0.3)
            .lineLimit(1)
            .environment(\.layoutDirection, .leftToRight)
    }

    private func phaseBadge(snap: PomodoroSnapshot) -> some View {
        let label: String = switch snap.phase {
        case .work: String(localized: "pomodoro.work")
        case .rest: String(localized: "pomodoro.rest")
        case .whistle: String(localized: "pomodoro.transition")
        case .finished: String(localized: "pomodoro.finished")
        case .idle: String(localized: "pomodoro.idle")
        }
        return Text(verbatim: label.uppercased())
            .scaledFont(.caption, weight: .bold)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.15), in: Capsule())
    }

    // MARK: - Session header

    private var sessionHeader: some View {
        VStack(spacing: 4) {
            Text(verbatim: sessionName)
                .scaledFont(.title2, weight: .bold)
            Text(verbatim: "\(String(localized: "pomodoro.session")) \(engine.snapshot.groupIndex + 1) / \(plan.groups.count)")
                .scaledFont(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Interval list

    private func intervalList(intervals: [SessionInterval], currentSeq: Int) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(intervals, id: \.seq) { item in
                        intervalRow(item: item, isCurrent: item.seq == currentSeq, isPast: item.seq < currentSeq)
                            .id(item.seq)
                    }
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: currentSeq) { _, newSeq in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newSeq, anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(currentSeq, anchor: .center)
            }
        }
    }

    private func intervalRow(item: SessionInterval, isCurrent: Bool, isPast: Bool) -> some View {
        let kindLabel = item.kind == .work
            ? String(localized: "pomodoro.work")
            : String(localized: "pomodoro.rest")
        let icon = item.kind == .work ? "figure.taekwondo" : "pause.circle.fill"
        return HStack(spacing: 10) {
            Image(systemName: icon)
                .scaledFont(.title3)
                .frame(width: 28)
            Text(verbatim: "\(item.seq). \(kindLabel): \(item.durationSeconds)")
                .scaledFont(.title3, weight: .bold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            isCurrent
                ? Color.white.opacity(0.25)
                : (isPast ? Color.white.opacity(0.05) : Color.white.opacity(0.1)),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .opacity(isPast ? 0.5 : 1.0)
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: - Bottom nav (session jumper)

    private func bottomNav(snap: PomodoroSnapshot) -> some View {
        HStack(spacing: 24) {
            Button {
                engine.skipToPreviousGroup()
            } label: {
                Image(systemName: "backward.end.fill")
                    .scaledFont(.title2)
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(snap.groupIndex == 0)
            .opacity(snap.groupIndex == 0 ? 0.4 : 1)

            Text(verbatim: "\(snap.groupIndex + 1)/\(plan.groups.count)")
                .scaledFont(.title2, weight: .bold, monospacedDigit: true)
                .environment(\.layoutDirection, .leftToRight)

            Button {
                engine.skipToNextGroup()
            } label: {
                Image(systemName: "forward.end.fill")
                    .scaledFont(.title2)
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(snap.groupIndex >= plan.groups.count - 1)
            .opacity(snap.groupIndex >= plan.groups.count - 1 ? 0.4 : 1)
        }
    }

    // MARK: - Helpers

    private func phaseColor(_ phase: PomodoroPhase) -> some View {
        switch phase {
        case .work:
            AnyView(Color.red)
        case .rest:
            AnyView(LinearGradient(colors: [.blue, .indigo.opacity(0.8)], startPoint: .top, endPoint: .bottom))
        case .whistle:
            AnyView(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
        case .finished:
            AnyView(LinearGradient(colors: [.green, .teal], startPoint: .top, endPoint: .bottom))
        case .idle:
            AnyView(Color.black)
        }
    }

    private func elapsedString(_ seconds: Double) -> String {
        let total = Int(seconds.rounded(.up))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func handlePhaseChange(_ phase: PomodoroPhase) {
        switch phase {
        case .work: audio.playWork()
        case .rest: audio.playRest()
        case .whistle: audio.playWhistle(seconds: plan.whistleSeconds)
        case .idle, .finished: audio.stopAll()
        }
    }
}

private struct SessionInterval: Hashable {
    let seq: Int
    let roundIndex: Int
    let intervalIndex: Int
    let kind: WorkRest
    let durationSeconds: Int
}

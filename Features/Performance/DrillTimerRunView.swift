import SwiftUI

// MARK: - Drill Timer run view
//
// Stage 1.8 — the full-screen operational timer. A bold phase-tinted canvas,
// a giant countdown ring legible from across the dojang, round / group /
// drill context, a next-up preview, and large transport controls.

public struct DrillTimerRunView: View {
    private let session: DrillTimerSession

    @Environment(\.dismiss) private var dismiss
    @State private var engine = DrillTimerEngine()
    @State private var audio = DrillTimerAudio()
    @State private var soundOn = true

    public init(session: DrillTimerSession) {
        self.session = session
    }

    private var phase: DrillTimerPhase { engine.phase }

    public var body: some View {
        ZStack {
            background
            if engine.isFinished {
                finishedCard
            } else {
                runningContent
            }
        }
        .animation(.easeInOut(duration: 0.35), value: phase)
        .onAppear(perform: startup)
        .onDisappear(perform: teardown)
        #if os(iOS)
        .statusBarHidden(true)
        #endif
    }

    // MARK: Background

    private var background: some View {
        LinearGradient(
            colors: [phase.tint.opacity(0.92), phase.tint.opacity(0.62)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay(
            RadialGradient(colors: [.white.opacity(0.18), .clear],
                           center: .top, startRadius: 10, endRadius: 520)
        )
        .ignoresSafeArea()
    }

    // MARK: Running content

    private var runningContent: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 8)
            ring
            Spacer(minLength: 8)
            nextUpRow
            controls
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            circleButton("xmark") { dismiss() }
            Spacer(minLength: 8)
            VStack(spacing: 2) {
                Text(verbatim: engine.sessionName)
                    .scaledFont(.subheadline, weight: .bold)
                    .foregroundStyle(.white)
                Text(verbatim: roundLabel)
                    .scaledFont(.caption2, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.8))
                    .environment(\.layoutDirection, .leftToRight)
            }
            Spacer(minLength: 8)
            circleButton(soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill") {
                soundOn.toggle()
                audio.setEnabled(soundOn)
            }
        }
    }

    private var ring: some View {
        CountdownRing(progress: 1 - engine.stepProgress,
                      tint: .white,
                      lineWidth: 16) {
            VStack(spacing: 6) {
                Label {
                    Text(localizedKey: phase.labelKey)
                } icon: {
                    Image(systemName: phase.systemIcon)
                }
                .scaledFont(.headline, weight: .bold)
                .foregroundStyle(.white)

                Text(verbatim: formatTimerClock(Int(ceil(engine.remaining))))
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .environment(\.layoutDirection, .leftToRight)
                    .contentTransition(.numericText())

                if let label = currentLabel {
                    Text(verbatim: label)
                        .scaledFont(.subheadline, weight: .semibold)
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 12)
                }
                metaChips
            }
        }
        .frame(maxWidth: 360)
        .frame(width: ringSize, height: ringSize)
    }

    private var metaChips: some View {
        HStack(spacing: 6) {
            if engine.totalWorkSteps > 0, phase == .work {
                pill(text: String(format: NSLocalizedString("timer.work_step.fmt", comment: ""),
                                   engine.workStepNumber, engine.totalWorkSteps))
            }
            if let group = engine.current?.groupName {
                pill(text: group, icon: "person.2.fill")
            }
        }
        .padding(.top, 2)
    }

    private var nextUpRow: some View {
        Group {
            if let next = engine.next {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.turn.down.right")
                        .scaledFont(.caption2, weight: .bold)
                    Text("timer.next").scaledFont(.caption, weight: .semibold)
                    Text(verbatim: stepDescription(next))
                        .scaledFont(.caption, weight: .semibold)
                    Text(verbatim: formatTimerClock(next.seconds))
                        .scaledFont(.caption, weight: .bold, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(.white.opacity(0.14), in: Capsule())
            } else {
                Text("timer.last_interval")
                    .scaledFont(.caption, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.vertical, 8)
            }
        }
        .padding(.bottom, 14)
    }

    private var controls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 22) {
                TimerControlButton(systemIcon: "backward.fill", size: 56) {
                    engine.skipBackward()
                }
                TimerControlButton(
                    systemIcon: engine.isRunning ? "pause.fill" : "play.fill",
                    prominent: true, tint: phase.tint, size: 84
                ) {
                    engine.togglePause()
                }
                TimerControlButton(systemIcon: "forward.fill", size: 56) {
                    engine.skipForward()
                }
            }
            HStack(spacing: 10) {
                secondaryButton("plus", "timer.add_10") { engine.addTime(10) }
                secondaryButton("arrow.counterclockwise", "timer.restart") {
                    engine.start()
                }
            }
        }
    }

    // MARK: Finished

    private var finishedCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.white)
            Text("timer.complete.title")
                .scaledFont(.title2, weight: .bold)
                .foregroundStyle(.white)
            Text(verbatim: String(format: NSLocalizedString("timer.complete.summary", comment: ""),
                                   engine.totalWorkSteps, formatTimerClock(engine.totalDuration)))
                .scaledFont(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                Button { engine.start() } label: {
                    Label("timer.restart", systemImage: "arrow.counterclockwise")
                        .scaledFont(.subheadline, weight: .semibold)
                        .padding(.horizontal, 18).padding(.vertical, 11)
                        .foregroundStyle(phase.tint)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
                Button { dismiss() } label: {
                    Text("action.done")
                        .scaledFont(.subheadline, weight: .semibold)
                        .padding(.horizontal, 18).padding(.vertical, 11)
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.18), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
        .padding(32)
    }

    // MARK: Pieces

    private func circleButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .scaledFont(.subheadline, weight: .bold)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.16), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(_ icon: String, _ titleKey: String,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).scaledFont(.caption, weight: .bold)
                Text(localizedKey: titleKey).scaledFont(.caption, weight: .semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(.white.opacity(0.16), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func pill(text: String, icon: String? = nil) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).scaledFont(.caption2, weight: .bold)
            }
            Text(verbatim: text).scaledFont(.caption2, weight: .bold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(.white.opacity(0.2), in: Capsule())
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: Derived

    private var ringSize: CGFloat {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? 360 : 300
        #else
        return 360
        #endif
    }

    private var roundLabel: String {
        let r = engine.current?.roundIndex ?? 1
        return String(format: NSLocalizedString("timer.round.fmt", comment: ""),
                      r, engine.totalRounds)
    }

    private var currentLabel: String? {
        guard let step = engine.current else { return nil }
        if let label = step.label, !label.isEmpty { return label }
        return nil
    }

    private func stepDescription(_ step: DrillTimerEngine.Step) -> String {
        if let label = step.label, !label.isEmpty { return label }
        return NSLocalizedString(step.phase.labelKey, comment: "")
    }

    // MARK: Lifecycle

    private func startup() {
        engine.load(session)
        engine.onEnterStep = { step in
            audio.cue(for: step.phase)
        }
        engine.onTick = { secs in
            if secs >= 1, secs <= 3 { audio.countdownTick() }
        }
        engine.onFinish = {
            audio.cue(for: .finished)
        }
        audio.setEnabled(soundOn)
        engine.start()
        keepAwake(true)
    }

    private func teardown() {
        engine.reset()
        keepAwake(false)
    }

    private func keepAwake(_ on: Bool) {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = on
        #endif
    }
}

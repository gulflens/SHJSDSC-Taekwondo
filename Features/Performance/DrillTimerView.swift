import SwiftUI

// MARK: - Drill Timer setup
//
// Stage 1.8 — the Timer mode of the Drills hub. Tap-to-run presets plus a
// custom interval builder with optional athlete-group rotation. Launching a
// timer presents `DrillTimerRunView` full-screen.

public struct DrillTimerView: View {
    @Binding private var isLibrary: Bool
    @Environment(\.horizontalSizeClass) private var hSize

    @State private var running: DrillTimerSession?

    // Custom builder state
    @State private var work = 30
    @State private var rest = 15
    @State private var rounds = 8
    @State private var prep = 10
    @State private var groupsOn = false
    @State private var groupCount = 2

    public init(isLibrary: Binding<Bool> = .constant(false)) {
        _isLibrary = isLibrary
    }

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    presetsSection
                    customSection
                }
                .padding(.horizontal, isWide ? 18 : 14)
                .padding(.vertical, 16)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        #if os(iOS)
        .fullScreenCover(item: $running) { session in
            DrillTimerRunView(session: session)
        }
        #else
        .sheet(item: $running) { session in
            DrillTimerRunView(session: session)
        }
        #endif
    }

    // MARK: Header

    private var header: some View {
        Group {
            if isWide {
                HStack(alignment: .center, spacing: 16) {
                    titleBlock
                    Spacer(minLength: 8)
                    DrillModeSwitcher(isLibrary: $isLibrary)
                    Spacer(minLength: 8)
                    Color.clear.frame(width: 200, height: 1)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    titleBlock
                    DrillModeSwitcher(isLibrary: $isLibrary)
                }
            }
        }
        .padding(.horizontal, isWide ? 18 : 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("drill.timer.title").scaledFont(.title2, weight: .bold)
            Text("drill.timer.subtitle")
                .scaledFont(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Presets

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("timer.quick_start").scaledFont(.headline, weight: .bold)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                TimerPresetCard(titleKey: "timer.preset.tabata",
                                subtitle: "8 × 0:20 / 0:10",
                                systemIcon: "bolt.fill", tint: .secondaryAccent) {
                    running = .tabata()
                }
                TimerPresetCard(titleKey: "timer.preset.rounds",
                                subtitle: "3 × 3:00 / 1:00",
                                systemIcon: "figure.kickboxing", tint: .accentColor) {
                    running = .rounds()
                }
                TimerPresetCard(titleKey: "timer.preset.emom",
                                subtitle: "10 × 1:00",
                                systemIcon: "repeat", tint: .orange) {
                    running = .emom()
                }
            }
        }
    }

    // MARK: Custom builder

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("timer.custom").scaledFont(.headline, weight: .bold)
            VStack(spacing: 10) {
                TimerStepperRow(titleKey: "timer.phase.work", systemIcon: "bolt.fill",
                                value: $work, range: 5...600, step: 5,
                                format: formatTimerClock)
                TimerStepperRow(titleKey: "timer.phase.rest", systemIcon: "pause.fill",
                                value: $rest, range: 0...300, step: 5,
                                format: formatTimerClock)
                TimerStepperRow(titleKey: "timer.rounds", systemIcon: "repeat",
                                value: $rounds, range: 1...30, step: 1,
                                format: { "\($0)" })
                TimerStepperRow(titleKey: "timer.prepare", systemIcon: "figure.stand",
                                value: $prep, range: 0...60, step: 5,
                                format: formatTimerClock)
                groupModeCard
                totalRow
                startButton
            }
        }
    }

    private var groupModeCard: some View {
        VStack(spacing: 10) {
            Toggle(isOn: $groupsOn.animation(.easeInOut(duration: 0.18))) {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .scaledFont(.subheadline, weight: .semibold)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("timer.groups").scaledFont(.subheadline, weight: .medium)
                        Text("timer.groups.hint")
                            .scaledFont(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            if groupsOn {
                TimerStepperRow(titleKey: "timer.groups.count", systemIcon: "number",
                                value: $groupCount, range: 2...4, step: 1,
                                format: { "\($0)" })
                HStack(spacing: 6) {
                    ForEach(groupNames, id: \.self) { name in
                        Text(verbatim: name)
                            .scaledFont(.caption2, weight: .semibold)
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.12), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
    }

    private var totalRow: some View {
        HStack {
            Text("timer.total").scaledFont(.subheadline, weight: .medium)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(verbatim: formatTimerClock(builtSession.totalSeconds))
                .scaledFont(.subheadline, weight: .bold, monospacedDigit: true)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    private var startButton: some View {
        Button {
            running = builtSession
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill").scaledFont(.subheadline, weight: .bold)
                Text("timer.start").scaledFont(.headline, weight: .semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.82)],
                               startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .shadow(color: Color.accentColor.opacity(0.32), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    // MARK: Derived

    private var groupNames: [String] {
        let letters = ["A", "B", "C", "D"]
        return (0..<min(groupCount, letters.count)).map { i in
            String(format: NSLocalizedString("timer.group.fmt", comment: ""), letters[i])
        }
    }

    private var builtSession: DrillTimerSession {
        DrillTimerSession.interval(
            name: NSLocalizedString("timer.custom", comment: ""),
            work: work,
            rest: rest,
            rounds: rounds,
            prepare: prep,
            groups: groupsOn ? groupNames : []
        )
    }
}

import SwiftUI

/// Combined Drills hub. The Timer / Library mode switch now lives inside each
/// screen's header (`DrillModeSwitcher`) rather than a separate segmented bar,
/// so this view just owns the shared `isLibrary` state and routes to the
/// premium Drill Library or the drill timer.
public struct DrillsAndTimerView: View {
    @State private var isLibrary = true

    public init() {}

    public var body: some View {
        if isLibrary {
            DrillLibraryView(isLibrary: $isLibrary)
        } else {
            DrillTimerModeView(isLibrary: $isLibrary)
        }
    }
}

/// Timer mode wrapper — a premium header carrying the mode switcher above the
/// interval-timer library. The timer itself is slated for a from-scratch
/// rebuild in a follow-up pass (Stage 1.8 sequenced Drill Library first).
struct DrillTimerModeView: View {
    @Binding var isLibrary: Bool
    @Environment(\.horizontalSizeClass) private var hSize

    private var isWide: Bool { hSize == .regular }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if isWide {
                    HStack(alignment: .center, spacing: 16) {
                        titleBlock
                        Spacer(minLength: 8)
                        DrillModeSwitcher(isLibrary: $isLibrary)
                        Spacer(minLength: 8)
                        Color.clear.frame(width: 220, height: 1)
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

            PomodoroLibraryView()
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("drill.timer.title").scaledFont(.title2, weight: .bold)
            Text("drill.timer.subtitle")
                .scaledFont(.caption).foregroundStyle(.secondary)
        }
    }
}

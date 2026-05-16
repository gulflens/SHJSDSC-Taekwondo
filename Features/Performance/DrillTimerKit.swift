import SwiftUI

// MARK: - Drill Timer design kit
//
// Stage 1.8 — shared visual vocabulary for the from-scratch Drill Timer:
// phase colours, the big countdown ring, control buttons, and preset cards.

public extension DrillTimerPhase {
    /// Phase accent — green "go" for work, warm tones for rest.
    var tint: Color {
        switch self {
        case .prepare:    .indigo
        case .work:       .secondaryAccent
        case .rest:       .orange
        case .roundBreak: .purple
        case .finished:   .secondaryAccent
        }
    }

    var systemIcon: String {
        switch self {
        case .prepare:    "figure.stand"
        case .work:       "bolt.fill"
        case .rest:       "pause.fill"
        case .roundBreak: "figure.cooldown"
        case .finished:   "checkmark.seal.fill"
        }
    }
}

/// `mm:ss` for a whole-second count; `h:mm:ss` past an hour.
func formatTimerClock(_ seconds: Int) -> String {
    let s = max(0, seconds)
    if s >= 3600 {
        return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }
    return String(format: "%d:%02d", s / 60, s % 60)
}

// MARK: - Countdown ring

/// Large circular countdown — a tinted track, a trimmed progress arc, and
/// caller-supplied centre content.
public struct CountdownRing<Content: View>: View {
    private let progress: Double
    private let tint: Color
    private let lineWidth: CGFloat
    private let content: Content

    public init(
        progress: Double,
        tint: Color,
        lineWidth: CGFloat = 14,
        @ViewBuilder content: () -> Content
    ) {
        self.progress = min(1, max(0, progress))
        self.tint = tint
        self.lineWidth = lineWidth
        self.content = content()
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.16), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: progress)
                .shadow(color: tint.opacity(0.5), radius: 8)
            content
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

// MARK: - Control button

/// Circular transport control. `prominent` renders the filled primary action
/// (play/pause); the rest are tinted-glass secondary controls.
public struct TimerControlButton: View {
    private let systemIcon: String
    private let prominent: Bool
    private let tint: Color
    private let size: CGFloat
    private let action: () -> Void

    public init(
        systemIcon: String,
        prominent: Bool = false,
        tint: Color = .accentColor,
        size: CGFloat = 56,
        action: @escaping () -> Void
    ) {
        self.systemIcon = systemIcon
        self.prominent = prominent
        self.tint = tint
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemIcon)
                .font(.system(size: size * (prominent ? 0.4 : 0.36), weight: .bold))
                .foregroundStyle(prominent ? Color.white : Color.primary)
                .frame(width: size, height: size)
                .background(
                    Circle().fill(
                        prominent
                            ? AnyShapeStyle(LinearGradient(
                                colors: [tint, tint.opacity(0.82)],
                                startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(.ultraThinMaterial))
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(prominent ? 0 : 0.18), lineWidth: 1)
                )
                .shadow(color: prominent ? tint.opacity(0.4) : .black.opacity(0.12),
                        radius: prominent ? 12 : 5, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preset card

/// Tap-to-run preset tile on the timer setup screen.
public struct TimerPresetCard: View {
    private let titleKey: String
    private let subtitle: String
    private let systemIcon: String
    private let tint: Color
    private let action: () -> Void

    public init(
        titleKey: String,
        subtitle: String,
        systemIcon: String,
        tint: Color,
        action: @escaping () -> Void
    ) {
        self.titleKey = titleKey
        self.subtitle = subtitle
        self.systemIcon = systemIcon
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemIcon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(colors: [tint, tint.opacity(0.78)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Spacer(minLength: 4)
                Text(localizedKey: titleKey)
                    .scaledFont(.headline, weight: .bold)
                Text(verbatim: subtitle)
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
            .padding(14)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stepper row

/// Labelled −/+ stepper row used in the custom-timer builder.
public struct TimerStepperRow: View {
    private let titleKey: String
    private let systemIcon: String
    @Binding private var value: Int
    private let range: ClosedRange<Int>
    private let step: Int
    private let format: (Int) -> String

    public init(
        titleKey: String,
        systemIcon: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int = 1,
        format: @escaping (Int) -> String
    ) {
        self.titleKey = titleKey
        self.systemIcon = systemIcon
        _value = value
        self.range = range
        self.step = step
        self.format = format
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemIcon)
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(Color.accentColor)
                .frame(width: 26)
            Text(localizedKey: titleKey)
                .scaledFont(.subheadline, weight: .medium)
            Spacer(minLength: 8)
            HStack(spacing: 14) {
                stepButton("minus") {
                    value = max(range.lowerBound, value - step)
                }
                Text(verbatim: format(value))
                    .scaledFont(.subheadline, weight: .bold, monospacedDigit: true)
                    .frame(minWidth: 64)
                    .environment(\.layoutDirection, .leftToRight)
                stepButton("plus") {
                    value = min(range.upperBound, value + step)
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

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .scaledFont(.footnote, weight: .bold)
                .foregroundStyle(Color.accentColor)
                .frame(width: 30, height: 30)
                .background(Color.accentColor.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

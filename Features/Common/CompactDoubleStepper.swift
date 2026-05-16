import SwiftUI

/// Double-valued sibling of `CompactStepper`. Shows a `−` button, a tappable
/// label (opens a number-pad alert), and a `+` button. Useful for prices,
/// weights, percentages — anywhere a Double range is being edited.
public struct CompactDoubleStepper: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var decimals: Int = 0
    var prefix: String?
    var suffix: String?

    public init(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 1,
        decimals: Int = 0,
        prefix: String? = nil,
        suffix: String? = nil
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.decimals = decimals
        self.prefix = prefix
        self.suffix = suffix
    }

    public var body: some View {
        HStack(spacing: 8) {
            Button {
                value = max(range.lowerBound, value - step)
            } label: {
                Image(systemName: "minus")
                    .scaledFont(.caption, weight: .bold)
                    .foregroundStyle(value <= range.lowerBound ? .tertiary : .primary)
                    .frame(width: 28, height: 28)
                    .background(Color(.quaternarySystemFill), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .disabled(value <= range.lowerBound)

            Text(verbatim: label)
                .scaledFont(.callout, monospacedDigit: true)
                .foregroundStyle(.tint)
                .frame(minWidth: 56)
                .padding(.horizontal, 4)
                .tappableDouble($value, in: range, decimals: decimals)

            Button {
                value = min(range.upperBound, value + step)
            } label: {
                Image(systemName: "plus")
                    .scaledFont(.caption, weight: .bold)
                    .foregroundStyle(value >= range.upperBound ? .tertiary : .primary)
                    .frame(width: 28, height: 28)
                    .background(Color(.quaternarySystemFill), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .disabled(value >= range.upperBound)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private var label: String {
        var parts: [String] = []
        if let prefix { parts.append(prefix) }
        if decimals == 0 {
            parts.append("\(Int(value.rounded()))")
        } else {
            parts.append(String(format: "%.\(decimals)f", value))
        }
        if let suffix { parts.append(suffix) }
        return parts.joined(separator: " ")
    }
}

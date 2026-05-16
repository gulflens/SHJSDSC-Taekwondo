import SwiftUI

public struct CompactStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    var prefix: String?
    var suffix: String?

    public init(value: Binding<Int>, range: ClosedRange<Int>, step: Int = 1, prefix: String? = nil, suffix: String? = nil) {
        self._value = value
        self.range = range
        self.step = step
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
                .frame(minWidth: 32)
                .padding(.horizontal, 4)
                .tappableInt($value, in: range)

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
        parts.append("\(value)")
        if let suffix { parts.append(suffix) }
        return parts.joined()
    }
}

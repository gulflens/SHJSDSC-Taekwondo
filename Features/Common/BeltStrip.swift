import SwiftUI

public extension Color {
    init(hex: String) {
        var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") { trimmed.removeFirst() }
        guard let value = UInt64(trimmed, radix: 16) else {
            self = .gray
            return
        }
        let r: Double, g: Double, b: Double, a: Double
        switch trimmed.count {
        case 6:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        case 8:
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        default:
            self = .gray
            return
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

public extension BeltColor {
    var swiftUIColor: Color { Color(hex: hex) }
}

public struct BeltStrip: View {
    public let belt: Belt
    public let history: [Belt]
    public let height: CGFloat

    public init(belt: Belt, history: [Belt] = [], height: CGFloat = 8) {
        self.belt = belt
        self.history = history
        self.height = height
    }

    public var body: some View {
        let progression: [BeltColor] = [.white, .yellow, .green, .blue, .red, .black]
        let currentIdx = progression.firstIndex(of: belt.color) ?? (progression.count - 1)
        HStack(spacing: 4) {
            ForEach(Array(progression.enumerated()), id: \.offset) { idx, color in
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color.swiftUIColor)
                    .frame(height: height)
                    .opacity(idx <= currentIdx ? 1.0 : 0.18)
                    .overlay(
                        RoundedRectangle(cornerRadius: height / 2)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
            }
        }
    }
}

import Foundation

public enum BeltColor: String, Codable, CaseIterable, Sendable, Hashable {
    case white, yellow, green, blue, red, black

    public var hex: String {
        switch self {
        case .white: "#F5F5F5"
        case .yellow: "#FFD23F"
        case .green: "#2E9E5B"
        case .blue: "#1F6FEB"
        case .red: "#E53935"
        case .black: "#1A1A1A"
        }
    }

    public var labelKey: String { "belt.\(rawValue)" }
}

public enum BeltKind: String, Codable, CaseIterable, Sendable, Hashable {
    case gup, poom, dan

    public var labelKey: String { "belt.\(rawValue)" }
}

public struct Belt: Codable, Hashable, Sendable {
    public var color: BeltColor
    public var kind: BeltKind
    public var number: Int
    public var awardedAt: Date

    public init(color: BeltColor, kind: BeltKind, number: Int, awardedAt: Date) {
        self.color = color
        self.kind = kind
        self.number = number
        self.awardedAt = awardedAt
    }

    public var label: String {
        "belt.\(kind.rawValue).\(number)"
    }
}

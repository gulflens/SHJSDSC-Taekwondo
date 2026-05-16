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

    public var rank: BeltRank {
        BeltRank(kind: kind, number: number)
    }
}

/// Lightweight, awardless belt rank used by drill prerequisites and
/// curriculum filters. Total ordering across the gup → poom → dan ladder
/// is exposed via `rankIndex` so two ranks can be compared with `<` / `>`.
public struct BeltRank: Codable, Hashable, Sendable, Comparable {
    public var kind: BeltKind
    public var number: Int

    public init(kind: BeltKind, number: Int) {
        self.kind = kind
        self.number = number
    }

    public var label: String { "belt.\(kind.rawValue).\(number)" }

    /// Monotonic index across the full ladder.
    /// gup 10 = 0 … gup 1 = 9 ; poom 1 = 10 … poom 4 = 13 ; dan 1 = 14 … dan 9 = 22.
    public var rankIndex: Int {
        switch kind {
        case .gup: return max(0, 10 - number)
        case .poom: return 10 + max(0, number - 1)
        case .dan: return 14 + max(0, number - 1)
        }
    }

    public static func < (lhs: BeltRank, rhs: BeltRank) -> Bool {
        lhs.rankIndex < rhs.rankIndex
    }
}

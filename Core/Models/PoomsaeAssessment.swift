import Foundation

public enum PoomsaeForm: String, Codable, CaseIterable, Sendable, Hashable {
    // Coloured-belt syllabus (Kukkiwon Taegeuk series)
    case taegeuk1
    case taegeuk2
    case taegeuk3
    case taegeuk4
    case taegeuk5
    case taegeuk6
    case taegeuk7
    case taegeuk8

    // Black-belt syllabus
    case koryo
    case keumgang
    case taebaek
    case pyongwon
    case sipjin
    case jitae
    case cheonkwon
    case hansoo
    case ilyeo

    public var labelKey: String { "poomsae.\(rawValue)" }

    /// Whether this form belongs to the gup or dan ladder.
    public var isBlackBelt: Bool {
        switch self {
        case .taegeuk1, .taegeuk2, .taegeuk3, .taegeuk4,
             .taegeuk5, .taegeuk6, .taegeuk7, .taegeuk8:
            false
        default:
            true
        }
    }

    /// Belt level this form is first introduced at (Kukkiwon syllabus mapping):
    /// Taegeuk N → gup (9 - N), so Taegeuk 1 = gup 8 … Taegeuk 8 = gup 1.
    /// Black-belt forms → dan 1…9 in order.
    public var requiredAt: (kind: BeltKind, number: Int) {
        switch self {
        case .taegeuk1: (.gup, 8)
        case .taegeuk2: (.gup, 7)
        case .taegeuk3: (.gup, 6)
        case .taegeuk4: (.gup, 5)
        case .taegeuk5: (.gup, 4)
        case .taegeuk6: (.gup, 3)
        case .taegeuk7: (.gup, 2)
        case .taegeuk8: (.gup, 1)
        case .koryo:     (.dan, 1)
        case .keumgang:  (.dan, 2)
        case .taebaek:   (.dan, 3)
        case .pyongwon:  (.dan, 4)
        case .sipjin:    (.dan, 5)
        case .jitae:     (.dan, 6)
        case .cheonkwon: (.dan, 7)
        case .hansoo:    (.dan, 8)
        case .ilyeo:     (.dan, 9)
        }
    }

    /// True when this form is part of the syllabus an athlete at `belt`
    /// should already know. Gup numbering counts down (10 = white, 1 = pre-black);
    /// dan numbering counts up. Poom is treated as the junior equivalent of
    /// dan-1 so children with a poom belt are expected to know all gup forms
    /// plus Koryo.
    public func isRequired(for belt: Belt) -> Bool {
        let req = requiredAt
        switch (req.kind, belt.kind) {
        case (.gup, .gup):
            return belt.number <= req.number
        case (.gup, .poom), (.gup, .dan):
            return true
        case (.dan, .dan):
            return belt.number >= req.number
        case (.dan, .poom):
            return req.number == 1
        case (.dan, .gup):
            return false
        case (.poom, _):
            return false
        }
    }
}

public struct PoomsaeAssessment: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var athleteID: EntityID
    public var recordedAt: Date
    public var recordedByCoachID: EntityID
    public var form: PoomsaeForm
    /// 1...10 — stances, techniques, sequence.
    public var accuracy: Int
    /// 1...10 — power, speed, rhythm.
    public var presentation: Int
    /// 1...10 — overall stability and weight transfer.
    public var balance: Int
    /// 1...10 — kihap, intent, focus.
    public var expression: Int
    /// Time to complete the form, in seconds.
    public var timeSeconds: Int
    public var videoURL: String?
    public var notes: String?

    public init(
        id: EntityID = UUID(),
        athleteID: EntityID,
        recordedAt: Date,
        recordedByCoachID: EntityID,
        form: PoomsaeForm,
        accuracy: Int,
        presentation: Int,
        balance: Int,
        expression: Int,
        timeSeconds: Int,
        videoURL: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.athleteID = athleteID
        self.recordedAt = recordedAt
        self.recordedByCoachID = recordedByCoachID
        self.form = form
        self.accuracy = max(1, min(10, accuracy))
        self.presentation = max(1, min(10, presentation))
        self.balance = max(1, min(10, balance))
        self.expression = max(1, min(10, expression))
        self.timeSeconds = max(0, timeSeconds)
        self.videoURL = videoURL
        self.notes = notes
    }

    /// Mean of the four scoring axes, 1...10.
    public var averageScore: Double {
        Double(accuracy + presentation + balance + expression) / 4.0
    }
}

public extension Array where Element == PoomsaeAssessment {
    /// Latest assessment per form.
    func latestPerForm() -> [PoomsaeAssessment] {
        var seen: [PoomsaeForm: PoomsaeAssessment] = [:]
        for a in self.sorted(by: { $0.recordedAt > $1.recordedAt }) {
            if seen[a.form] == nil { seen[a.form] = a }
        }
        return Array(seen.values)
    }
}

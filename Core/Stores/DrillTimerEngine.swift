import Foundation
import Observation

// MARK: - Drill Timer engine
//
// Stage 1.8 — drives a `DrillTimerSession` in real time. The session is
// flattened once into a plain `[Step]` timeline (rounds expanded, lead-in and
// round breaks inserted, athlete groups assigned); running is then just a
// cursor walking that array. @Observable @MainActor so views observe it
// directly. No SwiftUI import — `Observation` only.

@Observable @MainActor
public final class DrillTimerEngine {

    /// One resolved entry on the timeline.
    public struct Step: Identifiable, Sendable, Hashable {
        public let id: EntityID
        public var phase: DrillTimerPhase
        public var seconds: Int
        public var label: String?
        public var drillID: EntityID?
        public var roundIndex: Int      // 1-based; 0 for the lead-in
        public var totalRounds: Int
        public var groupName: String?

        public init(
            id: EntityID = UUID(),
            phase: DrillTimerPhase,
            seconds: Int,
            label: String? = nil,
            drillID: EntityID? = nil,
            roundIndex: Int,
            totalRounds: Int,
            groupName: String? = nil
        ) {
            self.id = id
            self.phase = phase
            self.seconds = seconds
            self.label = label
            self.drillID = drillID
            self.roundIndex = roundIndex
            self.totalRounds = totalRounds
            self.groupName = groupName
        }
    }

    public private(set) var steps: [Step] = []
    public private(set) var index: Int = 0
    public private(set) var remaining: Double = 0
    public private(set) var isRunning: Bool = false
    public private(set) var isFinished: Bool = false
    public private(set) var sessionName: String = ""
    public private(set) var totalRounds: Int = 1

    /// Called when a new step becomes current — audio hooks transition cues.
    public var onEnterStep: ((Step) -> Void)?
    /// Called once per whole second of a step's countdown, with the integer
    /// seconds remaining — audio uses it for the last-three-seconds beeps.
    public var onTick: ((Int) -> Void)?
    /// Called once when the whole session completes.
    public var onFinish: (() -> Void)?

    private var ticker: Task<Void, Never>?
    private let tickHz: Double = 20
    private var lastAnnouncedSecond: Int = -1

    public init() {}

    // MARK: Loading

    /// Flattens a session into the step timeline. Resets any running state.
    public func load(_ session: DrillTimerSession) {
        stopTicker()
        isRunning = false
        isFinished = false
        index = 0
        sessionName = session.name
        totalRounds = session.rounds

        var built: [Step] = []
        let groups = session.athleteGroups

        func group(forRound r: Int) -> String? {
            guard !groups.isEmpty else { return nil }
            return groups[(r - 1) % groups.count]
        }

        if session.prepareSeconds > 0 {
            built.append(Step(phase: .prepare,
                              seconds: session.prepareSeconds,
                              roundIndex: 1,
                              totalRounds: session.rounds,
                              groupName: group(forRound: 1)))
        }
        for r in 1...session.rounds {
            for interval in session.intervals {
                built.append(Step(
                    phase: interval.isWork ? .work : .rest,
                    seconds: interval.seconds,
                    label: interval.label,
                    drillID: interval.drillID,
                    roundIndex: r,
                    totalRounds: session.rounds,
                    groupName: group(forRound: r)))
            }
            if r < session.rounds, session.roundBreakSeconds > 0 {
                built.append(Step(phase: .roundBreak,
                                  seconds: session.roundBreakSeconds,
                                  roundIndex: r,
                                  totalRounds: session.rounds,
                                  groupName: group(forRound: r + 1)))
            }
        }
        steps = built
        remaining = Double(built.first?.seconds ?? 0)
    }

    // MARK: Transport

    public func start() {
        guard !steps.isEmpty else { return }
        index = 0
        isFinished = false
        remaining = Double(steps[0].seconds)
        isRunning = true
        announceStep()
        spinTicker()
    }

    public func togglePause() {
        guard !isFinished, !steps.isEmpty else { return }
        isRunning.toggle()
        if isRunning { spinTicker() } else { stopTicker() }
    }

    public func skipForward() {
        guard !steps.isEmpty else { return }
        goTo(index + 1)
    }

    /// Restarts the current step if it's already underway, otherwise jumps to
    /// the previous step — the familiar media-player "previous" behaviour.
    public func skipBackward() {
        guard !steps.isEmpty, let cur = current else { return }
        if Double(cur.seconds) - remaining > 1.5 {
            remaining = Double(cur.seconds)
            lastAnnouncedSecond = -1
        } else {
            goTo(index - 1)
        }
    }

    /// Adds bonus time to the current step (the "+10s" control).
    public func addTime(_ seconds: Int) {
        guard current != nil else { return }
        remaining += Double(seconds)
    }

    public func reset() {
        stopTicker()
        isRunning = false
        isFinished = false
        index = 0
        lastAnnouncedSecond = -1
        remaining = Double(steps.first?.seconds ?? 0)
    }

    // MARK: Cursor

    private func goTo(_ newIndex: Int) {
        guard !steps.isEmpty else { return }
        if newIndex >= steps.count {
            finish()
            return
        }
        index = max(0, newIndex)
        remaining = Double(steps[index].seconds)
        lastAnnouncedSecond = -1
        announceStep()
    }

    private func finish() {
        stopTicker()
        isRunning = false
        isFinished = true
        remaining = 0
        onFinish?()
    }

    private func announceStep() {
        guard let step = current else { return }
        lastAnnouncedSecond = -1
        onEnterStep?(step)
    }

    // MARK: Ticker

    private func spinTicker() {
        stopTicker()
        ticker = Task { [weak self] in
            guard let self else { return }
            let interval = 1.0 / self.tickHz
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if Task.isCancelled { break }
                self.tick(by: interval)
            }
        }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }

    private func tick(by seconds: Double) {
        guard isRunning, !isFinished else { return }
        remaining -= seconds
        let whole = Int(ceil(remaining))
        if whole != lastAnnouncedSecond, whole >= 0 {
            lastAnnouncedSecond = whole
            onTick?(whole)
        }
        if remaining <= 0 {
            goTo(index + 1)
        }
    }

    // MARK: Derived state

    public var current: Step? {
        guard index >= 0, index < steps.count else { return nil }
        return steps[index]
    }

    public var next: Step? {
        let n = index + 1
        guard n >= 0, n < steps.count else { return nil }
        return steps[n]
    }

    public var phase: DrillTimerPhase {
        if isFinished { return .finished }
        return current?.phase ?? .prepare
    }

    /// 0 → 1 progress through the current step.
    public var stepProgress: Double {
        guard let cur = current, cur.seconds > 0 else { return 0 }
        return min(1, max(0, 1 - remaining / Double(cur.seconds)))
    }

    public var totalDuration: Int {
        steps.reduce(0) { $0 + $1.seconds }
    }

    public var elapsedTotal: Double {
        guard !steps.isEmpty else { return 0 }
        if isFinished { return Double(totalDuration) }
        let before = steps.prefix(index).reduce(0) { $0 + $1.seconds }
        let inStep = (current?.seconds).map { Double($0) - remaining } ?? 0
        return Double(before) + max(0, inStep)
    }

    /// 1-based index of the current work step ("Drill 3 of 8").
    public var workStepNumber: Int {
        guard index < steps.count else { return totalWorkSteps }
        return steps.prefix(index + 1).filter { $0.phase == .work }.count
    }

    public var totalWorkSteps: Int {
        steps.filter { $0.phase == .work }.count
    }
}

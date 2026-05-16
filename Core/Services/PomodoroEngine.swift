import Foundation
import Observation

/// Phase the engine reports. The view uses this for color, label, and to
/// decide which audio loop to play. Whistle is its own phase so the run
/// view can paint a distinct "transition" state instead of overlapping
/// work/rest visuals.
public enum PomodoroPhase: Sendable, Hashable {
    case idle
    case work
    case rest
    case whistle(next: WorkRest)
    case finished
}

/// Snapshot the engine emits on every tick. Push-only state — the run view
/// reads this and draws.
public struct PomodoroSnapshot: Sendable, Hashable {
    public var phase: PomodoroPhase
    public var phaseSecondsRemaining: Double
    public var phaseTotalSeconds: Double
    public var groupIndex: Int
    public var roundIndex: Int        // 0-based within the current group's repetitions
    public var intervalIndex: Int     // 0-based within the current group's intervals
    public var elapsedTotalSeconds: Double
    public var totalSeconds: Double
}

/// Drives a `TrainingPomodoro` plan in real time. Owns the timeline and
/// publishes snapshots; the audio service subscribes to phase changes.
/// MainActor-isolated because views observe it directly.
@Observable @MainActor
public final class PomodoroEngine {
    public private(set) var snapshot: PomodoroSnapshot = .init(
        phase: .idle, phaseSecondsRemaining: 0, phaseTotalSeconds: 0,
        groupIndex: 0, roundIndex: 0, intervalIndex: 0,
        elapsedTotalSeconds: 0, totalSeconds: 0
    )
    public private(set) var isRunning: Bool = false
    public private(set) var plan: TrainingPomodoro?

    /// Fires every tick (~10Hz). The audio service listens, and the run
    /// view animates its progress ring off the snapshot.
    public var onPhaseChange: ((PomodoroPhase) -> Void)?

    private var ticker: Task<Void, Never>?
    private let tickHz: Double = 10
    private var pausedAt: Date?

    public init() {}

    public func load(_ plan: TrainingPomodoro) {
        stop()
        self.plan = plan
        snapshot = .init(
            phase: .idle, phaseSecondsRemaining: 0, phaseTotalSeconds: 0,
            groupIndex: 0, roundIndex: 0, intervalIndex: 0,
            elapsedTotalSeconds: 0, totalSeconds: Double(plan.totalSeconds)
        )
    }

    public func start() {
        guard let plan, !plan.groups.isEmpty else { return }
        isRunning = true
        // First whistle leads into the first work interval.
        beginWhistle(next: firstIntervalKind() ?? .work)
        spinTicker()
    }

    public func togglePause() {
        if isRunning {
            isRunning = false
            ticker?.cancel()
            ticker = nil
            pausedAt = Date()
        } else {
            isRunning = true
            pausedAt = nil
            spinTicker()
        }
    }

    public func skipPhase() {
        advanceToNextPhase()
    }

    public func skipToNextGroup() {
        guard let plan else { return }
        let nextGroupIdx = snapshot.groupIndex + 1
        if nextGroupIdx < plan.groups.count {
            let nextGroup = plan.groups[nextGroupIdx]
            snapshot.groupIndex = nextGroupIdx
            snapshot.roundIndex = 0
            snapshot.intervalIndex = 0
            beginWhistle(next: nextGroup.intervals.first?.kind ?? .work)
        } else {
            finish()
        }
    }

    public func skipToPreviousGroup() {
        guard let plan, !plan.groups.isEmpty else { return }
        let prevGroupIdx = max(0, snapshot.groupIndex - 1)
        let group = plan.groups[prevGroupIdx]
        snapshot.groupIndex = prevGroupIdx
        snapshot.roundIndex = 0
        snapshot.intervalIndex = 0
        beginWhistle(next: group.intervals.first?.kind ?? .work)
    }

    public func stop() {
        isRunning = false
        ticker?.cancel()
        ticker = nil
        pausedAt = nil
        snapshot.phase = .idle
        snapshot.phaseSecondsRemaining = 0
        snapshot.phaseTotalSeconds = 0
        snapshot.groupIndex = 0
        snapshot.roundIndex = 0
        snapshot.intervalIndex = 0
        snapshot.elapsedTotalSeconds = 0
    }

    // MARK: - Phase logic

    private func firstIntervalKind() -> WorkRest? {
        plan?.groups.first?.intervals.first?.kind
    }

    private func beginWhistle(next: WorkRest) {
        guard let plan else { return }
        snapshot.phase = .whistle(next: next)
        snapshot.phaseTotalSeconds = plan.whistleSeconds
        snapshot.phaseSecondsRemaining = plan.whistleSeconds
        onPhaseChange?(snapshot.phase)
    }

    private func beginInterval(groupIdx: Int, roundIdx: Int, intervalIdx: Int) {
        guard let plan,
              groupIdx < plan.groups.count else {
            finish()
            return
        }
        let group = plan.groups[groupIdx]
        guard intervalIdx < group.intervals.count else {
            // End of round in this group: bump round, or move to next group.
            if roundIdx + 1 < group.repetitions {
                beginWhistle(next: group.intervals.first?.kind ?? .work)
                snapshot.groupIndex = groupIdx
                snapshot.roundIndex = roundIdx + 1
                snapshot.intervalIndex = 0
            } else if groupIdx + 1 < plan.groups.count {
                let nextGroup = plan.groups[groupIdx + 1]
                beginWhistle(next: nextGroup.intervals.first?.kind ?? .work)
                snapshot.groupIndex = groupIdx + 1
                snapshot.roundIndex = 0
                snapshot.intervalIndex = 0
            } else {
                finish()
            }
            return
        }
        let interval = group.intervals[intervalIdx]
        snapshot.phase = (interval.kind == .work) ? .work : .rest
        snapshot.phaseTotalSeconds = Double(interval.durationSeconds)
        snapshot.phaseSecondsRemaining = Double(interval.durationSeconds)
        snapshot.groupIndex = groupIdx
        snapshot.roundIndex = roundIdx
        snapshot.intervalIndex = intervalIdx
        onPhaseChange?(snapshot.phase)
    }

    private func advanceToNextPhase() {
        guard let plan else { return }
        switch snapshot.phase {
        case .whistle:
            // Whistle ends; start the interval at the current cursor.
            beginInterval(
                groupIdx: snapshot.groupIndex,
                roundIdx: snapshot.roundIndex,
                intervalIdx: snapshot.intervalIndex
            )
        case .work, .rest:
            // Interval ends; either next interval (after whistle) or end of round.
            let group = plan.groups[snapshot.groupIndex]
            let nextIntervalIdx = snapshot.intervalIndex + 1
            if nextIntervalIdx < group.intervals.count {
                let upcoming = group.intervals[nextIntervalIdx].kind
                snapshot.intervalIndex = nextIntervalIdx
                beginWhistle(next: upcoming)
            } else if snapshot.roundIndex + 1 < group.repetitions {
                let upcoming = group.intervals.first?.kind ?? .work
                snapshot.roundIndex += 1
                snapshot.intervalIndex = 0
                beginWhistle(next: upcoming)
            } else if snapshot.groupIndex + 1 < plan.groups.count {
                let nextGroup = plan.groups[snapshot.groupIndex + 1]
                let upcoming = nextGroup.intervals.first?.kind ?? .work
                snapshot.groupIndex += 1
                snapshot.roundIndex = 0
                snapshot.intervalIndex = 0
                beginWhistle(next: upcoming)
            } else {
                finish()
            }
        case .idle, .finished:
            break
        }
    }

    private func finish() {
        snapshot.phase = .finished
        snapshot.phaseSecondsRemaining = 0
        isRunning = false
        ticker?.cancel()
        ticker = nil
        onPhaseChange?(.finished)
    }

    // MARK: - Ticker

    private func spinTicker() {
        ticker?.cancel()
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

    private func tick(by seconds: Double) {
        guard isRunning else { return }
        let remaining = snapshot.phaseSecondsRemaining - seconds
        var elapsed = snapshot.elapsedTotalSeconds
        if snapshot.phase != .idle, snapshot.phase != .finished, !isWhistlePhase(snapshot.phase) {
            elapsed += seconds
        }
        if remaining <= 0 {
            advanceToNextPhase()
            return
        }
        snapshot.phaseSecondsRemaining = max(0, remaining)
        snapshot.elapsedTotalSeconds = elapsed
    }

    private func isWhistlePhase(_ p: PomodoroPhase) -> Bool {
        if case .whistle = p { return true }
        return false
    }
}

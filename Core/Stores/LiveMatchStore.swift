import Foundation
import Observation

@Observable @MainActor
public final class LiveMatchStore {
    public private(set) var match: Match?
    public private(set) var currentRound: Int = 1
    public private(set) var roundTimeRemainingSec: Int = 120
    public private(set) var isTimerRunning: Bool = false
    public private(set) var winner: MatchSide?
    public private(set) var isFinalized: Bool = false

    public let roundDurationSec: Int = 120

    private var timerTask: Task<Void, Never>?
    private let repository: any Repository

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func startMatch(athlete: Athlete, opponentName: String, weightCategory: WeightCategory, tournament: Tournament?, rounds: Int = 3) async {
        let m = Match(
            tournamentName: tournament?.name ?? String(localized: "match.practice"),
            tournamentID: tournament?.id,
            date: Date(),
            ourAthleteID: athlete.id,
            opponentAthleteID: nil,
            opponentName: opponentName,
            weightClassKg: weightCategory.range.upper ?? 100,
            rounds: rounds,
            ourScore: 0,
            opponentScore: 0,
            won: false,
            medal: .none,
            events: []
        )
        match = m
        currentRound = 1
        roundTimeRemainingSec = roundDurationSec
        winner = nil
        isFinalized = false
        do { try await repository.startMatch(m) } catch { print("LiveMatchStore.startMatch:", error) }
        startTimer()
    }

    public func recordEvent(side: MatchSide, action: ScoreAction) async {
        guard var m = match, !isFinalized else { return }
        let event = ScoreEvent(
            matchID: m.id,
            round: currentRound,
            atSecond: roundDurationSec - roundTimeRemainingSec,
            side: side,
            action: action
        )
        m = ScoringEngine.applyEvent(to: m, event: event)
        match = m
        do { try await repository.recordEvent(event) } catch { print("LiveMatchStore.recordEvent:", error) }
        if ScoringEngine.isMatchOver(m, currentRound: currentRound) {
            winner = ScoringEngine.declareWinner(m)
            stopTimer()
        }
    }

    /// Apply an event received from a realtime channel. Idempotent — skips
    /// if the event id is already in the local match's events (which is what
    /// happens when our own `recordEvent` call echoes back through the
    /// realtime subscription).
    public func applyRemoteEvent(_ event: ScoreEvent) {
        guard var m = match, m.id == event.matchID, !isFinalized else { return }
        guard !m.events.contains(where: { $0.id == event.id }) else { return }
        m = ScoringEngine.applyEvent(to: m, event: event)
        match = m
        if ScoringEngine.isMatchOver(m, currentRound: currentRound) {
            winner = ScoringEngine.declareWinner(m)
        }
    }

    public func undoLast(side: MatchSide) {
        guard var m = match, !isFinalized else { return }
        guard let lastIdx = m.events.lastIndex(where: { $0.side == side }) else { return }
        let removed = m.events.remove(at: lastIdx)
        let pts = removed.action.points
        if removed.action == .penalty {
            switch removed.side {
            case .chung: m.opponentScore = max(0, m.opponentScore - pts)
            case .hong: m.ourScore = max(0, m.ourScore - pts)
            }
        } else {
            switch removed.side {
            case .chung: m.ourScore = max(0, m.ourScore - pts)
            case .hong: m.opponentScore = max(0, m.opponentScore - pts)
            }
        }
        match = m
        winner = nil
    }

    public func endRound() async {
        guard let m = match, !isFinalized else { return }
        stopTimer()
        do { try await repository.endRound(matchID: m.id) } catch { print("LiveMatchStore.endRound:", error) }
        if currentRound >= m.rounds {
            winner = ScoringEngine.declareWinner(m)
        }
    }

    public func startNextRound() {
        guard let m = match, !isFinalized else { return }
        if currentRound < m.rounds {
            currentRound += 1
            roundTimeRemainingSec = roundDurationSec
            winner = nil
            startTimer()
        }
    }

    public func finalize(medal: MedalType) async -> Match? {
        guard var m = match else { return nil }
        let w = winner ?? ScoringEngine.declareWinner(m)
        m.won = (w == .chung)
        m.medal = medal
        do { try await repository.finalizeMatch(m) } catch { print("LiveMatchStore.finalize:", error) }
        isFinalized = true
        stopTimer()
        match = m
        return m
    }

    public func togglePause() {
        if isTimerRunning { stopTimer() } else { startTimer() }
    }

    private func startTimer() {
        timerTask?.cancel()
        guard roundTimeRemainingSec > 0, !isFinalized else { return }
        isTimerRunning = true
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let strong = self, strong.roundTimeRemainingSec > 0 else { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                await MainActor.run {
                    strong.roundTimeRemainingSec = max(0, strong.roundTimeRemainingSec - 1)
                }
                if strong.roundTimeRemainingSec == 0 {
                    await strong.endRound()
                    break
                }
            }
            await MainActor.run { self?.isTimerRunning = false }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        isTimerRunning = false
    }

    public var formattedTime: String {
        let m = roundTimeRemainingSec / 60
        let s = roundTimeRemainingSec % 60
        return String(format: "%d:%02d", m, s)
    }
}

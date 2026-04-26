import Foundation
import Observation

@Observable @MainActor
public final class GradingStore {
    public private(set) var sessions: [GradingSession] = []
    public private(set) var activeSessionID: EntityID?
    public private(set) var scoresBySession: [EntityID: [GradingScore]] = [:]
    public private(set) var isLoading = false

    private let repository: any Repository

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func load(branchID: EntityID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            sessions = try await repository.gradingSessions(branchID: branchID)
            for s in sessions {
                scoresBySession[s.id] = try await repository.gradingScores(sessionID: s.id)
            }
        } catch {
            print("GradingStore.load:", error)
        }
    }

    public func loadAll(branches: [Branch]) async {
        isLoading = true
        defer { isLoading = false }
        do {
            var all: [GradingSession] = []
            for b in branches {
                all.append(contentsOf: try await repository.gradingSessions(branchID: b.id))
            }
            sessions = all.sorted { $0.scheduledAt < $1.scheduledAt }
            for s in sessions {
                scoresBySession[s.id] = try await repository.gradingScores(sessionID: s.id)
            }
        } catch {
            print("GradingStore.loadAll:", error)
        }
    }

    public func setActive(_ sessionID: EntityID?) {
        activeSessionID = sessionID
    }

    public func eligibility(athlete: Athlete, targetBelt: Belt) async -> GradingEligibility? {
        do {
            return try await repository.eligibility(athleteID: athlete.id, targetBelt: targetBelt)
        } catch {
            print("GradingStore.eligibility:", error)
            return nil
        }
    }

    public func saveScore(_ score: GradingScore) async {
        do {
            try await repository.upsert(score)
            // refresh scores for that session
            scoresBySession[score.sessionID] = try await repository.gradingScores(sessionID: score.sessionID)
        } catch {
            print("GradingStore.saveScore:", error)
        }
    }

    public func saveSession(_ session: GradingSession) async {
        do {
            try await repository.upsert(session)
            if let bid = sessions.first?.branchID {
                _ = bid
            }
            // refresh sessions for the affected branch
            sessions = try await repository.gradingSessions(branchID: session.branchID)
            scoresBySession[session.id] = try await repository.gradingScores(sessionID: session.id)
        } catch {
            print("GradingStore.saveSession:", error)
        }
    }

    public func issueCertificate(athlete: Athlete, sessionID: EntityID, targetBelt: Belt, signedBy: [EntityID]) async -> GradingCertificate? {
        let cert = GradingCertificate(
            athleteID: athlete.id,
            fromBelt: athlete.currentBelt,
            toBelt: targetBelt,
            awardedAt: Date(),
            sessionID: sessionID,
            signedByCoachIDs: signedBy
        )
        do {
            try await repository.issueCertificate(cert)
            // promote the athlete in the local store
            var promoted = athlete
            promoted.beltHistory.append(promoted.currentBelt)
            promoted.currentBelt = targetBelt
            try await repository.upsert(promoted)
            return cert
        } catch {
            print("GradingStore.issueCertificate:", error)
            return nil
        }
    }

    public func progress(for sessionID: EntityID) -> (scored: Int, total: Int) {
        let scored = scoresBySession[sessionID]?.count ?? 0
        let total = sessions.first { $0.id == sessionID }?.candidateAthleteIDs.count ?? 0
        return (scored, total)
    }
}

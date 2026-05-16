import Foundation
import Observation

@Observable @MainActor
public final class LiveClassStore {
    public let session: ClassSession
    public private(set) var athletes: [Athlete] = []
    public private(set) var marks: [EntityID: AttendanceState] = [:]
    /// Quick engagement rating (1...5) captured in the wrap-up phase.
    /// Persists into `AttendanceRecord.effortRating`.
    public private(set) var ratings: [EntityID: Int] = [:]
    public private(set) var isLoading = false
    public private(set) var isSaving = false
    public private(set) var saved = false

    private let repository: any Repository

    public init(session: ClassSession, repository: any Repository) {
        self.session = session
        self.repository = repository
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let all = try await repository.athletes()
            let enrolled = Set(session.enrolledAthleteIDs)
            athletes = all
                .filter { enrolled.contains($0.id) }
                .sorted { $0.fullName < $1.fullName }
            let existing = try await repository.attendance(sessionID: session.id)
            for r in existing {
                marks[r.athleteID] = r.state
                if let e = r.effortRating { ratings[r.athleteID] = e }
            }
            for a in athletes where marks[a.id] == nil {
                marks[a.id] = .present
            }
        } catch {
            print("LiveClassStore.load:", error)
        }
    }

    public func setState(_ state: AttendanceState, for athleteID: EntityID) {
        marks[athleteID] = state
    }

    public func cycleState(for athleteID: EntityID) {
        let order: [AttendanceState] = [.present, .late, .absent, .excused]
        let current = marks[athleteID] ?? .present
        let idx = order.firstIndex(of: current) ?? 0
        marks[athleteID] = order[(idx + 1) % order.count]
    }

    public func markAllPresent() {
        for a in athletes { marks[a.id] = .present }
    }

    public func setRating(_ rating: Int, for athleteID: EntityID) {
        ratings[athleteID] = max(1, min(5, rating))
    }

    public var presentCount: Int {
        athletes.reduce(into: 0) { acc, a in
            let s = marks[a.id] ?? .present
            if s == .present || s == .late { acc += 1 }
        }
    }

    public var absentCount: Int {
        athletes.reduce(into: 0) { acc, a in
            let s = marks[a.id] ?? .present
            if s == .absent || s == .excused { acc += 1 }
        }
    }

    public func save() async {
        isSaving = true
        saved = false
        defer { isSaving = false }
        do {
            let records = athletes.map { a -> AttendanceRecord in
                AttendanceRecord(
                    sessionID: session.id,
                    athleteID: a.id,
                    state: marks[a.id] ?? .present,
                    recordedAt: Date(),
                    effortRating: ratings[a.id]
                )
            }
            try await repository.upsertAttendance(records)
            saved = true
        } catch {
            print("LiveClassStore.save:", error)
        }
    }
}

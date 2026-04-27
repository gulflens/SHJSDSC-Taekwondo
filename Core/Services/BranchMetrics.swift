import Foundation

public struct BranchOperationalMetrics: Sendable, Hashable {
    public let registeredCount: Int
    public let activeCount: Int
    public let waitlistCount: Int
    public let utilisationPct: Double
    public let retentionPct90d: Double
    public let newSignups30d: Int
    public let churn30d: Int
    public let avgAttendancePct: Double
    public let competitionTeamCount: Int
    public let readyToGradeCount: Int
    public let watchListCount: Int
    public let restCount: Int
    public let sessionsPerWeek: Int
    public let totalCoaches: Int
    public let coachesWithCurrentSafeguardingPct: Double

    public init(
        registeredCount: Int,
        activeCount: Int,
        waitlistCount: Int,
        utilisationPct: Double,
        retentionPct90d: Double,
        newSignups30d: Int,
        churn30d: Int,
        avgAttendancePct: Double,
        competitionTeamCount: Int,
        readyToGradeCount: Int,
        watchListCount: Int,
        restCount: Int,
        sessionsPerWeek: Int,
        totalCoaches: Int,
        coachesWithCurrentSafeguardingPct: Double
    ) {
        self.registeredCount = registeredCount
        self.activeCount = activeCount
        self.waitlistCount = waitlistCount
        self.utilisationPct = utilisationPct
        self.retentionPct90d = retentionPct90d
        self.newSignups30d = newSignups30d
        self.churn30d = churn30d
        self.avgAttendancePct = avgAttendancePct
        self.competitionTeamCount = competitionTeamCount
        self.readyToGradeCount = readyToGradeCount
        self.watchListCount = watchListCount
        self.restCount = restCount
        self.sessionsPerWeek = sessionsPerWeek
        self.totalCoaches = totalCoaches
        self.coachesWithCurrentSafeguardingPct = coachesWithCurrentSafeguardingPct
    }

    public static let empty = BranchOperationalMetrics(
        registeredCount: 0, activeCount: 0, waitlistCount: 0, utilisationPct: 0,
        retentionPct90d: 0, newSignups30d: 0, churn30d: 0, avgAttendancePct: 0,
        competitionTeamCount: 0, readyToGradeCount: 0, watchListCount: 0,
        restCount: 0, sessionsPerWeek: 0, totalCoaches: 0,
        coachesWithCurrentSafeguardingPct: 0
    )
}

/// Pure compute namespace — every input is supplied by the caller so the
/// service can be unit-tested without touching the repository or Calendar
/// state. Intended to be called by BranchProfileStore once it has fanned
/// out its async lets.
public enum BranchMetrics {

    public static func compute(
        branch: Branch,
        athletes: [Athlete],
        attendance: [AttendanceRecord],
        sessions: [ClassSession],
        coaches: [Coach],
        now: Date = Date()
    ) -> BranchOperationalMetrics {
        let cal = Calendar(identifier: .gregorian)
        let day30 = cal.date(byAdding: .day, value: -30, to: now) ?? now
        let day90 = cal.date(byAdding: .day, value: -90, to: now) ?? now

        let registered = athletes.count
        let active = athletes.filter { $0.status != .rest }.count
        let utilisation = branch.capacity > 0
            ? min(1.0, Double(registered) / Double(branch.capacity)) : 0
        let waitlist = max(0, registered - branch.capacity)

        let newSignups30 = athletes.filter { $0.joinedAt >= day30 }.count

        // Churn proxy: athletes who joined ≥30d ago but are now resting are
        // counted as drop-outs for the 30d window. With only an active/rest
        // status field this is the closest signal we have.
        let churn30 = athletes.filter { $0.joinedAt < day30 && $0.status == .rest }.count

        let cohort90 = athletes.filter { $0.joinedAt < day90 }
        let cohortStart = cohort90.count
        let cohortStillActive = cohort90.filter { $0.status != .rest }.count
        let retention = cohortStart > 0
            ? Double(cohortStillActive) / Double(cohortStart) : 0

        let recentAttendance = attendance.filter { $0.recordedAt >= day30 }
        let attendanceTotal = recentAttendance.count
        let attendancePresent = recentAttendance.filter { $0.state == .present || $0.state == .late }.count
        let avgAttendance = attendanceTotal > 0
            ? Double(attendancePresent) / Double(attendanceTotal) : 0

        let comp = athletes.filter { $0.status == .competitionTeam }.count
        let ready = athletes.filter { $0.status == .readyToGrade }.count
        let watch = athletes.filter { $0.status == .watch }.count
        let rest = athletes.filter { $0.status == .rest }.count

        // Distinct sessions in a 7-day window centred on `now` give the
        // weekly-cadence number a manager actually expects on a dashboard.
        let weekStart = cal.date(byAdding: .day, value: -7, to: now) ?? now
        let sessionsPerWeek = sessions.filter { $0.startsAt >= weekStart && $0.startsAt <= now }.count

        let safeguardCutoff = now
        let withSafeguarding = coaches.filter { $0.safeguardingExpiry >= safeguardCutoff }.count
        let safeguardingPct = coaches.isEmpty ? 0 : Double(withSafeguarding) / Double(coaches.count)

        return BranchOperationalMetrics(
            registeredCount: registered,
            activeCount: active,
            waitlistCount: waitlist,
            utilisationPct: utilisation,
            retentionPct90d: retention,
            newSignups30d: newSignups30,
            churn30d: churn30,
            avgAttendancePct: avgAttendance,
            competitionTeamCount: comp,
            readyToGradeCount: ready,
            watchListCount: watch,
            restCount: rest,
            sessionsPerWeek: sessionsPerWeek,
            totalCoaches: coaches.count,
            coachesWithCurrentSafeguardingPct: safeguardingPct
        )
    }
}

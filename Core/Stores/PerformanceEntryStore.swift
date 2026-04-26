import Foundation
import Observation

public struct TrendPoint: Identifiable, Hashable, Sendable {
    public let id: EntityID
    public let date: Date
    public let value: Double

    public init(id: EntityID = UUID(), date: Date, value: Double) {
        self.id = id
        self.date = date
        self.value = value
    }
}

@Observable @MainActor
public final class PerformanceEntryStore {
    public private(set) var physicalTests: [PhysicalTest] = []
    public private(set) var assessments: [TechnicalAssessment] = []
    public private(set) var wellness: [WellnessEntry] = []
    public private(set) var isLoading = false

    private let repository: any Repository

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func load(athleteID: EntityID, windowDays: Int = 90) async {
        isLoading = true
        defer { isLoading = false }
        let since = Date().addingTimeInterval(-Double(windowDays) * 24 * 3600)
        do {
            physicalTests = try await repository.physicalTests(athleteID: athleteID)
            assessments = try await repository.assessments(athleteID: athleteID)
            wellness = try await repository.wellness(athleteID: athleteID, since: since)
        } catch {
            print("PerformanceEntryStore.load:", error)
        }
    }

    public func save(physicalTest: PhysicalTest) async {
        do {
            try await repository.upsert(physicalTest: physicalTest)
            await load(athleteID: physicalTest.athleteID)
        } catch {
            print("PerformanceEntryStore.save physical:", error)
        }
    }

    public func save(assessment: TechnicalAssessment) async {
        do {
            try await repository.upsert(assessment: assessment)
            await load(athleteID: assessment.athleteID)
        } catch {
            print("PerformanceEntryStore.save assessment:", error)
        }
    }

    public func save(wellness entry: WellnessEntry) async {
        do {
            try await repository.upsert(wellness: entry)
            await load(athleteID: entry.athleteID)
        } catch {
            print("PerformanceEntryStore.save wellness:", error)
        }
    }

    /// Latest physical composite (0..100) per recorded date, last `days` days.
    public func physicalTrend(days: Int = 90) -> [TrendPoint] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 3600)
        return physicalTests
            .filter { $0.recordedAt >= cutoff }
            .sorted { $0.recordedAt < $1.recordedAt }
            .map { TrendPoint(id: $0.id, date: $0.recordedAt, value: GradingEngine.physicalCompositeScore($0)) }
    }

    public func technicalTrend(days: Int = 90) -> [TrendPoint] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 3600)
        return assessments
            .filter { $0.recordedAt >= cutoff }
            .sorted { $0.recordedAt < $1.recordedAt }
            .map { TrendPoint(id: $0.id, date: $0.recordedAt, value: $0.average * 10) }
    }

    /// Wellness composite: combine sleep, mood, soreness (inverted), RPE (inverted) → 0..100.
    public func wellnessTrend(days: Int = 90) -> [TrendPoint] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 3600)
        return wellness
            .filter { $0.recordedAt >= cutoff }
            .sorted { $0.recordedAt < $1.recordedAt }
            .map { entry in
                let sleep = min(1.0, entry.sleepHours / 9.0)
                let mood = Double(entry.mood) / 5.0
                let soreness = 1.0 - Double(entry.soreness - 1) / 4.0
                let rpe = 1.0 - Double(entry.rpePreviousSession - 1) / 9.0
                let value = (sleep + mood + soreness + rpe) / 4.0 * 100
                return TrendPoint(id: entry.id, date: entry.recordedAt, value: value)
            }
    }

    public func wellnessStreak() -> Int {
        let cal = Calendar.current
        let dates = wellness.map { cal.startOfDay(for: $0.recordedAt) }
        var streak = 0
        var cursor = cal.startOfDay(for: Date())
        while dates.contains(cursor) {
            streak += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streak
    }
}

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
    public private(set) var physicalMetrics: [PhysicalMetric] = []
    public private(set) var technicalSkills: [TechnicalSkill] = []
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
            physicalMetrics = try await repository.physicalMetrics(athleteID: athleteID)
            technicalSkills = try await repository.technicalSkills(athleteID: athleteID)
            wellness = try await repository.wellness(athleteID: athleteID, since: since)
        } catch {
            print("PerformanceEntryStore.load:", error)
        }
    }

    public func save(metric: PhysicalMetric) async {
        do {
            try await repository.upsert(metric: metric)
            await load(athleteID: metric.athleteID)
        } catch {
            print("PerformanceEntryStore.save metric:", error)
        }
    }

    public func deleteMetric(id: EntityID, athleteID: EntityID) async {
        do {
            try await repository.deletePhysicalMetric(id: id)
            await load(athleteID: athleteID)
        } catch {
            print("PerformanceEntryStore.delete metric:", error)
        }
    }

    public func save(skill: TechnicalSkill) async {
        do {
            try await repository.upsert(skill: skill)
            await load(athleteID: skill.athleteID)
        } catch {
            print("PerformanceEntryStore.save skill:", error)
        }
    }

    public func deleteSkill(id: EntityID, athleteID: EntityID) async {
        do {
            try await repository.deleteTechnicalSkill(id: id)
            await load(athleteID: athleteID)
        } catch {
            print("PerformanceEntryStore.delete skill:", error)
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

    /// Bucket physical metrics by recording day and emit a 0..100 composite per
    /// day (last `days` days). Days with no measurements do not produce points.
    public func physicalTrend(days: Int = 90) -> [TrendPoint] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 3600)
        let cal = Calendar.current
        let recent = physicalMetrics.filter { $0.recordedAt >= cutoff }
        let byDay = Dictionary(grouping: recent) { cal.startOfDay(for: $0.recordedAt) }
        return byDay
            .map { day, metrics in
                TrendPoint(date: day, value: GradingEngine.physicalCompositeScore(metrics))
            }
            .sorted { $0.date < $1.date }
    }

    /// Bucket technical skills by recording day; emit average (form+app)/2 × 10
    /// per day (last `days` days) so the trend line lives on the same 0..100
    /// scale as the physical composite.
    public func technicalTrend(days: Int = 90) -> [TrendPoint] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 3600)
        let cal = Calendar.current
        let recent = technicalSkills.filter { $0.recordedAt >= cutoff }
        let byDay = Dictionary(grouping: recent) { cal.startOfDay(for: $0.recordedAt) }
        return byDay
            .map { day, skills in
                let avg = skills.map(\.averageScore).reduce(0, +) / Double(skills.count)
                return TrendPoint(date: day, value: avg * 10)
            }
            .sorted { $0.date < $1.date }
    }

    /// Wellness composite (0..100). Combines six signals on a 1..10 scale —
    /// sleep, mood, motivation are higher-is-better; soreness, stress, RPE
    /// are inverted (higher = worse). Sleep is mapped from hours to 0..1
    /// against a 9-hour benchmark.
    public func wellnessTrend(days: Int = 90) -> [TrendPoint] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 3600)
        return wellness
            .filter { $0.recordedAt >= cutoff }
            .sorted { $0.recordedAt < $1.recordedAt }
            .map { entry in
                let sleep = min(1.0, entry.sleepHours / 9.0)
                let mood = Double(entry.mood) / 10.0
                let motivation = Double(entry.motivation) / 10.0
                let soreness = 1.0 - Double(entry.soreness - 1) / 9.0
                let stress = 1.0 - Double(entry.stress - 1) / 9.0
                let rpe = 1.0 - Double(entry.rpePreviousSession - 1) / 9.0
                let value = (sleep + mood + motivation + soreness + stress + rpe) / 6.0 * 100
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

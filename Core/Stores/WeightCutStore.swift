import Foundation
import Observation

@Observable @MainActor
public final class WeightCutStore {
    public private(set) var entries: [WeightCutEntry] = []
    public private(set) var isLoading = false

    private let repository: any Repository

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func load(registrationID: EntityID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await repository.weightCutHistory(registrationID: registrationID)
        } catch {
            print("WeightCutStore.load:", error)
        }
    }

    public func log(registrationID: EntityID, currentKg: Double, targetKg: Double, notes: String? = nil) async {
        let entry = WeightCutEntry(
            registrationID: registrationID,
            recordedAt: Date(),
            currentKg: currentKg,
            targetKg: targetKg,
            notes: notes
        )
        do {
            try await repository.upsert(weightCut: entry)
            await load(registrationID: registrationID)
        } catch {
            print("WeightCutStore.log:", error)
        }
    }

    public var trend: [(date: Date, value: Double)] {
        entries.sorted { $0.recordedAt < $1.recordedAt }
            .map { ($0.recordedAt, $0.currentKg) }
    }

    public var targetKg: Double? { entries.first?.targetKg }
}

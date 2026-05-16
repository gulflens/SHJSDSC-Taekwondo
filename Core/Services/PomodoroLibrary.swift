import Foundation

/// Local-only library of saved pomodoro plans, stored as JSON in UserDefaults.
/// Per-device — no cloud sync. Two coaches on different devices keep their
/// own libraries; that's a known limitation but matches the feature ask
/// (single-coach drills, not shared club playlists).
public actor PomodoroLibrary {
    public static let shared = PomodoroLibrary()

    private let key = "trainingPomodoros.v1"
    private let defaults = UserDefaults.standard

    public init() {}

    public func all() -> [TrainingPomodoro] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([TrainingPomodoro].self, from: data)) ?? []
    }

    public func save(_ plan: TrainingPomodoro) {
        var current = all()
        if let i = current.firstIndex(where: { $0.id == plan.id }) {
            current[i] = plan
        } else {
            current.append(plan)
        }
        persist(current)
    }

    public func delete(id: EntityID) {
        let filtered = all().filter { $0.id != id }
        persist(filtered)
    }

    private func persist(_ plans: [TrainingPomodoro]) {
        guard let data = try? JSONEncoder().encode(plans) else { return }
        defaults.set(data, forKey: key)
    }
}

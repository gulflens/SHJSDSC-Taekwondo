import Foundation
import SwiftUI
import UserNotifications

public struct LocalNotificationScheduler: NotificationScheduler {

    public init() {}

    public func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("LocalNotificationScheduler.requestAuthorization:", error)
            return false
        }
    }

    public func scheduleLocal(id: String, title: String, body: String, fireAt: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let interval = max(1, fireAt.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
    }

    public func cancel(id: String) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}

private struct NotificationSchedulerKey: EnvironmentKey {
    static let defaultValue: any NotificationScheduler = LocalNotificationScheduler()
}

extension EnvironmentValues {
    public var notificationScheduler: any NotificationScheduler {
        get { self[NotificationSchedulerKey.self] }
        set { self[NotificationSchedulerKey.self] = newValue }
    }
}

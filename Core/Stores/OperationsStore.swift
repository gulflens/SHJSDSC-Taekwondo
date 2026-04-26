import Foundation
import Observation

@Observable @MainActor
public final class OperationsStore {
    public private(set) var announcements: [Announcement] = []
    public private(set) var rsvpsByAnnouncement: [EntityID: [AnnouncementRSVP]] = [:]
    public private(set) var isLoading = false

    private let repository: any Repository

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func load(audience: AnnouncementAudience? = nil) async {
        isLoading = true
        defer { isLoading = false }
        do {
            announcements = try await repository.announcements(audience: audience)
            var bucket: [EntityID: [AnnouncementRSVP]] = [:]
            for a in announcements {
                bucket[a.id] = try await repository.rsvps(announcementID: a.id)
            }
            rsvpsByAnnouncement = bucket
        } catch {
            print("OperationsStore.load:", error)
        }
    }

    public func grouped() -> [(date: Date, items: [Announcement])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: announcements) { cal.startOfDay(for: $0.publishedAt) }
        return groups
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, items: $0.value.sorted { $0.publishedAt > $1.publishedAt }) }
    }

    public func unreadCount(for userID: EntityID) -> Int {
        // Demo proxy: "unread" = announcement published in last 7 days that this
        // user hasn't RSVP'd to (when RSVP required) or hasn't viewed.
        let cutoff = Date().addingTimeInterval(-7 * 24 * 3600)
        return announcements.filter { a in
            guard a.publishedAt >= cutoff else { return false }
            if a.requiresRSVP {
                return !(rsvpsByAnnouncement[a.id]?.contains { $0.userID == userID } ?? false)
            }
            return true
        }.count
    }

    public func publish(_ announcement: Announcement) async {
        do {
            try await repository.upsert(announcement: announcement)
            await load()
        } catch {
            print("OperationsStore.publish:", error)
        }
    }

    public func rsvp(announcementID: EntityID, userID: EntityID, response: RSVPResponse) async {
        let r = AnnouncementRSVP(announcementID: announcementID, userID: userID, response: response)
        do {
            try await repository.upsert(rsvp: r)
            rsvpsByAnnouncement[announcementID] = try await repository.rsvps(announcementID: announcementID)
        } catch {
            print("OperationsStore.rsvp:", error)
        }
    }

    public func myResponse(announcementID: EntityID, userID: EntityID) -> RSVPResponse? {
        rsvpsByAnnouncement[announcementID]?.first { $0.userID == userID }?.response
    }
}

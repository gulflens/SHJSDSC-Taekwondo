import SwiftUI

public struct AthleteTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            AthleteHomeView()
                .tabItem { Label("tab.home", systemImage: "house.fill") }

            NavigationStack {
                MyScheduleView()
            }
            .tabItem { Label("tab.schedule", systemImage: "calendar") }

            NavigationStack {
                AthleteSelfProfileView()
            }
            .tabItem { Label("tab.profile", systemImage: "person.crop.circle.fill") }

            NavigationStack {
                AnnouncementsView()
            }
            .tabItem { Label("tab.announcements", systemImage: "megaphone") }
        }
    }
}

private struct AthleteSelfProfileView: View {
    @Environment(AppSession.self) private var session
    @State private var athlete: Athlete?

    var body: some View {
        Group {
            if let athlete {
                AthleteDetailView(athlete: athlete)
            } else {
                ProgressView()
            }
        }
        .task { await load() }
    }

    private func load() async {
        guard let userID = session.currentUser?.id else { return }
        do {
            athlete = try await session.repository.athlete(id: userID)
        } catch {
            print("AthleteSelfProfileView.load:", error)
        }
    }
}

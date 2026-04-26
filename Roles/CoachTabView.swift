import SwiftUI

public struct CoachTabView: View {
    @Environment(AppSession.self) private var session

    public init() {}

    public var body: some View {
        TabView {
            CoachHomeView()
                .tabItem { Label("tab.home", systemImage: "house.fill") }

            NavigationStack {
                AttendanceListView()
            }
            .tabItem { Label("tab.classes", systemImage: "list.clipboard.fill") }

            NavigationStack {
                AthleteListView(scope: .myAthletes(coachID: session.currentUser?.id ?? UUID()))
            }
            .tabItem { Label("tab.athletes", systemImage: "person.3.fill") }

            NavigationStack {
                AnnouncementsView()
            }
            .tabItem { Label("tab.announcements", systemImage: "megaphone") }

            MoreView()
                .tabItem { Label("tab.more", systemImage: "ellipsis.circle.fill") }
        }
    }
}

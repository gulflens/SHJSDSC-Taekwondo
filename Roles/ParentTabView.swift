import SwiftUI

public struct ParentTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            ParentHomeView()
                .tabItem { Label("tab.home", systemImage: "house.fill") }

            NavigationStack {
                MyScheduleView()
            }
            .tabItem { Label("tab.schedule", systemImage: "calendar") }

            NavigationStack {
                AnnouncementsView()
            }
            .tabItem { Label("tab.announcements", systemImage: "megaphone") }

            MoreView()
                .tabItem { Label("tab.more", systemImage: "ellipsis.circle.fill") }
        }
    }
}

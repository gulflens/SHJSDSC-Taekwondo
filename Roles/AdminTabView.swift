import SwiftUI

public struct AdminTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            HQDashboardView()
                .tabItem { Label("tab.overview", systemImage: "square.grid.2x2.fill") }

            NavigationStack {
                BranchListView()
            }
            .tabItem { Label("tab.branches", systemImage: "building.2.fill") }

            NavigationStack {
                AthleteListView(scope: .all)
            }
            .tabItem { Label("tab.people", systemImage: "person.3.fill") }

            NavigationStack {
                TournamentListView()
            }
            .tabItem { Label("tab.tournaments", systemImage: "rosette") }

            MoreView()
                .tabItem { Label("tab.more", systemImage: "ellipsis.circle.fill") }
        }
    }
}

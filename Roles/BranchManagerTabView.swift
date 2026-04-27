import SwiftUI

public struct BranchManagerTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            BranchManagerHomeView()
                .tabItem { Label("manager.dashboard", systemImage: "square.grid.2x2.fill") }

            NavigationStack {
                BranchListView()
            }
            .tabItem { Label("tab.branches", systemImage: "building.2.fill") }

            NavigationStack {
                AthleteListView(scope: .all)
            }
            .tabItem { Label("tab.athletes", systemImage: "person.3.fill") }

            NavigationStack {
                CoachListView()
            }
            .tabItem { Label("tab.coaches", systemImage: "figure.taekwondo") }

            MoreView()
                .tabItem { Label("tab.more", systemImage: "ellipsis.circle.fill") }
        }
    }
}

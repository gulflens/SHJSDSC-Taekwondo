import SwiftUI

public struct TechnicalDirectorTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            TDDashboardView()
                .tabItem { Label("tab.overview", systemImage: "square.grid.2x2.fill") }

            NavigationStack {
                BranchHeatMapView()
            }
            .tabItem { Label("tab.branches", systemImage: "building.2.fill") }

            NavigationStack {
                AthleteListView(scope: .all)
            }
            .tabItem { Label("tab.athletes", systemImage: "person.3.fill") }

            NavigationStack {
                CoachListView()
            }
            .tabItem { Label("tab.coaches", systemImage: "person.crop.rectangle.stack.fill") }

            NavigationStack {
                TournamentListView()
            }
            .tabItem { Label("tab.tournaments", systemImage: "rosette") }
        }
    }
}

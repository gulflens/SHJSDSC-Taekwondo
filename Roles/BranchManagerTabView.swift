import SwiftUI

public struct BranchManagerTabView: View {
    public init() {}

    public var body: some View {
        AdaptiveNavigationShell(
            appTitle: "manager.dashboard",
            items: [
                SidebarItem("dashboard",       titleKey: "manager.dashboard",      icon: "square.grid.2x2.fill"),
                SidebarItem("branches",        titleKey: "tab.branches",           icon: "building.2.fill"),
                SidebarItem("athletes",        titleKey: "tab.athletes",           icon: "person.3.fill"),
                SidebarItem("coaches",         titleKey: "tab.coaches",            icon: "figure.taekwondo"),
                SidebarItem("tournaments",     titleKey: "tab.tournaments",        icon: "rosette"),
                SidebarItem("announcements",   titleKey: "tab.announcements",      icon: "megaphone.fill"),
                SidebarItem("certifications",  titleKey: "tab.certifications",     icon: "checkmark.shield.fill"),
                SidebarItem("settings",        titleKey: "settings.title",         icon: "gearshape.fill")
            ],
            profileItem: SidebarItem("profile", titleKey: "tab.profile", icon: "person.crop.circle.fill")
        ) { id in
            switch id {
            case "dashboard":      BranchManagerHomeView()
            case "branches":       BranchesOverviewView()
            case "athletes":       AthleteListView(scope: .all)
            case "coaches":        CoachListView()
            case "tournaments":    TournamentListView()
            case "announcements":  AnnouncementsView()
            case "certifications": CertificationsListView()
            case "settings":       MoreView()
            case "profile":        MyProfileView()
            default:               EmptyView()
            }
        }
    }
}

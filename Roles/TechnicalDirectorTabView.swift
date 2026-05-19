import SwiftUI

public struct TechnicalDirectorTabView: View {
    public init() {}

    /// Sidebar items. Poomsae Analysis (Stage 2.6.a) is iPad-only, so it is
    /// appended conditionally rather than placed in the literal.
    private var navItems: [SidebarItem] {
        var items: [SidebarItem] = [
            SidebarItem("overview",        titleKey: "tab.overview",         icon: "square.grid.2x2.fill"),
            SidebarItem("branches",        titleKey: "tab.branches",         icon: "building.2.fill"),
            SidebarItem("athletes",        titleKey: "tab.athletes",         icon: "person.3.fill"),
            SidebarItem("coaches",         titleKey: "tab.coaches",          icon: "person.crop.rectangle.stack.fill"),
            SidebarItem("development",     titleKey: "tab.development",      icon: "figure.taekwondo"),
            SidebarItem("tournaments",     titleKey: "tab.tournaments",      icon: "rosette"),
            SidebarItem("grading",         titleKey: "tab.grading",          icon: "medal.fill"),
            SidebarItem("announcements",   titleKey: "tab.announcements",    icon: "megaphone.fill"),
            SidebarItem("drills",          titleKey: "drills.tab.title",     icon: "list.clipboard.fill")
        ]
        #if os(iOS)
        items.append(SidebarItem("poomsae", titleKey: "Poomsae Analysis", icon: "figure.martial.arts"))
        #endif
        items.append(contentsOf: [
            SidebarItem("certifications",  titleKey: "tab.certifications",   icon: "checkmark.shield.fill"),
            SidebarItem("users",           titleKey: "users.title",          icon: "person.2.fill"),
            SidebarItem("settings",        titleKey: "settings.title",       icon: "gearshape.fill")
        ])
        return items
    }

    public var body: some View {
        AdaptiveNavigationShell(
            appTitle: "tab.overview",
            items: navItems,
            profileItem: SidebarItem("profile", titleKey: "tab.profile", icon: "person.crop.circle.fill")
        ) { id in
            switch id {
            case "overview":       BranchPerformanceView()
            case "branches":       TDDashboardView()
            case "athletes":       AthleteListView(scope: .all)
            case "coaches":        CoachListView()
            case "development":    CoachingDevelopmentView()
            case "tournaments":    TournamentListView()
            case "grading":        GradingDashboardView()
            case "announcements":  AnnouncementsView()
            case "drills":         DrillsAndTimerView()
            #if os(iOS)
            case "poomsae":        PoomsaeRecordingListView()
            #endif
            case "certifications": CertificationsListView()
            case "users":          UsersConsoleView()
            case "settings":       MoreView()
            case "profile":        MyProfileView()
            default:               EmptyView()
            }
        }
    }
}

import SwiftUI

public struct DeveloperTabView: View {
    public init() {}

    public var body: some View {
        AdaptiveNavigationShell(
            appTitle: "tab.overview",
            items: [
                SidebarItem("overview",        titleKey: "tab.overview",         icon: "square.grid.2x2.fill"),
                SidebarItem("branches",        titleKey: "tab.branches",         icon: "building.2.fill"),
                SidebarItem("athletes",        titleKey: "tab.athletes",         icon: "person.3.fill"),
                SidebarItem("coaches",         titleKey: "tab.coaches",          icon: "person.crop.rectangle.stack.fill"),
                SidebarItem("tournaments",     titleKey: "tab.tournaments",      icon: "rosette"),
                SidebarItem("grading",         titleKey: "tab.grading",          icon: "medal.fill"),
                SidebarItem("announcements",   titleKey: "tab.announcements",    icon: "megaphone.fill"),
                SidebarItem("drills",          titleKey: "drills.tab.title",     icon: "list.clipboard.fill"),
                SidebarItem("certifications",  titleKey: "tab.certifications",   icon: "checkmark.shield.fill"),
                SidebarItem("audit",           titleKey: "audit.title",          icon: "list.bullet.rectangle"),
                SidebarItem("users",           titleKey: "users.title",          icon: "person.2.fill"),
                SidebarItem("settings",        titleKey: "settings.title",       icon: "gearshape.fill")
            ],
            profileItem: SidebarItem("profile", titleKey: "tab.profile", icon: "person.crop.circle.fill")
        ) { id in
            switch id {
            case "overview":       BranchPerformanceView()
            case "branches":       HQDashboardView()
            case "athletes":       AthleteListView(scope: .all)
            case "coaches":        CoachListView()
            case "tournaments":    TournamentListView()
            case "grading":        GradingDashboardView()
            case "announcements":  AnnouncementsView()
            case "drills":         DrillsAndTimerView()
            case "certifications": CertificationsListView()
            case "audit":          AuditLogView()
            case "users":          UsersConsoleView()
            case "settings":       MoreView()
            case "profile":        MyProfileView()
            default:               EmptyView()
            }
        }
    }
}

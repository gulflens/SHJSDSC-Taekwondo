import SwiftUI

public struct CoachTabView: View {
    @Environment(AppSession.self) private var session

    public init() {}

    /// Sidebar items. Poomsae Analysis (Stage 2.6.a) is iPad-only, so it is
    /// appended conditionally rather than placed in the literal.
    private var navItems: [SidebarItem] {
        var items: [SidebarItem] = [
            SidebarItem("home",            titleKey: "tab.home",               icon: "house.fill"),
            SidebarItem("classes",         titleKey: "tab.classes",            icon: "list.clipboard.fill"),
            SidebarItem("athletes",        titleKey: "tab.athletes",           icon: "person.3.fill"),
            SidebarItem("announcements",   titleKey: "tab.announcements",      icon: "megaphone.fill"),
            SidebarItem("drills",          titleKey: "drills.tab.title",       icon: "list.clipboard.fill")
        ]
        #if os(iOS)
        items.append(SidebarItem("poomsae", titleKey: "Poomsae Analysis", icon: "figure.martial.arts"))
        #endif
        items.append(contentsOf: [
            SidebarItem("certifications",  titleKey: "tab.certifications",     icon: "checkmark.shield.fill"),
            SidebarItem("settings",        titleKey: "settings.title",         icon: "gearshape.fill")
        ])
        return items
    }

    public var body: some View {
        AdaptiveNavigationShell(
            appTitle: "tab.home",
            items: navItems,
            profileItem: SidebarItem("profile", titleKey: "tab.profile", icon: "person.crop.circle.fill")
        ) { id in
            switch id {
            case "home":           CoachHomeView()
            case "classes":        AttendanceListView()
            case "athletes":       AthleteListView(scope: .myAthletes(coachID: session.currentUser?.id ?? UUID()))
            case "announcements":  AnnouncementsView()
            case "drills":         DrillsAndTimerView()
            #if os(iOS)
            case "poomsae":        PoomsaeRecordingListView()
            #endif
            case "certifications": CertificationsListView()
            case "settings":       MoreView()
            case "profile":        MyProfileView()
            default:               EmptyView()
            }
        }
    }
}

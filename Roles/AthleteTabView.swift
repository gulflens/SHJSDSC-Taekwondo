import SwiftUI

public struct AthleteTabView: View {
    public init() {}

    public var body: some View {
        AdaptiveNavigationShell(
            appTitle: "tab.home",
            items: [
                SidebarItem("home",          titleKey: "tab.home",               icon: "house.fill"),
                SidebarItem("schedule",      titleKey: "tab.schedule",           icon: "calendar"),
                SidebarItem("announcements", titleKey: "tab.announcements",      icon: "megaphone.fill"),
                SidebarItem("settings",      titleKey: "settings.title",         icon: "gearshape.fill")
            ],
            profileItem: SidebarItem("profile", titleKey: "tab.profile", icon: "person.crop.circle.fill")
        ) { id in
            switch id {
            case "home":          AthleteHomeView()
            case "schedule":      MyScheduleView()
            case "announcements": AnnouncementsView()
            case "settings":      MoreView()
            case "profile":       MyProfileView()
            default:              EmptyView()
            }
        }
    }
}

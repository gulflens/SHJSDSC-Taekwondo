import SwiftUI

/// Premium adaptive navigation shell used by every role's top-level surface.
/// Replaces the green-bar `SidebarShell` from Stage 1.5.
///
/// **iPhone (compact size class):** native `TabView` with up to 5 visible
/// tabs and the rest folded into a "More" tab. The bar uses the system's
/// translucent material so it floats over content.
///
/// **iPad (regular size class):** `NavigationSplitView` with a layered,
/// floating-style sidebar (rounded corner pill rows, thin-material
/// background). Auto-collapses to icon-only as soon as the user picks a
/// destination or taps anywhere in the detail pane; expand again via the
/// header toggle.
///
/// Same public API as `SidebarShell` so role tab views (BranchManagerTabView,
/// AdminTabView, etc.) can swap the wrapper with no logic change.
public struct AdaptiveNavigationShell<Detail: View>: View {
    public let appTitle: LocalizedStringKey
    public let items: [SidebarItem]
    public let profileItem: SidebarItem?
    @ViewBuilder public let detail: (String) -> Detail

    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass
    /// macOS UI Zoom factor. 1.0 on iOS/iPadOS so those layouts are untouched;
    /// on macOS it widens the sidebar column and icon boxes so the chrome
    /// keeps pace with the zoomed text.
    @Environment(\.uiScale) private var uiScale
    @State private var selection: String?
    /// Sidebar collapse state on iPad. Persists across launches so HQ users
    /// who prefer the icon-only mode get it back next time. Keyed per-app
    /// (not per-role) — switching roles in demo mode preserves it.
    @AppStorage("nav.sidebar.collapsed") private var isSidebarCollapsed: Bool = false
    /// When pinned the sidebar stays expanded — `collapseSidebarIfExpanded()`
    /// becomes a no-op, so tapping a row or the detail pane no longer folds
    /// it to icon-only. Persisted per-app like the collapse state.
    @AppStorage("nav.sidebar.pinned") private var isSidebarPinned: Bool = false

    /// First 4 items become bottom tabs on iPhone. Overflow folds into a More
    /// tab. Tune by re-ordering the items list in the role tab view.
    private let primaryCompactTabCount = 4

    /// Width of the sidebar in collapsed (icon-only) and expanded states.
    private let collapsedSidebarWidth: CGFloat = 72
    private let expandedSidebarIdeal: CGFloat = 280

    public init(
        appTitle: LocalizedStringKey,
        items: [SidebarItem],
        profileItem: SidebarItem? = nil,
        @ViewBuilder detail: @escaping (String) -> Detail
    ) {
        self.appTitle = appTitle
        self.items = items
        self.profileItem = profileItem
        self.detail = detail
        _selection = State(initialValue: items.first?.id)
    }

    public var body: some View {
        Group {
            if sizeClass == .regular {
                regularShell
            } else {
                compactShell
            }
        }
    }

    // MARK: - iPhone: TabView

    private var compactShell: some View {
        let primary = Array(items.prefix(primaryCompactTabCount))
        let overflow = Array(items.dropFirst(primaryCompactTabCount))
        return TabView(selection: compactSelectionBinding(fallback: primary.first?.id ?? "")) {
            primaryTabs(primary)
            moreTab(overflow: overflow)
        }
        .tint(Color.accentColor)
    }

    private func compactSelectionBinding(fallback: String) -> Binding<String> {
        Binding(
            get: { selection ?? fallback },
            set: { selection = $0 }
        )
    }

    @ViewBuilder
    private func primaryTabs(_ primary: [SidebarItem]) -> some View {
        ForEach(primary) { item in
            tabRoot(for: item)
                .tabItem {
                    Label(item.titleKey, systemImage: item.systemIcon)
                }
                .tag(item.id)
        }
    }

    @ViewBuilder
    private func moreTab(overflow: [SidebarItem]) -> some View {
        if !overflow.isEmpty || profileItem != nil {
            MoreTabRoot(
                items: overflow,
                profileItem: profileItem,
                detail: detail,
                selection: $selection
            )
            .tabItem {
                Label("nav.more", systemImage: "ellipsis.circle.fill")
            }
            .tag("__more__")
        }
    }

    @ViewBuilder
    private func tabRoot(for item: SidebarItem) -> some View {
        NavigationStack {
            detail(item.id)
                .background(Color.appBackground.ignoresSafeArea())
                .navigationTitle(Text(item.titleKey))
                .appNavigationChrome()
        }
    }

    // MARK: - iPad: NavigationSplitView with layered sidebar

    private var regularShell: some View {
        NavigationSplitView {
            sidebarContent
                .navigationSplitViewColumnWidth(
                    min: (isSidebarCollapsed ? collapsedSidebarWidth : 240) * uiScale,
                    ideal: (isSidebarCollapsed ? collapsedSidebarWidth : expandedSidebarIdeal) * uiScale,
                    max: (isSidebarCollapsed ? collapsedSidebarWidth : 340) * uiScale
                )
        } detail: {
            detailContent
                .simultaneousGesture(
                    TapGesture().onEnded { collapseSidebarIfExpanded() }
                )
        }
        .navigationSplitViewStyle(.balanced)
    }

    /// Auto-collapses the iPad sidebar to icon-only the moment the user
    /// engages with anything outside it (sidebar row tap or detail-pane tap).
    /// Sets the value directly — the implicit `.animation(.easeInOut, value:
    /// isSidebarCollapsed)` modifier on `sidebarContent` drives the animation,
    /// so no `withAnimation` wrap (avoids double-animation with the modifier).
    /// No-op when already collapsed, or when the user has pinned the sidebar.
    private func collapseSidebarIfExpanded() {
        guard !isSidebarPinned, !isSidebarCollapsed else { return }
        isSidebarCollapsed = true
    }

    private var sidebarContent: some View {
        VStack(spacing: 0) {
            sidebarHeader
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(items) { item in
                        sidebarRow(item)
                    }
                }
                .padding(.horizontal, isSidebarCollapsed ? 8 : 12)
                .padding(.top, 8)
            }
            if let profileItem {
                Divider().opacity(0.4)
                sidebarRow(profileItem, isProfile: true)
                    .padding(.horizontal, isSidebarCollapsed ? 8 : 12)
                    .padding(.vertical, 8)
            }
        }
        .background(Color.sidebarBackground.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .animation(.easeInOut(duration: 0.22), value: isSidebarCollapsed)
    }

    @ViewBuilder
    private var sidebarHeader: some View {
        if isSidebarCollapsed {
            // Centered collapse-toggle, no app title visible.
            VStack(spacing: 0) {
                sidebarToggleButton
                    .padding(.top, 24)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
        } else {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appTitle)
                        .font(.system(size: 17 * uiScale, weight: .bold))
                        .foregroundStyle(Color.sidebarForeground)
                        .lineLimit(1)
                    Text("nav.console_subtitle")
                        .font(.system(size: 11 * uiScale))
                        .foregroundStyle(Color.sidebarForeground.opacity(0.55))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                sidebarPinButton
                sidebarToggleButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 12)
        }
    }

    private var sidebarToggleButton: some View {
        Button {
            isSidebarCollapsed.toggle()
            // A collapsed sidebar can't be "pinned open" — collapsing unpins.
            if isSidebarCollapsed { isSidebarPinned = false }
        } label: {
            Image(systemName: isSidebarCollapsed ? "sidebar.right" : "sidebar.left")
                .font(.system(size: 14 * uiScale, weight: .semibold))
                .foregroundStyle(Color.sidebarForeground.opacity(0.7))
                .frame(width: 32 * uiScale, height: 32 * uiScale)
                .background(Color.sidebarForeground.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(isSidebarCollapsed ? "nav.sidebar.expand" : "nav.sidebar.collapse"))
        .help(Text(isSidebarCollapsed ? "nav.sidebar.expand" : "nav.sidebar.collapse"))
    }

    /// Pin toggle — only shown in the expanded header. Pinning keeps the
    /// sidebar from auto-collapsing when the user taps a row or the detail
    /// pane; it also force-expands in case the state was somehow collapsed.
    private var sidebarPinButton: some View {
        Button {
            isSidebarPinned.toggle()
            if isSidebarPinned { isSidebarCollapsed = false }
        } label: {
            Image(systemName: isSidebarPinned ? "pin.fill" : "pin")
                .font(.system(size: 13 * uiScale, weight: .semibold))
                .foregroundStyle(isSidebarPinned ? Color.accentColor : Color.sidebarForeground.opacity(0.7))
                .frame(width: 32 * uiScale, height: 32 * uiScale)
                .background(
                    (isSidebarPinned ? Color.accentColor.opacity(0.15) : Color.sidebarForeground.opacity(0.08)),
                    in: Circle()
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(isSidebarPinned ? "nav.sidebar.unpin" : "nav.sidebar.pin"))
        .help(Text(isSidebarPinned ? "nav.sidebar.unpin" : "nav.sidebar.pin"))
    }

    private func sidebarRow(_ item: SidebarItem, isProfile: Bool = false) -> some View {
        let isSelected = selection == item.id
        return Button {
            selection = item.id
            collapseSidebarIfExpanded()
        } label: {
            HStack(spacing: 12) {
                rowIcon(item, isSelected: isSelected, isProfile: isProfile)
                if !isSidebarCollapsed {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.titleKey)
                            .font(.system(size: 14 * uiScale, weight: isSelected ? .semibold : .medium))
                            .foregroundStyle(Color.sidebarForeground)
                            .lineLimit(1)
                        if isProfile, let user = session.currentUser {
                            Text(verbatim: user.fullName)
                                .font(.system(size: 11 * uiScale))
                                .foregroundStyle(Color.sidebarForeground.opacity(0.55))
                                .lineLimit(1)
                        }
                    }
                    .transition(.opacity)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, isSidebarCollapsed ? 8 : 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: isSidebarCollapsed ? .center : .leading)
            .background(rowBackground(isSelected: isSelected))
            // Make the whole tile tappable — without this only the icon and
            // label glyphs are hit-testable; the Spacer and padding are not.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(Text(item.titleKey))
    }

    @ViewBuilder
    private func rowIcon(_ item: SidebarItem, isSelected: Bool, isProfile: Bool) -> some View {
        if isProfile, let user = session.currentUser {
            Avatar(seed: user.avatarSeed, label: initials(for: user), size: 28)
        } else {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.accentColor.opacity(0.18))
                }
                Image(systemName: item.systemIcon)
                    .font(.system(size: 15 * uiScale, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.sidebarForeground.opacity(0.7))
            }
            .frame(width: 32 * uiScale, height: 32 * uiScale)
        }
    }

    @ViewBuilder
    private func rowBackground(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
                )
        } else {
            Color.clear
        }
    }

    private func initials(for user: User) -> String {
        let parts = user.fullName.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }

    @ViewBuilder
    private var detailContent: some View {
        NavigationStack {
            Group {
                if let selection {
                    detail(selection)
                } else {
                    placeholder
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(Text(currentDetailTitle))
            .appNavigationChrome()
        }
    }

    private var currentDetailTitle: LocalizedStringKey {
        if let selection {
            if let match = items.first(where: { $0.id == selection }) {
                return match.titleKey
            }
            if let profileItem, profileItem.id == selection {
                return profileItem.titleKey
            }
        }
        return appTitle
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "sidebar.left")
                .scaledFont(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("nav.select_section")
                .scaledFont(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - More tab root (compact)

/// Used by the iPhone shell when the role has more than 4 primary destinations.
/// Renders a grouped list of overflow items + the profile footer; tapping any
/// row pushes the destination onto its own NavigationStack.
private struct MoreTabRoot<Detail: View>: View {
    let items: [SidebarItem]
    let profileItem: SidebarItem?
    @ViewBuilder let detail: (String) -> Detail
    @Binding var selection: String?

    @Environment(AppSession.self) private var session

    var body: some View {
        NavigationStack {
            List {
                if !items.isEmpty {
                    Section("nav.more.sections") {
                        ForEach(items) { item in
                            NavigationLink {
                                detail(item.id)
                                    .background(Color.appBackground.ignoresSafeArea())
                                    .navigationTitle(Text(item.titleKey))
                                    .appNavigationChrome()
                            } label: {
                                Label(item.titleKey, systemImage: item.systemIcon)
                            }
                        }
                    }
                }
                if let profileItem {
                    Section("nav.more.account") {
                        NavigationLink {
                            detail(profileItem.id)
                                .background(Color.appBackground.ignoresSafeArea())
                                .navigationTitle(Text(profileItem.titleKey))
                                .appNavigationChrome()
                        } label: {
                            HStack(spacing: 12) {
                                if let user = session.currentUser {
                                    Avatar(seed: user.avatarSeed, label: initials(for: user), size: 32)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profileItem.titleKey)
                                        .scaledFont(.body, weight: .semibold)
                                    if let user = session.currentUser {
                                        Text(verbatim: user.fullName)
                                            .scaledFont(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("nav.more")
            .appNavigationChrome()
        }
    }

    private func initials(for user: User) -> String {
        let parts = user.fullName.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }
}

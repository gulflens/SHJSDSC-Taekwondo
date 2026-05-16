import SwiftUI

/// Single entry in a sidebar. `id` is the stable key that the role view's
/// detail-builder closure switches on. Equality / hashing is by `id` only so
/// `LocalizedStringKey`'s lack of Hashable doesn't block synthesis.
public struct SidebarItem: Identifiable, Hashable {
    public let id: String
    public let titleKey: LocalizedStringKey
    public let systemIcon: String

    public init(_ id: String, titleKey: LocalizedStringKey, icon: String) {
        self.id = id
        self.titleKey = titleKey
        self.systemIcon = icon
    }

    public static func == (lhs: SidebarItem, rhs: SidebarItem) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// `NavigationSplitView`-based shell with a fly-over sidebar.
///
/// The detail pane fills the screen by default; the sidebar slides in over
/// the detail when the user taps the sidebar toggle (or swipes from the
/// leading edge). Selecting an item or tapping the detail collapses it back.
///
/// `profileItem` is rendered as a fixed footer at the bottom of the sidebar
/// column showing the current user's avatar + name + role. Tapping it routes
/// through the same detail builder via the item's `id`.
public struct SidebarShell<Detail: View>: View {
    public let appTitle: LocalizedStringKey
    public let items: [SidebarItem]
    public let profileItem: SidebarItem?
    @ViewBuilder public let detail: (String) -> Detail

    @Environment(AppSession.self) private var session
    @State private var selection: String?
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

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
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarColumn
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.prominentDetail)
        .onChange(of: selection) { _, _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                columnVisibility = .detailOnly
            }
        }
    }

    /// Title for the detail pane's nav bar — derived from whichever sidebar
    /// item (or profile footer) is currently selected. Centralising this here
    /// removes the need for every routed view to set its own
    /// `.navigationTitle(...)`, which was producing a redundant secondary
    /// header inside the detail pane.
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

    private var detailColumn: some View {
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

    private var sidebarColumn: some View {
        let list = List(items, selection: $selection) { item in
            NavigationLink(value: item.id) {
                Label(item.titleKey, systemImage: item.systemIcon)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.sidebarForeground)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.sidebarBackground)
        }
        .listStyle(.plain)
        .tint(.white)
        .foregroundStyle(Color.sidebarForeground)
        .scrollContentBackground(.hidden)
        .background(Color.sidebarBackground.ignoresSafeArea())

        let titled = list
            .navigationTitle(appTitle)
            .appNavigationChrome()

        let withFooter = titled.safeAreaInset(edge: .bottom, spacing: 0) {
            if let profileItem {
                profileFooter(profileItem)
            }
        }

        return withFooter
    }

    private func profileFooter(_ item: SidebarItem) -> some View {
        let isSelected = selection == item.id
        return Button {
            selection = item.id
        } label: {
            HStack(spacing: 12) {
                if let user = session.currentUser {
                    Avatar(seed: user.avatarSeed, label: initials(for: user), size: 30)
                } else {
                    Image(systemName: item.systemIcon)
                        .scaledFont(.body, weight: .semibold)
                        .foregroundStyle(Color.sidebarForeground)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.titleKey)
                        .scaledFont(.body, weight: .semibold)
                        .foregroundStyle(Color.sidebarForeground)
                    if let user = session.currentUser {
                        Text(verbatim: user.fullName)
                            .scaledFont(.caption2)
                            .lineLimit(1)
                            .foregroundStyle(Color.sidebarForeground.opacity(0.75))
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.white.opacity(0.18) : Color.sidebarBackground)
            .overlay(alignment: .top) {
                Color.white.opacity(0.25).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(item.titleKey))
    }

    private func initials(for user: User) -> String {
        let parts = user.fullName.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
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

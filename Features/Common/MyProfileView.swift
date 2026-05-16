import SwiftUI

/// Federation-grade profile dashboard. Replaces the role-routed account
/// summary with a single layered surface used by every signed-in role
/// (athletes/coaches still have their dossier views — those live elsewhere
/// now). Layout follows `References/Profile page dashboard overview.png`:
/// a soft-gradient hero with bilingual identity + 2×2 status grid, then
/// Account Details / Security / Preferences cards in a two-column flow on
/// iPad (stacked on iPhone), and an Activity Summary KPI strip + Quick
/// Actions tile grid at the bottom.
public struct MyProfileView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var hSize

    @State private var primaryBranch: Branch?
    @State private var recentActionsCount: Int = 0
    @State private var exportShareURL: URL?
    @State private var exporting = false
    @State private var showingSignOutConfirm = false
    @State private var showingEditAccount = false

    public init() {}

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        ScrollView {
            if let user = session.currentUser {
                content(for: user)
                    .padding(.horizontal, isWide ? 20 : 14)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
            } else {
                placeholder
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(Text("profile.title"))
        .toolbar { editToolbar }
        .confirmationDialog(
            Text("profile.sign_out_confirm"),
            isPresented: $showingSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("settings.sign_out", role: .destructive) {
                Task { await session.signOut() }
            }
            Button("action.cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingEditAccount) {
            EditMyAccountView()
                .onDisappear { Task { await reloadDerived() } }
        }
        .task { await reloadDerived() }
    }

    @ViewBuilder
    private func content(for user: User) -> some View {
        VStack(spacing: 16) {
            ProfileHeroCard(
                user: user,
                primaryBranch: primaryBranch,
                isWide: isWide,
                onEdit: { showingEditAccount = true }
            )
            mainGrid(for: user)
            bottomGrid(for: user)
        }
    }

    @ViewBuilder
    private func mainGrid(for user: User) -> some View {
        // Profile shows identity only. Theme / appearance / notifications /
        // security / format / dashboard preferences live in Settings — keeping
        // them here would duplicate that surface.
        accountDetailsCard(for: user)
    }

    @ViewBuilder
    private func bottomGrid(for user: User) -> some View {
        if isWide {
            HStack(alignment: .top, spacing: 16) {
                activitySummaryCard
                    .frame(maxWidth: .infinity)
                quickActionsCard(for: user)
                    .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: 16) {
                activitySummaryCard
                quickActionsCard(for: user)
            }
        }
    }

    // MARK: - Cards

    private func accountDetailsCard(for user: User) -> some View {
        SectionCard(
            "profile.section.account_details",
            icon: "person.text.rectangle",
            trailing: {
                Button {
                    showingEditAccount = true
                } label: {
                    Image(systemName: "pencil")
                        .scaledFont(.footnote, weight: .semibold)
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("profile.edit.title"))
            }
        ) {
            VStack(spacing: 0) {
                ProfileRow(label: "profile.edit.full_name", value: user.fullName.isEmpty ? "—" : user.fullName)
                ProfileRow(
                    label: "profile.edit.full_name_ar",
                    value: user.fullNameAr.isEmpty ? "—" : user.fullNameAr,
                    rtl: true
                )
                ProfileRow(label: "profile.edit.email", value: user.email ?? "—")
                ProfileRow(label: "profile.edit.phone", value: user.phone ?? "—")
                ProfileRow(label: "profile.role", chip: ProfileChip(text: NSLocalizedString(user.role.label, comment: ""), tone: .accent))
                if let branch = primaryBranch {
                    ProfileRow(
                        label: "profile.primary_branch",
                        chip: ProfileChip(text: branch.name, tone: .neutral)
                    )
                } else {
                    ProfileRow(label: "profile.primary_branch", value: "—")
                }
                ProfileRow(label: "profile.member_since", value: "—", comingSoon: true)
            }
        }
    }

    private var activitySummaryCard: some View {
        SectionCard("profile.section.activity", icon: "chart.bar.xaxis") {
            let columns = [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ]
            LazyVGrid(columns: columns, spacing: 10) {
                ActivityTile(
                    icon: "arrow.right.to.line",
                    tint: .blue,
                    label: "profile.activity.logins",
                    value: "—",
                    comingSoon: true
                )
                ActivityTile(
                    icon: "wave.3.right",
                    tint: .secondaryAccent,
                    label: "profile.activity.sessions",
                    value: "1",
                    comingSoon: true
                )
                ActivityTile(
                    icon: "list.bullet.rectangle",
                    tint: .orange,
                    label: "profile.activity.recent_actions",
                    value: "\(recentActionsCount)"
                )
                ActivityTile(
                    icon: "rosette",
                    tint: .purple,
                    label: "profile.activity.achievements",
                    value: "—",
                    comingSoon: true
                )
            }
        }
    }

    private func quickActionsCard(for user: User) -> some View {
        SectionCard("profile.section.quick_actions", icon: "bolt.fill") {
            let columns = [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ]
            LazyVGrid(columns: columns, spacing: 10) {
                QuickActionTile(
                    icon: "pencil",
                    tint: .accentColor,
                    label: "profile.edit.title"
                ) { showingEditAccount = true }

                QuickActionTile(
                    icon: exporting ? "hourglass" : "square.and.arrow.down",
                    tint: .secondaryAccent,
                    label: "settings.export_data",
                    disabled: exporting
                ) { Task { await exportMyData(for: user) } }

                QuickActionTile(
                    icon: "bell.fill",
                    tint: .orange,
                    label: "profile.prefs.notifications"
                ) { showingEditAccount = true }

                QuickActionTile(
                    icon: "rectangle.portrait.and.arrow.right",
                    tint: .red,
                    label: "settings.sign_out",
                    destructive: true
                ) { showingSignOutConfirm = true }
            }
            if let url = exportShareURL {
                ShareLink(item: url) {
                    Label("export.share", systemImage: "square.and.arrow.up")
                        .scaledFont(.footnote, weight: .semibold)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
        }
    }

    @ToolbarContentBuilder
    private var editToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showingEditAccount = true
            } label: {
                Label("profile.edit.title", systemImage: "pencil")
                    .scaledFont(.subheadline, weight: .semibold)
            }
            .tint(.accentColor)
        }
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .scaledFont(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("profile.no_record")
                .scaledFont(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Data

    private func reloadDerived() async {
        guard let user = session.currentUser else { return }
        if let branchID = user.primaryBranchID {
            do {
                primaryBranch = try await session.repository.branch(id: branchID)
            } catch {
                print("MyProfileView.loadBranch:", error)
            }
        } else {
            primaryBranch = nil
        }
        do {
            let since = Calendar.current.date(byAdding: .day, value: -30, to: Date())
            let entries = try await session.repository.entries(actor: user.id, since: since)
            recentActionsCount = entries.count
        } catch {
            print("MyProfileView.recentActions:", error)
        }
    }

    private func exportMyData(for user: User) async {
        exporting = true
        defer { exporting = false }
        do {
            let athlete = try? await session.repository.athlete(id: user.id)
            let registrations = try await session.repository.registrations(athleteID: user.id)
            let matches = try await session.repository.matches(athleteID: user.id)
            let exporter = CSVReportExporter()
            let data = exporter.exportMyData(
                user: user,
                athlete: athlete,
                registrations: registrations,
                matches: matches
            )
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("my-data.json")
            try data.write(to: url)
            exportShareURL = url
        } catch {
            print("MyProfileView.exportMyData:", error)
        }
    }

}

// MARK: - Account-detail row

private struct ProfileRow: View {
    let labelKey: LocalizedStringKey
    let trailing: AnyView
    var rtl: Bool = false
    var comingSoon: Bool = false

    init(label: LocalizedStringKey, value: String, rtl: Bool = false, comingSoon: Bool = false) {
        self.labelKey = label
        if comingSoon {
            self.trailing = AnyView(ComingSoonChip())
        } else {
            self.trailing = AnyView(
                Text(verbatim: value)
                    .scaledFont(.subheadline, weight: .medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            )
        }
        self.rtl = rtl
        self.comingSoon = comingSoon
    }

    init(label: LocalizedStringKey, chip: ProfileChip) {
        self.labelKey = label
        self.trailing = AnyView(chip)
        self.rtl = false
    }

    init<V: View>(label: LocalizedStringKey, comingSoon: Bool = false, @ViewBuilder _ content: () -> V) {
        self.labelKey = label
        if comingSoon {
            self.trailing = AnyView(ComingSoonChip())
        } else {
            self.trailing = AnyView(content())
        }
        self.rtl = false
        self.comingSoon = comingSoon
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(labelKey)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                trailing
                    .multilineTextAlignment(.trailing)
                    .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
            }
            .padding(.vertical, 11)
            .opacity(comingSoon ? 0.6 : 1)
            Divider().opacity(0.35)
        }
    }
}

private struct ProfileChip: View {
    enum Tone { case accent, neutral, success, warning }
    let text: String
    let tone: Tone

    var body: some View {
        Text(verbatim: text)
            .scaledFont(.caption, weight: .semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(bg, in: Capsule())
            .foregroundStyle(fg)
    }

    private var bg: Color {
        switch tone {
        case .accent: Color.accentColor.opacity(0.15)
        case .neutral: Color.secondary.opacity(0.12)
        case .success: Color.secondaryAccent.opacity(0.18)
        case .warning: Color.orange.opacity(0.18)
        }
    }
    private var fg: Color {
        switch tone {
        case .accent: Color.accentColor
        case .neutral: Color.primary
        case .success: Color.secondaryAccent
        case .warning: Color.orange
        }
    }
}

// MARK: - Activity / Quick Action tiles

private struct ActivityTile: View {
    let icon: String
    let tint: Color
    let label: LocalizedStringKey
    let value: String
    var comingSoon: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.15))
                Image(systemName: icon)
                    .scaledFont(.footnote, weight: .semibold)
                    .foregroundStyle(tint)
            }
            .frame(width: 30, height: 30)
            if comingSoon {
                ComingSoonChip()
            } else {
                Text(verbatim: value)
                    .scaledFont(.title3, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(.primary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Text(label)
                .scaledFont(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(comingSoon ? 0.7 : 1)
    }
}

private struct QuickActionTile: View {
    let icon: String
    let tint: Color
    let label: LocalizedStringKey
    var disabled: Bool = false
    var destructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.15))
                    Image(systemName: icon)
                        .scaledFont(.footnote, weight: .semibold)
                        .foregroundStyle(destructive ? Color.red : tint)
                }
                .frame(width: 32, height: 32)
                Text(label)
                    .scaledFont(.subheadline, weight: .semibold)
                    .foregroundStyle(destructive ? Color.red : Color.primary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
            .padding(12)
            .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.6 : 1)
    }
}

import SwiftUI

/// Premium Settings dashboard. Replaces the old grouped-form More screen
/// with a federation-grade two-column layout (Appearance/System/About on the
/// left, Notifications/Preferences/Security on the right, Developer gated for
/// the developer role).
///
/// Theme + accent + 2FA + biometric controls persist via `@AppStorage` only —
/// no live theming is wired this pass (would require touching the app root).
/// Notification toggles bind to the live `User.notificationPrefs` via the
/// session repository, so changes there are real.
public struct MoreView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.notificationScheduler) private var notificationScheduler
    @Environment(\.horizontalSizeClass) private var hSize

    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("prefs.theme") private var themePref: String = "system"
    @AppStorage("prefs.accent") private var accentPref: String = "blue"
    @AppStorage("prefs.macUIScale") private var macUIScalePref: String = "xLarge"
    @AppStorage("prefs.ipadUIScale") private var ipadUIScalePref: String = IPadUIScale.standard.rawValue
    @AppStorage("prefs.twoFactor") private var twoFactorPref: Bool = false
    @AppStorage("prefs.biometric") private var biometricPref: Bool = false
    @AppStorage("prefs.dateFormat") private var dateFormatPref: String = "DD MMM YYYY"
    @AppStorage("prefs.timeFormat") private var timeFormatPref: String = "24h"
    @AppStorage("prefs.numberFormat") private var numberFormatPref: String = "1,234.56"

    @State private var firingTest = false
    @State private var showingEditAccount = false
    @State private var showingResetConfirm = false
    @State private var search: String = ""

    public init() {}

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                mainGrid
            }
            .padding(.horizontal, isWide ? 20 : 14)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .searchable(text: $search, prompt: Text("settings.search.placeholder"))
        .toolbar { trailingMenu }
        .sheet(isPresented: $showingEditAccount) {
            EditMyAccountView()
        }
        .confirmationDialog(
            Text("settings.reset_confirm.title"),
            isPresented: $showingResetConfirm,
            titleVisibility: .visible
        ) {
            Button("settings.wipe_local", role: .destructive) {
                Task { await wipeLocalState() }
            }
            Button("action.cancel", role: .cancel) {}
        } message: {
            Text("settings.reset_confirm.body")
        }
    }

    @ToolbarContentBuilder
    private var trailingMenu: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    showingEditAccount = true
                } label: {
                    Label("profile.edit.title", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    Task { await session.signOut() }
                } label: {
                    Label("settings.sign_out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .scaledFont(.title3)
                    .foregroundStyle(.tint)
            }
        }
    }

    @ViewBuilder
    private var mainGrid: some View {
        if isWide {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 16) {
                    if shouldShow(card: appearanceCardSearchKeys) { appearanceCard }
                    if shouldShow(card: systemCardSearchKeys) { systemCard }
                    if shouldShow(card: aboutCardSearchKeys) { aboutCard }
                    if session.currentUser?.role == .developer,
                       shouldShow(card: developerCardSearchKeys) {
                        developerCard
                    }
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 16) {
                    if shouldShow(card: notificationsCardSearchKeys) { notificationsCard }
                    if shouldShow(card: preferencesCardSearchKeys) { preferencesCard }
                    if shouldShow(card: securityCardSearchKeys) { securityCard }
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: 16) {
                if shouldShow(card: appearanceCardSearchKeys) { appearanceCard }
                if shouldShow(card: notificationsCardSearchKeys) { notificationsCard }
                if shouldShow(card: preferencesCardSearchKeys) { preferencesCard }
                if shouldShow(card: securityCardSearchKeys) { securityCard }
                if shouldShow(card: systemCardSearchKeys) { systemCard }
                if shouldShow(card: aboutCardSearchKeys) { aboutCard }
                if session.currentUser?.role == .developer,
                   shouldShow(card: developerCardSearchKeys) {
                    developerCard
                }
            }
        }
    }

    // MARK: - Appearance

    private let appearanceCardSearchKeys = [
        "settings.appearance", "settings.language", "settings.theme",
        "settings.accent", "language.english", "language.arabic", "language.french",
        "profile.theme.light", "profile.theme.dark", "profile.theme.system",
        "settings.ui_scale", "settings.ui_scale.standard", "settings.ui_scale.large",
        "settings.ui_scale.xlarge", "settings.ui_scale.xxlarge"
    ]

    private var appearanceCard: some View {
        SectionCard("settings.appearance", icon: "paintpalette.fill") {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("settings.language")
                        .scaledFont(.subheadline, weight: .semibold)
                    Picker("settings.language", selection: $appLanguage) {
                        Text("language.english").tag("en")
                        Text("language.arabic").tag("ar")
                        Text("language.french").tag("fr")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("settings.theme")
                        .scaledFont(.subheadline, weight: .semibold)
                    ThemeSelectorView(selection: $themePref)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("settings.accent")
                        .scaledFont(.subheadline, weight: .semibold)
                    AccentColorPicker(selection: $accentPref)
                }
                #if os(macOS)
                VStack(alignment: .leading, spacing: 8) {
                    Text("settings.ui_scale")
                        .scaledFont(.subheadline, weight: .semibold)
                    Text("settings.ui_scale.subtitle")
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                    UIScaleSelectorView(selection: $macUIScalePref)
                }
                #else
                // iPad-only — iPhone layouts are already comfortably sized.
                if UIDevice.current.userInterfaceIdiom == .pad {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("settings.ui_scale")
                            .scaledFont(.subheadline, weight: .semibold)
                        Text("settings.ui_scale.subtitle")
                            .scaledFont(.caption)
                            .foregroundStyle(.secondary)
                        IPadUIScaleSelectorView(selection: $ipadUIScalePref)
                    }
                }
                #endif
            }
        }
    }

    // MARK: - Notifications

    private let notificationsCardSearchKeys = [
        "settings.notifications", "profile.edit.notif.class_reminders",
        "profile.edit.notif.announcements", "profile.edit.notif.weekly_digest",
        "profile.edit.notif.promotion_alerts", "settings.fire_test"
    ]

    private var notificationsCard: some View {
        SectionCard("settings.notifications", icon: "bell.badge.fill") {
            VStack(spacing: 0) {
                NavigationLinkRow(
                    icon: "bell.badge.fill",
                    tint: .accentColor,
                    label: "settings.notifications.push",
                    subtitle: "settings.notifications.push.subtitle",
                    destination: NotificationsCenterView()
                )
                divider
                NavigationLinkRow(
                    icon: "envelope.fill",
                    tint: .accentColor,
                    label: "profile.prefs.email",
                    subtitle: "profile.prefs.email.subtitle",
                    comingSoon: true
                )
                divider
                ToggleRow(
                    icon: "megaphone.fill",
                    tint: .orange,
                    label: "settings.notifications.announcements",
                    subtitle: "settings.notifications.announcements.subtitle",
                    isOn: notificationBinding(\.announcements)
                )
                divider
                ToggleRow(
                    icon: "rosette",
                    tint: .secondaryAccent,
                    label: "settings.notifications.competitions",
                    subtitle: "settings.notifications.competitions.subtitle",
                    isOn: notificationBinding(\.promotionAlerts)
                )
                divider
                ButtonRow(
                    icon: firingTest ? "hourglass" : "bolt.badge.clock",
                    tint: .purple,
                    label: "settings.fire_test",
                    subtitle: "settings.fire_test.subtitle",
                    trailingLabel: "settings.fire_test.send",
                    disabled: firingTest
                ) {
                    Task { await fireTestDigest() }
                }
            }
        }
    }

    // MARK: - Preferences

    private let preferencesCardSearchKeys = [
        "profile.prefs.dashboard", "profile.date_format", "profile.time_zone",
        "profile.number_format", "profile.preferred_language"
    ]

    private var preferencesCard: some View {
        SectionCard("profile.section.preferences", icon: "slider.horizontal.3") {
            VStack(spacing: 0) {
                NavigationLinkRow(
                    icon: "rectangle.3.group.fill",
                    tint: .accentColor,
                    label: "profile.prefs.dashboard",
                    subtitle: "profile.prefs.dashboard.subtitle",
                    destination: DashboardPreferencesView()
                )
                divider
                NavigationLinkRow(
                    icon: "calendar",
                    tint: .accentColor,
                    label: "profile.date_format",
                    subtitle: "profile.date_format.subtitle",
                    valueText: dateFormatPref,
                    destination: DateFormatPickerView()
                )
                divider
                NavigationLinkRow(
                    icon: "clock",
                    tint: .accentColor,
                    label: "profile.time_format",
                    subtitle: "profile.time_format.subtitle",
                    valueText: timeFormatPref == "24h" ? "24h" : "12h",
                    destination: TimeFormatPickerView()
                )
                divider
                NavigationLinkRow(
                    icon: "number",
                    tint: .accentColor,
                    label: "profile.number_format",
                    subtitle: "profile.number_format.subtitle",
                    valueText: numberFormatPref,
                    destination: NumberFormatPickerView()
                )
                divider
                NavigationLinkRow(
                    icon: "globe",
                    tint: .accentColor,
                    label: "profile.preferred_language",
                    subtitle: "profile.preferred_language.subtitle",
                    valueText: appLanguageLabel,
                    destination: PreferredLanguagePickerView()
                )
            }
        }
    }

    // MARK: - Security

    private let securityCardSearchKeys = [
        "profile.section.security", "profile.security.password",
        "profile.security.two_factor", "profile.security.active_sessions",
        "profile.security.login_activity", "settings.security.biometric"
    ]

    private var securityCard: some View {
        SectionCard("profile.section.security", icon: "lock.shield.fill") {
            VStack(spacing: 0) {
                NavigationLinkRow(
                    icon: "key.fill",
                    tint: .accentColor,
                    label: "profile.security.password",
                    subtitle: "profile.security.password.last_changed",
                    chevronLabel: "profile.security.change",
                    destination: ChangePasswordView()
                )
                divider
                ToggleRow(
                    icon: "lock.shield.fill",
                    tint: .secondaryAccent,
                    label: "profile.security.two_factor",
                    subtitle: twoFactorPref ? "settings.security.two_factor.on" : "settings.security.two_factor.off",
                    isOn: $twoFactorPref,
                    comingSoon: true
                )
                divider
                NavigationLinkRow(
                    icon: "iphone.gen3",
                    tint: .accentColor,
                    label: "profile.security.active_sessions",
                    subtitle: "profile.security.active_sessions.subtitle",
                    badgeText: "1",
                    comingSoon: true
                )
                divider
                NavigationLinkRow(
                    icon: "clock.arrow.circlepath",
                    tint: .accentColor,
                    label: "profile.security.login_activity",
                    subtitle: "profile.security.login_activity.subtitle",
                    destination: LoginActivityView()
                )
                divider
                ToggleRow(
                    icon: "faceid",
                    tint: .secondaryAccent,
                    label: "settings.security.biometric",
                    subtitle: "settings.security.biometric.subtitle",
                    isOn: $biometricPref
                )
            }
        }
    }

    // MARK: - System

    private let systemCardSearchKeys = [
        "settings.system", "settings.system.follow", "settings.system.sync",
        "settings.system.offline", "settings.system.cache"
    ]

    private var systemCard: some View {
        SectionCard("settings.system", icon: "gearshape.2.fill") {
            VStack(spacing: 0) {
                ToggleRow(
                    icon: "circle.lefthalf.filled",
                    tint: .accentColor,
                    label: "settings.system.follow",
                    subtitle: "settings.system.follow.subtitle",
                    isOn: followSystemBinding
                )
                divider
                NavigationLinkRow(
                    icon: "arrow.triangle.2.circlepath",
                    tint: .secondaryAccent,
                    label: "settings.system.sync",
                    subtitle: lastSyncSubtitle,
                    destination: DataSyncView()
                )
                divider
                NavigationLinkRow(
                    icon: "wifi.slash",
                    tint: .accentColor,
                    label: "settings.system.offline",
                    subtitle: "settings.system.offline.subtitle",
                    destination: OfflineModeView()
                )
                divider
                NavigationLinkRow(
                    icon: "externaldrive.fill",
                    tint: .accentColor,
                    label: "settings.system.cache",
                    subtitle: "settings.system.cache.subtitle",
                    destination: CacheManagementView()
                )
            }
        }
    }

    /// "Follow System" mirrors the theme preference: on ⇒ theme tracks the OS
    /// light/dark setting; off ⇒ a manual theme is used (the Appearance card's
    /// Theme picker then takes over).
    private var followSystemBinding: Binding<Bool> {
        Binding(
            get: { themePref == "system" },
            set: { themePref = $0 ? "system" : "light" }
        )
    }

    // MARK: - About

    private let aboutCardSearchKeys = [
        "settings.about_and_privacy", "settings.privacy", "settings.about",
        "settings.terms", "settings.licenses", "settings.build"
    ]

    private var aboutCard: some View {
        SectionCard("settings.about_and_privacy", icon: "info.circle.fill") {
            VStack(spacing: 0) {
                NavigationLinkRow(
                    icon: "hand.raised.fill",
                    tint: .accentColor,
                    label: "settings.privacy",
                    subtitle: "settings.privacy.subtitle",
                    destination: PrivacyPolicyView()
                )
                divider
                NavigationLinkRow(
                    icon: "info.circle.fill",
                    tint: .accentColor,
                    label: "settings.about",
                    subtitle: "settings.about.subtitle",
                    destination: AboutView()
                )
                divider
                NavigationLinkRow(
                    icon: "doc.text",
                    tint: .accentColor,
                    label: "settings.terms",
                    subtitle: "settings.terms.subtitle",
                    destination: TermsOfUseView()
                )
                divider
                NavigationLinkRow(
                    icon: "scroll",
                    tint: .accentColor,
                    label: "settings.licenses",
                    subtitle: "settings.licenses.subtitle",
                    destination: LicenseView()
                )
                divider
                ValueRow(
                    icon: "app.badge",
                    tint: .secondary,
                    label: "settings.build",
                    subtitle: "settings.build.subtitle",
                    value: buildVersionText
                )
            }
        }
    }

    // MARK: - Developer

    private let developerCardSearchKeys = [
        "settings.developer", "settings.use_demo_data", "settings.wipe_local",
        "settings.developer.mode", "settings.developer.debug"
    ]

    private var developerCard: some View {
        DangerCard(titleKey: "settings.developer", icon: "hammer.fill") {
            VStack(spacing: 0) {
                ToggleRow(
                    icon: "checkmark.shield.fill",
                    tint: .red,
                    label: "settings.use_demo_data",
                    subtitle: "settings.use_demo_data_help",
                    isOn: useDemoBinding
                )
                divider
                ToggleRow(
                    icon: "ladybug.fill",
                    tint: .red,
                    label: "settings.developer.mode",
                    subtitle: "settings.developer.mode.subtitle",
                    isOn: .constant(true),
                    comingSoon: true
                )
                divider
                NavigationLinkRow(
                    icon: "wrench.and.screwdriver.fill",
                    tint: .red,
                    label: "settings.developer.debug",
                    subtitle: "settings.developer.debug.subtitle",
                    comingSoon: true
                )
                divider
                DangerButtonRow(
                    icon: "trash.fill",
                    label: "settings.wipe_local",
                    subtitle: "settings.wipe_local_help"
                ) {
                    showingResetConfirm = true
                }
            }
        }
    }

    // MARK: - Helpers

    private var divider: some View { Divider().opacity(0.32) }

    private var appLanguageLabel: String {
        switch appLanguage {
        case "ar": NSLocalizedString("language.arabic", comment: "")
        case "fr": NSLocalizedString("language.french", comment: "")
        default: NSLocalizedString("language.english", comment: "")
        }
    }

    private var lastSyncSubtitle: LocalizedStringKey {
        "settings.system.sync.subtitle"
    }

    private var buildVersionText: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(v) (\(b))"
    }

    private var useDemoBinding: Binding<Bool> {
        Binding(
            get: {
                let hasSet = UserDefaults.standard.object(forKey: "useDemoData") != nil
                return hasSet ? UserDefaults.standard.bool(forKey: "useDemoData") : true
            },
            set: { newValue in
                UserDefaults.standard.set(newValue, forKey: "useDemoData")
            }
        )
    }

    private func notificationBinding(_ keyPath: WritableKeyPath<UserNotificationPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: {
                session.currentUser?.notificationPrefs[keyPath: keyPath] ?? false
            },
            set: { newValue in
                guard var user = session.currentUser else { return }
                user.notificationPrefs[keyPath: keyPath] = newValue
                Task { await session.updateProfile(user) }
            }
        )
    }

    private func shouldShow(card keys: [String]) -> Bool {
        guard !search.isEmpty else { return true }
        let q = search.lowercased()
        return keys.contains { key in
            NSLocalizedString(key, comment: "").lowercased().contains(q)
        }
    }

    // MARK: - Async

    private func fireTestDigest() async {
        firingTest = true
        defer { firingTest = false }
        do {
            let title = String(localized: "notif.sunday_digest.title")
            let body = String(localized: "notif.sunday_digest.body_test")
            try await notificationScheduler.scheduleLocal(
                id: "sunday-digest-test",
                title: title,
                body: body,
                fireAt: Date().addingTimeInterval(5)
            )
        } catch {
            print("MoreView.fireTestDigest:", error)
        }
    }

    /// Resets local-only state without touching the backend (see prior impl
    /// for details on what gets cleared).
    private func wipeLocalState() async {
        for kind in NotificationKind.allCases {
            await notificationScheduler.cancel(id: kind.rawValue)
        }
        await notificationScheduler.cancel(id: "sunday-digest")
        await notificationScheduler.cancel(id: "sunday-digest-test")

        UserDefaults.standard.removeObject(forKey: "rememberedUserID")
        UserDefaults.standard.removeObject(forKey: "hasRequestedNotifAuth")

        if let documents = try? FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false
        ) {
            let photosDir = documents.appendingPathComponent("athletePhotos", isDirectory: true)
            try? FileManager.default.removeItem(at: photosDir)
        }

        await session.signOut()
    }
}

// MARK: - Theme & accent pickers

private struct ThemeSelectorView: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 10) {
            ThemeButton(value: "light", label: "profile.theme.light", icon: "sun.max.fill", selection: $selection)
            ThemeButton(value: "dark", label: "profile.theme.dark", icon: "moon.fill", selection: $selection)
            ThemeButton(value: "system", label: "profile.theme.system", icon: "circle.lefthalf.filled", selection: $selection)
        }
    }
}

private struct ThemeButton: View {
    let value: String
    let label: LocalizedStringKey
    let icon: String
    @Binding var selection: String

    private var selected: Bool { selection == value }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selection = value
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .scaledFont(.title3)
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                Text(label)
                    .scaledFont(.caption, weight: .semibold)
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? Color.accentColor.opacity(0.7) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

/// macOS-only picker for the app-wide UI zoom preset. Renders the four
/// `MacUIScale` tiers as a segmented row matching the `ThemeSelectorView`
/// visual language so Settings → Appearance reads as one consistent block.
private struct UIScaleSelectorView: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 10) {
            ForEach(MacUIScale.allCases) { scale in
                UIScaleButton(value: scale.rawValue, label: scale.labelKey, selection: $selection)
            }
        }
    }
}

/// iPad UI-zoom picker — the four `IPadUIScale` tiers as a segmented row.
/// Reuses `UIScaleButton` so it matches the macOS picker exactly; the shared
/// tier raw values ("standard"/"large"/"xLarge"/"xxLarge") also drive the
/// growing-"Aa" preview glyph.
private struct IPadUIScaleSelectorView: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 10) {
            ForEach(IPadUIScale.allCases) { scale in
                UIScaleButton(value: scale.rawValue, label: scale.labelKey, selection: $selection)
            }
        }
    }
}

private struct UIScaleButton: View {
    let value: String
    let label: LocalizedStringKey
    @Binding var selection: String

    private var selected: Bool { selection == value }

    /// Each tier renders an "Aa" glyph that grows with the represented
    /// `DynamicTypeSize`, so the picker visually previews the effect before
    /// the user commits to a value.
    private var previewFont: Font {
        switch value {
        case "standard": .system(size: 12, weight: .semibold)
        case "large":    .system(size: 15, weight: .semibold)
        case "xLarge":   .system(size: 18, weight: .semibold)
        case "xxLarge":  .system(size: 22, weight: .semibold)
        default:         .system(size: 15, weight: .semibold)
        }
    }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selection = value
            }
        } label: {
            VStack(spacing: 6) {
                Text(verbatim: "Aa")
                    .font(previewFont)
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                    .frame(height: 26)
                Text(label)
                    .scaledFont(.caption, weight: .semibold)
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? Color.accentColor.opacity(0.7) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AccentColorPicker: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 14) {
            ForEach(AppAccent.allCases) { accent in
                AccentSwatch(value: accent.rawValue, color: accent.color, selection: $selection)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct AccentSwatch: View {
    let value: String
    let color: Color
    @Binding var selection: String

    private var selected: Bool { selection == value }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                selection = value
            }
        } label: {
            ZStack {
                Circle().fill(color)
                if selected {
                    Circle()
                        .stroke(Color.white.opacity(0.95), lineWidth: 2.5)
                        .padding(3)
                }
            }
            .frame(width: 30, height: 30)
            .overlay(
                Circle().stroke(selected ? Color.primary.opacity(0.9) : Color.white.opacity(0.5), lineWidth: 1.5)
            )
            .shadow(color: color.opacity(0.40), radius: selected ? 7 : 3, y: selected ? 3 : 1)
            .scaleEffect(selected ? 1.08 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: value.capitalized))
    }
}

// MARK: - Generic premium settings rows

private struct ToggleRow: View {
    let icon: String
    let tint: Color
    let label: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    @Binding var isOn: Bool
    var disabled: Bool = false
    var comingSoon: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            iconBadge(icon: icon, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).scaledFont(.subheadline, weight: .semibold)
                if let subtitle {
                    Text(subtitle).scaledFont(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            if comingSoon {
                ComingSoonChip()
            } else {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .disabled(disabled)
                    .tint(.secondaryAccent)
            }
        }
        .padding(.vertical, 11)
        .opacity((disabled || comingSoon) ? 0.6 : 1)
    }
}

private struct NavigationLinkRow<Destination: View>: View {
    let icon: String
    let tint: Color
    let label: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    var valueText: String? = nil
    var badgeText: LocalizedStringKey? = nil
    var chevronLabel: LocalizedStringKey? = nil
    var comingSoon: Bool = false
    var destination: Destination

    init(
        icon: String,
        tint: Color,
        label: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        valueText: String? = nil,
        badgeText: LocalizedStringKey? = nil,
        chevronLabel: LocalizedStringKey? = nil,
        comingSoon: Bool = false,
        @ViewBuilder destination: () -> Destination = { EmptyView() }
    ) {
        self.icon = icon
        self.tint = tint
        self.label = label
        self.subtitle = subtitle
        self.valueText = valueText
        self.badgeText = badgeText
        self.chevronLabel = chevronLabel
        self.comingSoon = comingSoon
        self.destination = destination()
    }

    /// Convenience overload to pass a destination directly without the closure.
    init(
        icon: String,
        tint: Color,
        label: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        valueText: String? = nil,
        badgeText: LocalizedStringKey? = nil,
        chevronLabel: LocalizedStringKey? = nil,
        comingSoon: Bool = false,
        destination: Destination
    ) {
        self.icon = icon
        self.tint = tint
        self.label = label
        self.subtitle = subtitle
        self.valueText = valueText
        self.badgeText = badgeText
        self.chevronLabel = chevronLabel
        self.comingSoon = comingSoon
        self.destination = destination
    }

    var body: some View {
        if comingSoon {
            content.opacity(0.6)
        } else {
            NavigationLink {
                destination
            } label: {
                content
            }
            .buttonStyle(.plain)
        }
    }

    private var content: some View {
        HStack(alignment: .center, spacing: 12) {
            iconBadge(icon: icon, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).scaledFont(.subheadline, weight: .semibold)
                if let subtitle {
                    Text(subtitle).scaledFont(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            if comingSoon {
                ComingSoonChip()
            } else {
                trailingDecoration
                Image(systemName: "chevron.right")
                    .scaledFont(.caption, weight: .semibold)
                    .foregroundStyle(.tertiary)
                    .flipsForRightToLeftLayoutDirection(true)
            }
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var trailingDecoration: some View {
        if let valueText {
            Text(verbatim: valueText)
                .scaledFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .environment(\.layoutDirection, .leftToRight)
        } else if let badgeText {
            Text(badgeText)
                .scaledFont(.caption, weight: .semibold)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Color.secondaryAccent.opacity(0.18), in: Capsule())
                .foregroundStyle(Color.secondaryAccent)
        } else if let chevronLabel {
            Text(chevronLabel)
                .scaledFont(.footnote, weight: .semibold)
                .foregroundStyle(.tint)
        }
    }
}

private struct ValueRow: View {
    let icon: String
    let tint: Color
    let label: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let value: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            iconBadge(icon: icon, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).scaledFont(.subheadline, weight: .semibold)
                if let subtitle {
                    Text(subtitle).scaledFont(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Text(verbatim: value)
                .scaledFont(.footnote, weight: .medium, monospacedDigit: true)
                .foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.vertical, 11)
    }
}

private struct ButtonRow: View {
    let icon: String
    let tint: Color
    let label: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let trailingLabel: LocalizedStringKey
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                iconBadge(icon: icon, tint: tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).scaledFont(.subheadline, weight: .semibold)
                    if let subtitle {
                        Text(subtitle).scaledFont(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                Text(trailingLabel)
                    .scaledFont(.footnote, weight: .semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(tint.opacity(0.15), in: Capsule())
                    .foregroundStyle(tint)
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.6 : 1)
    }
}

private struct DangerButtonRow: View {
    let icon: String
    let label: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                iconBadge(icon: icon, tint: .red)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .scaledFont(.subheadline, weight: .semibold)
                        .foregroundStyle(.red)
                    if let subtitle {
                        Text(subtitle).scaledFont(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.right")
                    .scaledFont(.caption, weight: .semibold)
                    .foregroundStyle(.red)
                    .flipsForRightToLeftLayoutDirection(true)
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon badge

@ViewBuilder
private func iconBadge(icon: String, tint: Color) -> some View {
    ZStack {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(tint.opacity(0.14))
        Image(systemName: icon)
            .scaledFont(.footnote, weight: .semibold)
            .foregroundStyle(tint)
    }
    .frame(width: 32, height: 32)
}

// MARK: - Danger card surface

private struct DangerCard<Content: View>: View {
    let titleKey: LocalizedStringKey
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .scaledFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.red)
                Text(titleKey)
                    .scaledFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.red)
                Spacer(minLength: 0)
                Image(systemName: "exclamationmark.shield.fill")
                    .scaledFont(.caption)
                    .foregroundStyle(.red.opacity(0.8))
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.red.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.red.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.red.opacity(0.05), radius: 12, y: 4)
    }
}

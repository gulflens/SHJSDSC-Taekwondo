import SwiftUI

@main
struct SHJSDSCApp: App {
    @State private var session: AppSession
    @State private var notificationScheduler: any NotificationScheduler = LocalNotificationScheduler()
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("prefs.theme") private var themePref: String = "system"
    @AppStorage("prefs.accent") private var accentPref: String = "blue"
    /// macOS-only UI zoom level. SwiftUI defaults on macOS render system text
    /// styles noticeably smaller than the iPad-tuned layouts the app was
    /// designed for, so we ship with a comfortable "xLarge" default and let
    /// the user dial it via Settings → Appearance → UI Zoom.
    @AppStorage("prefs.macUIScale") private var macUIScalePref: String = "xLarge"
    @AppStorage("hasRequestedNotifAuth") private var hasRequestedNotifAuth: Bool = false
    @State private var hasBootstrapped = false
    /// Optional Face ID / Touch ID app lock (Settings → Security). Starts
    /// locked on cold launch when enabled; re-locks on backgrounding.
    @State private var biometricLock = BiometricLock()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let hasSetPref = UserDefaults.standard.object(forKey: "useDemoData") != nil
        let firstLaunchDefault = !SupabaseConfig.url.isEmpty && !SupabaseConfig.anonKey.isEmpty
            ? false
            : true
        let useDemoData = hasSetPref
            ? UserDefaults.standard.bool(forKey: "useDemoData")
            : firstLaunchDefault
        let repo = SHJSDSCApp.makeRepository(useDemoData: useDemoData)
        _session = State(initialValue: AppSession(repository: repo))
    }

    /// Repository selection:
    ///   • useDemoData true → DemoRepository (Stages 1-4 behaviour)
    ///   • useDemoData false + Supabase package added + non-empty config →
    ///     real SupabaseRepository
    ///   • Anything missing → silent fallback to DemoRepository with a log
    ///
    /// Config priority: `SupabaseConfig` (committed Swift constants) → Info.plist
    /// (xcconfig-driven for deployments that prefer build-settings wiring).
    private static func makeRepository(useDemoData: Bool) -> any Repository {
        if useDemoData { return DemoRepository() }

        let urlString: String = {
            if !SupabaseConfig.url.isEmpty { return SupabaseConfig.url }
            return (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String) ?? ""
        }()
        let key: String = {
            if !SupabaseConfig.anonKey.isEmpty { return SupabaseConfig.anonKey }
            return (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String) ?? ""
        }()

        guard let url = URL(string: urlString),
              !urlString.isEmpty, !key.isEmpty,
              !urlString.contains("your-project-ref") else {
            print("Supabase config missing or unedited — using demo data.")
            return DemoRepository()
        }

        #if canImport(Supabase)
        // Wrap the live backend in CachingRepository so Offline Mode and the
        // disk read-cache work. DemoRepository is in-memory and needs neither.
        return CachingRepository(base: SupabaseRepository(url: url, anonKey: key))
        #else
        print("supabase-swift package not added — using demo data.")
        return DemoRepository()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if hasBootstrapped {
                        RoleRouter()
                    } else {
                        LaunchView()
                    }
                }
                .environment(session)
                .environment(\.notificationScheduler, notificationScheduler)

                // Biometric gate — covers the whole app while locked.
                if biometricLock.isLocked {
                    BiometricLockView(lock: biometricLock)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: biometricLock.isLocked)
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { biometricLock.lockIfEnabled() }
            }
            .environment(\.locale, locale)
            .environment(\.layoutDirection, layoutDirection)
            .preferredColorScheme(preferredColorScheme)
            .appNavigationChrome()
            .appAccent(AppAccent.from(accentPref))
            .id(appLanguage)
            #if os(macOS)
            // Without an explicit min frame the macOS window opens at a tiny
            // default size that makes the iPad-tuned layout look stranded.
            // 1180×760 keeps the sidebar + a comfortable detail pane visible
            // without forcing huge displays into a compromised layout.
            .frame(minWidth: 1100, minHeight: 700)
            // UI Zoom, three prongs — all driven by the same MacUIScale tier
            // so the picker affects the whole UI without the broken geometry
            // of a root-level scaleEffect:
            //   • dynamicTypeSize → every semantic-font view (.body/.caption/
            //     .title3/etc.), which is most text incl. sidebar + inputs
            //   • controlSize     → text fields, buttons, pickers, steppers
            //   • \.uiScale       → .scaledFont(...) + explicit dimensions
            //     (sidebar column width, icon boxes) that opt in
            .dynamicTypeSize(MacUIScale.from(macUIScalePref).dynamicTypeSize)
            .controlSize(MacUIScale.from(macUIScalePref).controlSize)
            .environment(\.uiScale, MacUIScale.from(macUIScalePref).scaleFactor)
            #endif
            .task {
                await session.bootstrap()
                withAnimation(.easeOut(duration: 0.3)) {
                    hasBootstrapped = true
                }
                if !hasRequestedNotifAuth {
                    _ = await notificationScheduler.requestAuthorization()
                    hasRequestedNotifAuth = true
                }
                await scheduleSundayDigestIfEnabled()
                await scheduleCertExpiriesIfEnabled()
            }
        }
        #if os(macOS)
        // Initial window size on first launch. macOS remembers user-resized
        // dimensions on subsequent launches via Auto Layout state restoration,
        // so this only sets the very first impression.
        .defaultSize(width: 1280, height: 820)
        .windowResizability(.contentMinSize)
        .commands {
            ZoomCommands()
        }
        #endif
    }

    private var locale: Locale {
        switch appLanguage {
        case "ar": Locale(identifier: "ar")
        case "fr": Locale(identifier: "fr")
        default: Locale(identifier: "en")
        }
    }

    private var layoutDirection: LayoutDirection {
        appLanguage == "ar" ? .rightToLeft : .leftToRight
    }

    /// Maps the persisted theme preference (Settings → Appearance → Theme) to
    /// SwiftUI's `ColorScheme` override. `nil` means "follow system" — the OS
    /// dark/light setting wins.
    private var preferredColorScheme: ColorScheme? {
        switch themePref {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private func scheduleSundayDigestIfEnabled() async {
        let enabled = UserDefaults.standard.object(forKey: NotificationKind.tdSundayDigest.preferenceKey) as? Bool ?? true
        guard enabled else { return }
        do {
            let scores = try await session.repository.allScores()
            let avg = scores.isEmpty ? 0.0 : scores.reduce(0.0) { $0 + ScoreEngine.composite($1) } / Double(scores.count)
            let athletes = try await session.repository.athletes()
            let watch = athletes.filter { $0.status == .watch }.count
            let expiring = try await session.repository.expiringSoon(within: 30 * 24 * 3600)
            let digest = DigestBuilder.buildSundayDigest(
                date: Date(),
                scoresAvg: avg,
                watchListCount: watch,
                certsExpiring: expiring.count
            )
            let title = String(localized: "notif.sunday_digest.title")
            let body = String(format: NSLocalizedString("notif.sunday_digest.body", comment: ""), avg, watch, expiring.count)
            try await notificationScheduler.scheduleLocal(
                id: "sunday-digest",
                title: title,
                body: body,
                fireAt: digest.fireAt
            )
        } catch {
            print("SHJSDSCApp.scheduleSundayDigestIfEnabled:", error)
        }
    }

    #if os(macOS)
    fileprivate struct ZoomCommands: Commands {
        @AppStorage("prefs.macUIScale") private var macUIScalePref: String = "xLarge"

        var body: some Commands {
            // Append into the View menu (where SwiftUI groups sidebar/toolbar
            // commands). Three items mirror standard macOS apps: ⌘+ steps up,
            // ⌘- steps down, ⌘0 returns to the app's natural baseline (xLarge,
            // which is the iPad-tuned default on macOS).
            CommandGroup(after: .sidebar) {
                Button("menu.view.zoom_in") { step(by: 1) }
                    .keyboardShortcut("+", modifiers: .command)
                    .disabled(current == MacUIScale.allCases.last)
                Button("menu.view.zoom_out") { step(by: -1) }
                    .keyboardShortcut("-", modifiers: .command)
                    .disabled(current == MacUIScale.allCases.first)
                Button("menu.view.actual_size") {
                    macUIScalePref = MacUIScale.xLarge.rawValue
                }
                .keyboardShortcut("0", modifiers: .command)
                .disabled(current == .xLarge)
            }
        }

        private var current: MacUIScale { MacUIScale.from(macUIScalePref) }

        private func step(by delta: Int) {
            let cases = MacUIScale.allCases
            guard let idx = cases.firstIndex(of: current) else { return }
            let next = idx + delta
            guard cases.indices.contains(next) else { return }
            macUIScalePref = cases[next].rawValue
        }
    }
    #endif

    private func scheduleCertExpiriesIfEnabled() async {
        let enabled = UserDefaults.standard.object(forKey: NotificationKind.certExpiring.preferenceKey) as? Bool ?? true
        guard enabled else { return }
        do {
            let expiring = try await session.repository.expiringSoon(within: 30 * 24 * 3600)
            for cert in expiring {
                let id = "cert-\(cert.id.uuidString)"
                let title = String(localized: "notif.cert_expiring.title")
                let body = String(format: NSLocalizedString("notif.cert_expiring.body", comment: ""), String(localized: LocalizedStringResource(stringLiteral: cert.kind.labelKey)), cert.daysUntilExpiry)
                let fireAt = max(Date().addingTimeInterval(60), cert.expiresAt.addingTimeInterval(-7 * 24 * 3600))
                try await notificationScheduler.scheduleLocal(id: id, title: title, body: body, fireAt: fireAt)
            }
        } catch {
            print("SHJSDSCApp.scheduleCertExpiriesIfEnabled:", error)
        }
    }
}
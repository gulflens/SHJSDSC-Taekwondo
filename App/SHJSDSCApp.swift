import SwiftUI

@main
struct SHJSDSCApp: App {
    @State private var session: AppSession
    @State private var notificationScheduler: any NotificationScheduler = LocalNotificationScheduler()
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    @AppStorage("hasRequestedNotifAuth") private var hasRequestedNotifAuth: Bool = false

    init() {
        let useDemoData = UserDefaults.standard.bool(forKey: "useDemoData")
        let repo = SHJSDSCApp.makeRepository(useDemoData: useDemoData)
        _session = State(initialValue: AppSession(repository: repo))
    }

    /// Repository selection:
    ///   • useDemoData true → DemoRepository (Stages 1-4 behaviour)
    ///   • useDemoData false + Supabase package added + xcconfig wired →
    ///     real SupabaseRepository
    ///   • Anything missing → silent fallback to DemoRepository with a log
    private static func makeRepository(useDemoData: Bool) -> any Repository {
        if useDemoData { return DemoRepository() }

        let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
        guard let urlString, let url = URL(string: urlString),
              let key, !key.isEmpty,
              !urlString.contains("your-project-ref") else {
            print("Supabase config missing or unedited — using demo data.")
            return DemoRepository()
        }

        #if canImport(Supabase)
        return SupabaseRepository(url: url, anonKey: key)
        #else
        print("supabase-swift package not added — using demo data.")
        return DemoRepository()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RoleRouter()
                .environment(session)
                .environment(\.notificationScheduler, notificationScheduler)
                .environment(\.locale, locale)
                .environment(\.layoutDirection, layoutDirection)
                .task {
                    await session.bootstrap()
                    if !hasRequestedNotifAuth {
                        _ = await notificationScheduler.requestAuthorization()
                        hasRequestedNotifAuth = true
                    }
                    await scheduleSundayDigestIfEnabled()
                    await scheduleCertExpiriesIfEnabled()
                }
        }
    }

    private var locale: Locale {
        switch appLanguage {
        case "en": Locale(identifier: "en")
        case "ar": Locale(identifier: "ar")
        default: Locale.current
        }
    }

    private var layoutDirection: LayoutDirection {
        switch appLanguage {
        case "ar": .rightToLeft
        case "en": .leftToRight
        default: Locale.current.language.languageCode?.identifier == "ar" ? .rightToLeft : .leftToRight
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

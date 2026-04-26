import SwiftUI

@main
struct SHJSDSCApp: App {
    @State private var session = AppSession(repository: DemoRepository())
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    var body: some Scene {
        WindowGroup {
            RoleRouter()
                .environment(session)
                .environment(\.locale, locale)
                .environment(\.layoutDirection, layoutDirection)
                .task { await session.bootstrap() }
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
}

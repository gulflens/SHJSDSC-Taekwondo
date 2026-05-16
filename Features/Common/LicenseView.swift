import SwiftUI

/// In-app License & acknowledgements screen. Structured `ScrollView` of
/// sections mirroring `PrivacyPolicyView` so the About / Terms / License
/// trio stays consistent. The app ships no third-party packages today
/// (see CLAUDE.md — no SPM deps before the Supabase stage); the third-party
/// section reflects that and is ready for entries to be appended later.
public struct LicenseView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                ForEach(Section.allCases, id: \.self) { section in
                    sectionView(section)
                }
                footer
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.appBackground)
        .navigationTitle(Text("settings.licenses"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "scroll.fill")
                .scaledFont(.title)
                .foregroundStyle(.tint)
            Text("license.app_title").scaledFont(.title2, weight: .bold)
            Text(verbatim: copyrightLine)
                .scaledFont(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func sectionView(_ section: Section) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .scaledFont(.subheadline, weight: .bold)
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 6))
                Text(localizedKey: section.titleKey)
                    .scaledFont(.headline)
            }
            Text(localizedKey: section.bodyKey)
                .scaledFont(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("license.contact_title").scaledFont(.headline)
            Text("license.contact_body")
                .scaledFont(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Link(destination: URL(string: "mailto:hello@gulflens.studio")!) {
                Label {
                    Text(verbatim: "hello@gulflens.studio")
                } icon: {
                    Image(systemName: "envelope.fill")
                }
                .scaledFont(.subheadline, weight: .bold)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
    }

    /// "© 2026 Gulf Lens Studio" — year resolved at runtime so it never stales.
    private var copyrightLine: String {
        let year = Calendar.current.component(.year, from: Date())
        return String(format: NSLocalizedString("license.copyright_format", comment: ""), year)
    }

    private enum Section: CaseIterable {
        case app
        case frameworks
        case thirdParty

        var icon: String {
            switch self {
            case .app:        "lock.doc.fill"
            case .frameworks: "swift"
            case .thirdParty: "shippingbox.fill"
            }
        }

        var titleKey: String {
            switch self {
            case .app:        "license.section.app.title"
            case .frameworks: "license.section.frameworks.title"
            case .thirdParty: "license.section.third_party.title"
            }
        }

        var bodyKey: String {
            switch self {
            case .app:        "license.section.app.body"
            case .frameworks: "license.section.frameworks.body"
            case .thirdParty: "license.section.third_party.body"
            }
        }
    }
}

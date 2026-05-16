import SwiftUI

/// In-app "About" screen. Structured `ScrollView` of sections mirroring
/// `PrivacyPolicyView` so the About / Terms / License trio reads as one
/// consistent family. Content is fully localised; the version line is read
/// live from the bundle.
public struct AboutView: View {
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
        .navigationTitle(Text("settings.about"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "figure.taekwondo")
                .scaledFont(.title)
                .foregroundStyle(.tint)
            Text("about.app_title").scaledFont(.title2, weight: .bold)
            Text(verbatim: versionLine)
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
            Text("about.contact_title").scaledFont(.headline)
            Text("about.contact_body")
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

    /// "Version 1.0 (12)" — read live from the bundle so it never drifts.
    private var versionLine: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return String(format: NSLocalizedString("about.version_format", comment: ""), v, b)
    }

    private enum Section: CaseIterable {
        case app
        case club
        case features
        case team

        var icon: String {
            switch self {
            case .app:      "iphone"
            case .club:     "building.columns.fill"
            case .features: "checklist"
            case .team:     "hammer.fill"
            }
        }

        var titleKey: String {
            switch self {
            case .app:      "about.section.app.title"
            case .club:     "about.section.club.title"
            case .features: "about.section.features.title"
            case .team:     "about.section.team.title"
            }
        }

        var bodyKey: String {
            switch self {
            case .app:      "about.section.app.body"
            case .club:     "about.section.club.body"
            case .features: "about.section.features.body"
            case .team:     "about.section.team.body"
            }
        }
    }
}

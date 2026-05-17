import SwiftUI

/// In-app privacy policy. Built as a structured `ScrollView` of sections so
/// the content is searchable, accessible, and stays in-app rather than
/// kicking the user out to a Safari tab.
public struct PrivacyPolicyView: View {
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
        .subviewChrome(Text("settings.privacy"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "hand.raised.fill")
                .scaledFont(.title)
                .foregroundStyle(.tint)
            Text("privacy.app_title").scaledFont(.title2, weight: .bold)
            Text("privacy.last_updated").scaledFont(.caption).foregroundStyle(.secondary)
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
            Text("privacy.contact_title").scaledFont(.headline)
            Text("privacy.contact_body")
                .scaledFont(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Link(destination: URL(string: "mailto:privacy@gulflens.studio")!) {
                Label {
                    Text(verbatim: "privacy@gulflens.studio")
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

    private enum Section: CaseIterable {
        case dataWeCollect
        case howWeUseIt
        case sharing
        case storage
        case minorsAndConsent
        case mediaConsent
        case yourRights
        case retention

        var icon: String {
            switch self {
            case .dataWeCollect: "tray.full.fill"
            case .howWeUseIt: "gearshape.2.fill"
            case .sharing: "person.2.fill"
            case .storage: "lock.shield.fill"
            case .minorsAndConsent: "figure.and.child.holdinghands"
            case .mediaConsent: "camera.fill"
            case .yourRights: "person.badge.shield.checkmark.fill"
            case .retention: "clock.arrow.circlepath"
            }
        }

        var titleKey: String {
            switch self {
            case .dataWeCollect: "privacy.section.data_we_collect.title"
            case .howWeUseIt: "privacy.section.how_we_use_it.title"
            case .sharing: "privacy.section.sharing.title"
            case .storage: "privacy.section.storage.title"
            case .minorsAndConsent: "privacy.section.minors.title"
            case .mediaConsent: "privacy.section.media.title"
            case .yourRights: "privacy.section.your_rights.title"
            case .retention: "privacy.section.retention.title"
            }
        }

        var bodyKey: String {
            switch self {
            case .dataWeCollect: "privacy.section.data_we_collect.body"
            case .howWeUseIt: "privacy.section.how_we_use_it.body"
            case .sharing: "privacy.section.sharing.body"
            case .storage: "privacy.section.storage.body"
            case .minorsAndConsent: "privacy.section.minors.body"
            case .mediaConsent: "privacy.section.media.body"
            case .yourRights: "privacy.section.your_rights.body"
            case .retention: "privacy.section.retention.body"
            }
        }
    }
}

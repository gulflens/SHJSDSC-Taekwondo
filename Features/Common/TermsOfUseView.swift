import SwiftUI

/// In-app Terms of Use. Structured `ScrollView` of sections mirroring
/// `PrivacyPolicyView` so the About / Terms / License trio stays consistent.
public struct TermsOfUseView: View {
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
        .navigationTitle(Text("settings.terms"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "doc.text.fill")
                .scaledFont(.title)
                .foregroundStyle(.tint)
            Text("terms.app_title").scaledFont(.title2, weight: .bold)
            Text("terms.last_updated").scaledFont(.caption).foregroundStyle(.secondary)
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
            Text("terms.contact_title").scaledFont(.headline)
            Text("terms.contact_body")
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

    private enum Section: CaseIterable {
        case acceptance
        case eligibility
        case permittedUse
        case prohibited
        case memberData
        case availability
        case liability
        case changes

        var icon: String {
            switch self {
            case .acceptance:   "checkmark.seal.fill"
            case .eligibility:  "person.badge.key.fill"
            case .permittedUse: "hand.thumbsup.fill"
            case .prohibited:   "hand.raised.slash.fill"
            case .memberData:   "person.2.fill"
            case .availability: "wifi.exclamationmark"
            case .liability:    "exclamationmark.shield.fill"
            case .changes:      "arrow.triangle.2.circlepath"
            }
        }

        var titleKey: String {
            switch self {
            case .acceptance:   "terms.section.acceptance.title"
            case .eligibility:  "terms.section.eligibility.title"
            case .permittedUse: "terms.section.permitted_use.title"
            case .prohibited:   "terms.section.prohibited.title"
            case .memberData:   "terms.section.member_data.title"
            case .availability: "terms.section.availability.title"
            case .liability:    "terms.section.liability.title"
            case .changes:      "terms.section.changes.title"
            }
        }

        var bodyKey: String {
            switch self {
            case .acceptance:   "terms.section.acceptance.body"
            case .eligibility:  "terms.section.eligibility.body"
            case .permittedUse: "terms.section.permitted_use.body"
            case .prohibited:   "terms.section.prohibited.body"
            case .memberData:   "terms.section.member_data.body"
            case .availability: "terms.section.availability.body"
            case .liability:    "terms.section.liability.body"
            case .changes:      "terms.section.changes.body"
            }
        }
    }
}

import SwiftUI

public struct CertificateView: View {
    @Environment(AppSession.self) private var session
    public let certificate: GradingCertificate
    public let athlete: Athlete

    @State private var examiners: [Coach] = []
    @State private var branch: Branch?

    public init(certificate: GradingCertificate, athlete: Athlete) {
        self.certificate = certificate
        self.athlete = athlete
    }

    public var body: some View {
        ScrollView {
            certificateBody
                .padding(24)
        }
        .navigationTitle(Text("grading.certificate"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: shareSummary) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.30, green: 0.30, blue: 0.31), in: Capsule())
                        .contentShape(Capsule())
                }
            }
        }
        #endif
        .task { await load() }
    }

    private var certificateBody: some View {
        VStack(spacing: 18) {
            // Header
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .scaledFont(size: 32)
                    .foregroundStyle(.tint)
                Spacer()
                Text(verbatim: "SSDSC")
                    .scaledFont(size: 16, weight: .bold, design: .serif)
                    .foregroundStyle(.secondary)
                    .help(Text("tooltip.ssdsc"))
                Spacer()
                Image(systemName: "shield.lefthalf.filled")
                    .scaledFont(size: 32)
                    .foregroundStyle(.tint)
                    .scaleEffect(x: -1, y: 1)
            }
            Divider()

            Text("grading.certificate")
                .scaledFont(size: 28, weight: .bold, design: .serif)

            // Names — both languages
            VStack(spacing: 6) {
                Text("grading.awarded_to")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: athlete.fullName)
                    .scaledFont(size: 24, weight: .semibold, design: .serif)
                Text(verbatim: athlete.fullNameAr)
                    .scaledFont(size: 22, weight: .semibold, design: .serif)
            }

            // Belt transition
            HStack(spacing: 16) {
                beltBadge(certificate.fromBelt, label: "grading.from_belt")
                Image(systemName: "arrow.right")
                    .scaledFont(.title3)
                    .foregroundStyle(.secondary)
                beltBadge(certificate.toBelt, label: "grading.to_belt")
            }

            Divider()

            // Dates: Gregorian + Hijri
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("grading.issued_on").scaledFont(.caption).foregroundStyle(.secondary)
                    Text(verbatim: gregorianDate)
                        .scaledFont(.callout)
                }
                VStack(spacing: 4) {
                    Text("grading.hijri_date").scaledFont(.caption).foregroundStyle(.secondary)
                    Text(verbatim: hijriDate)
                        .scaledFont(.callout)
                }
            }

            // Branch line
            if let branch {
                Text(verbatim: "\(branch.name) · \(branch.nameAr)")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
            }

            // Signatures
            VStack(spacing: 8) {
                Text("grading.signed_by").scaledFont(.caption).foregroundStyle(.secondary)
                ForEach(examiners) { c in
                    HStack(spacing: 8) {
                        Avatar(seed: c.avatarSeed, label: c.initials, size: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: c.fullName).scaledFont(.caption)
                            Rectangle()
                                .fill(Color.primary.opacity(0.35))
                                .frame(width: 120, height: 0.6)
                        }
                    }
                }
            }
            .padding(.top, 4)

            // Watermark
            Text(verbatim: "SSDSC")
                .scaledFont(size: 56, weight: .bold, design: .serif)
                .foregroundStyle(Color.tint.opacity(0.06))
                .padding(.top, 8)
        }
        .frame(maxWidth: 520)
        .padding(28)
        .background(Color.secondary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }

    private func beltBadge(_ belt: Belt, label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(label).scaledFont(.caption2).foregroundStyle(.secondary)
            RoundedRectangle(cornerRadius: 6)
                .fill(belt.color.swiftUIColor)
                .frame(width: 64, height: 14)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.2), lineWidth: 0.5))
            Text(localizedKey: belt.label)
                .scaledFont(.caption, weight: .bold)
        }
    }

    private var gregorianDate: String {
        let f = DateFormatter()
        f.dateStyle = .long
        return f.string(from: certificate.awardedAt)
    }

    private var hijriDate: String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .islamicUmmAlQura)
        f.locale = Locale(identifier: "ar")
        f.dateStyle = .long
        return f.string(from: certificate.awardedAt)
    }

    private var shareSummary: String {
        var parts: [String] = []
        parts.append("SHJSDSC — \(athlete.fullName)")
        parts.append("\(athlete.fullNameAr)")
        parts.append("\(gregorianDate) · \(hijriDate)")
        return parts.joined(separator: "\n")
    }

    private func load() async {
        do {
            branch = try await session.repository.branch(id: athletesBranchID())
            var es: [Coach] = []
            for id in certificate.signedByCoachIDs {
                if let c = try await session.repository.coach(id: id) { es.append(c) }
            }
            examiners = es
        } catch {
            print("CertificateView.load:", error)
        }
    }

    private func athletesBranchID() -> EntityID {
        athlete.branchID
    }
}


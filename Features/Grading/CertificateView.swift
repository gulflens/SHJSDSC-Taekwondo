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
                    .font(.system(size: 32))
                    .foregroundStyle(.tint)
                Spacer()
                Text(verbatim: "SSDSC")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 32))
                    .foregroundStyle(.tint)
                    .scaleEffect(x: -1, y: 1)
            }
            Divider()

            Text("grading.certificate")
                .font(.system(size: 28, weight: .bold, design: .serif))

            // Names — both languages
            VStack(spacing: 6) {
                Text("grading.awarded_to")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: athlete.fullName)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                Text(verbatim: athlete.fullNameAr)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
            }

            // Belt transition
            HStack(spacing: 16) {
                beltBadge(certificate.fromBelt, label: "grading.from_belt")
                Image(systemName: "arrow.right")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                beltBadge(certificate.toBelt, label: "grading.to_belt")
            }

            Divider()

            // Dates: Gregorian + Hijri
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("grading.issued_on").font(.caption).foregroundStyle(.secondary)
                    Text(verbatim: gregorianDate)
                        .font(.callout)
                }
                VStack(spacing: 4) {
                    Text("grading.hijri_date").font(.caption).foregroundStyle(.secondary)
                    Text(verbatim: hijriDate)
                        .font(.callout)
                }
            }

            // Branch line
            if let branch {
                Text(verbatim: "\(branch.name) · \(branch.nameAr)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Signatures
            VStack(spacing: 8) {
                Text("grading.signed_by").font(.caption).foregroundStyle(.secondary)
                ForEach(examiners) { c in
                    HStack(spacing: 8) {
                        Avatar(seed: c.avatarSeed, label: c.initials, size: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: c.fullName).font(.caption)
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
                .font(.system(size: 56, weight: .bold, design: .serif))
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
            Text(label).font(.caption2).foregroundStyle(.secondary)
            RoundedRectangle(cornerRadius: 6)
                .fill(belt.color.swiftUIColor)
                .frame(width: 64, height: 14)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.2), lineWidth: 0.5))
            Text(LocalizedStringKey(belt.label))
                .font(.caption.bold())
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

private extension Color {
    static var tint: Color { .accentColor }
}

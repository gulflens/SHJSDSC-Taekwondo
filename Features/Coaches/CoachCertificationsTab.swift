import SwiftUI

/// Coach certifications surface — completeness ring + active / expiring /
/// expired sections, each rendered as styled rows with severity indicators.
public struct CoachCertificationsTab: View {
    public let coach: Coach
    public let certifications: [Certification]
    public let isWide: Bool

    public init(coach: Coach, certifications: [Certification], isWide: Bool) {
        self.coach = coach
        self.certifications = certifications
        self.isWide = isWide
    }

    public var body: some View {
        VStack(spacing: 14) {
            summaryBanner
            sectionFor(severity: .expired, titleKey: "coach.certifications.section.expired", icon: "xmark.octagon.fill")
            sectionFor(severity: .expiring, titleKey: "coach.certifications.section.expiring", icon: "exclamationmark.triangle.fill")
            sectionFor(severity: .ok, titleKey: "coach.certifications.section.active", icon: "checkmark.seal.fill")
            embeddedCoachExpiriesCard
        }
    }

    private var summaryBanner: some View {
        SectionCard {
            HStack(spacing: 16) {
                ProgressRing(
                    value: certifications.isEmpty ? 0 : Double(activeCount) / Double(certifications.count),
                    size: 88,
                    trackWidth: 9,
                    centerLabelKey: "coach.certifications.health"
                )
                VStack(alignment: .leading, spacing: 6) {
                    Text("coach.certifications.title")
                        .scaledFont(.subheadline, weight: .semibold)
                    AthleteSummaryRow(
                        icon: "checkmark.circle.fill",
                        labelKey: "coach.certifications.active",
                        value: "\(activeCount)",
                        valueColor: .green
                    )
                    AthleteSummaryRow(
                        icon: "exclamationmark.circle.fill",
                        labelKey: "coach.certifications.expiring",
                        value: "\(expiringCount)",
                        valueColor: expiringCount > 0 ? .orange : .secondary
                    )
                    AthleteSummaryRow(
                        icon: "xmark.circle.fill",
                        labelKey: "coach.certifications.expired",
                        value: "\(expiredCount)",
                        valueColor: expiredCount > 0 ? .red : .secondary
                    )
                }
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private func sectionFor(severity: CertificationSeverity, titleKey: LocalizedStringKey, icon: String) -> some View {
        let filtered = certifications.filter { $0.severity == severity }
        if !filtered.isEmpty {
            SectionCard(titleKey, icon: icon) {
                VStack(spacing: 6) {
                    ForEach(filtered) { cert in
                        certRow(cert)
                        if cert.id != filtered.last?.id {
                            Divider().opacity(0.3)
                        }
                    }
                }
            }
        }
    }

    private func certRow(_ cert: Certification) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(severityColor(cert.severity).opacity(0.12))
                Image(systemName: kindIcon(cert.kind))
                    .scaledFont(.subheadline)
                    .foregroundStyle(severityColor(cert.severity))
            }
            .frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(localizedKey: cert.kind.labelKey)
                    .scaledFont(.subheadline, weight: .semibold)
                Text(verbatim: cert.issuer)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                Text(cert.expiresAt, format: .dateTime.day().month(.abbreviated).year())
                    .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                    .foregroundStyle(severityColor(cert.severity))
                    .environment(\.layoutDirection, .leftToRight)
                Text(verbatim: severityCaption(cert))
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func severityCaption(_ cert: Certification) -> String {
        let days = cert.daysUntilExpiry
        switch cert.severity {
        case .ok: return String(format: NSLocalizedString("coach.certifications.in_days", comment: ""), days)
        case .expiring: return String(format: NSLocalizedString("coach.certifications.in_days", comment: ""), days)
        case .expired: return String(format: NSLocalizedString("coach.certifications.expired_days", comment: ""), abs(days))
        }
    }

    private func severityColor(_ severity: CertificationSeverity) -> Color {
        switch severity {
        case .ok: .green
        case .expiring: .orange
        case .expired: .red
        }
    }

    private func kindIcon(_ kind: CertificationKind) -> String {
        switch kind {
        case .firstAid: "cross.case.fill"
        case .safeguarding: "shield.fill"
        case .wtCoaching: "rosette"
        case .doping: "drop.fill"
        case .refereeing: "flag.checkered"
        }
    }

    /// Coach struct carries its own expiry dates (firstAid, safeguarding, WT,
    /// anti-doping, referee tiers). Show them here as a Compliance Snapshot
    /// even when no separate Certification rows have been issued yet.
    private var embeddedCoachExpiriesCard: some View {
        SectionCard("coach.certifications.compliance_snapshot", icon: "checkmark.shield.fill") {
            VStack(spacing: 6) {
                expiryRow(labelKey: "cert.firstAid", date: coach.firstAidExpiry)
                expiryRow(labelKey: "cert.safeguarding", date: coach.safeguardingExpiry)
                if let wt = coach.wtCoachLicenceExpiry {
                    expiryRow(labelKey: "cert.wtCoaching", date: wt)
                }
                if let anti = coach.antiDopingExpiry {
                    expiryRow(labelKey: "cert.doping", date: anti)
                }
            }
        }
    }

    private func expiryRow(labelKey: LocalizedStringKey, date: Date) -> some View {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        let severity: CertificationSeverity = days < 0 ? .expired : (days < 60 ? .expiring : .ok)
        return HStack(spacing: 10) {
            Circle()
                .fill(severityColor(severity))
                .frame(width: 8, height: 8)
            Text(labelKey)
                .scaledFont(.footnote)
            Spacer(minLength: 8)
            Text(date, format: .dateTime.day().month(.abbreviated).year())
                .scaledFont(.footnote, weight: .semibold, monospacedDigit: true)
                .foregroundStyle(severityColor(severity))
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.vertical, 2)
    }

    private var activeCount: Int { certifications.filter { $0.severity == .ok }.count }
    private var expiringCount: Int { certifications.filter { $0.severity == .expiring }.count }
    private var expiredCount: Int { certifications.filter { $0.severity == .expired }.count }
}

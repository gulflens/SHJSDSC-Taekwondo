import SwiftUI

// MARK: - Certifications design kit
//
// Stage 1.10 — shared visual vocabulary for the Certifications compliance
// dashboard: severity colours, status icon/badge, the compliance ring, the
// expiry-metadata column, and the search field.

public extension CertificationSeverity {
    /// Pastel compliance accent — emerald / orange / red.
    var tint: Color {
        switch self {
        case .ok:       .secondaryAccent
        case .expiring: .orange
        case .expired:  .red
        }
    }

    /// Status-pill / legend label key.
    var statusLabelKey: String {
        switch self {
        case .ok:       "cert.status.active"
        case .expiring: "cert.status.expiring"
        case .expired:  "cert.status.expired"
        }
    }
}

/// "Nov 12, 2026" for a certification expiry.
func certDateText(_ date: Date) -> String {
    date.formatted(.dateTime.month(.abbreviated).day().year())
}

// MARK: - Status icon

/// Rounded pastel tile — the certification kind's glyph tinted by severity.
public struct CertificationStatusIcon: View {
    private let kind: CertificationKind
    private let severity: CertificationSeverity
    private let size: CGFloat

    public init(kind: CertificationKind, severity: CertificationSeverity, size: CGFloat = 40) {
        self.kind = kind
        self.severity = severity
        self.size = size
    }

    public var body: some View {
        Image(systemName: kind.systemIcon)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(severity.tint)
            .frame(width: size, height: size)
            .background(
                severity.tint.opacity(0.14),
                in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            )
    }
}

// MARK: - Status badge

/// Rounded pastel capsule — "Active / Expiring soon / Expired".
public struct StatusBadgeView: View {
    private let severity: CertificationSeverity

    public init(_ severity: CertificationSeverity) {
        self.severity = severity
    }

    public var body: some View {
        Text(localizedKey: severity.statusLabelKey)
            .scaledFont(.caption2, weight: .semibold)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(severity.tint.opacity(0.16), in: Capsule())
            .foregroundStyle(severity.tint)
    }
}

// MARK: - Expiry metadata

/// Expiry date (tinted by severity) over a soft relative caption
/// ("In 179 days" / "Expired 2557 days ago").
public struct ExpiryMetadataView: View {
    private let cert: Certification
    private let alignment: HorizontalAlignment

    public init(_ cert: Certification, alignment: HorizontalAlignment = .leading) {
        self.cert = cert
        self.alignment = alignment
    }

    public var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(verbatim: certDateText(cert.expiresAt))
                .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                .foregroundStyle(cert.severity.tint)
                .environment(\.layoutDirection, .leftToRight)
            Text(verbatim: relativeCaption)
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var relativeCaption: String {
        let days = cert.daysUntilExpiry
        if days < 0 {
            return String(format: NSLocalizedString("cert.expired_days_ago", comment: ""), abs(days))
        }
        return String(format: NSLocalizedString("cert.in_days", comment: ""), days)
    }
}

// MARK: - Compliance ring

/// Apple-Fitness-style ring — a track, a trimmed emerald progress arc, and a
/// big percentage with the "Compliance Health" caption.
public struct ComplianceRing: View {
    private let value: Double
    private let size: CGFloat

    public init(value: Double, size: CGFloat = 104) {
        self.value = min(1, max(0, value))
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.14), lineWidth: size * 0.1)
            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    LinearGradient(colors: [Color.secondaryAccent, Color.secondaryAccent.opacity(0.7)],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.secondaryAccent.opacity(0.35), radius: 5)
                .animation(.easeInOut(duration: 0.5), value: value)
            VStack(spacing: 1) {
                Text(verbatim: "\(Int((value * 100).rounded()))%")
                    .font(.system(size: size * 0.26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .environment(\.layoutDirection, .leftToRight)
                Text("cert.health")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(size * 0.14)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Search field

/// Rounded glass-material search field for the certifications header.
public struct SearchCertificationField: View {
    @Binding private var text: String

    public init(text: Binding<String>) {
        _text = text
    }

    public var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .scaledFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
            TextField(text: $text) { Text("cert.search") }
                .textFieldStyle(.plain)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .scaledFont(.footnote)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.secondary.opacity(0.14), lineWidth: 1))
    }
}

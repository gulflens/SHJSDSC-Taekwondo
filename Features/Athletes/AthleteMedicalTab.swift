import SwiftUI

/// Medical tab — vitals, allergies / conditions / medications chips, injury
/// log, weight history, and consent flags. Reuses existing InjuryLogCard +
/// WeightHistoryCard from Features/Athletes.
public struct AthleteMedicalTab: View {
    @Binding public var athlete: Athlete
    public let isWide: Bool

    public init(athlete: Binding<Athlete>, isWide: Bool) {
        _athlete = athlete
        self.isWide = isWide
    }

    public var body: some View {
        VStack(spacing: 14) {
            vitalsCard
            if isWide {
                HStack(alignment: .top, spacing: 14) {
                    allergiesCard.frame(maxWidth: .infinity)
                    conditionsCard.frame(maxWidth: .infinity)
                    medicationsCard.frame(maxWidth: .infinity)
                }
            } else {
                allergiesCard
                conditionsCard
                medicationsCard
            }
            clearanceCard
            SectionCard("medical.injury_log", icon: "bandage.fill") {
                InjuryLogCard(athlete: $athlete)
            }
            SectionCard("medical.weight_history", icon: "scalemass.fill") {
                WeightHistoryCard(athlete: $athlete)
            }
        }
    }

    // MARK: - Vitals

    private var vitalsCard: some View {
        SectionCard("medical.vitals", icon: "heart.text.square.fill") {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 4 : 2),
                spacing: 12
            ) {
                KPITile(
                    title: "medical.height",
                    value: athlete.heightCm.map { String(format: "%.0fcm", $0) } ?? "—",
                    icon: "ruler.fill"
                )
                KPITile(
                    title: "medical.weight",
                    value: String(format: "%.1fkg", athlete.weightKg),
                    icon: "scalemass.fill"
                )
                KPITile(
                    title: "medical.blood_group",
                    value: athlete.bloodType?.display ?? "—",
                    icon: "drop.fill"
                )
                KPITile(
                    title: "medical.fit_to_train",
                    value: athlete.fitToTrain
                        ? NSLocalizedString("medical.cleared", comment: "")
                        : NSLocalizedString("medical.restricted", comment: ""),
                    icon: athlete.fitToTrain ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
            }
        }
    }

    // MARK: - Chip cards

    private var allergiesCard: some View {
        SectionCard("medical.allergies", icon: "leaf.fill") {
            chipList(athlete.allergies, emptyKey: "medical.no_allergies", color: .green)
        }
    }

    private var conditionsCard: some View {
        SectionCard("medical.conditions", icon: "cross.case.fill") {
            chipList(athlete.medicalConditions, emptyKey: "medical.no_conditions", color: .orange)
        }
    }

    private var medicationsCard: some View {
        SectionCard("medical.medications", icon: "pills.fill") {
            chipList(athlete.medications, emptyKey: "medical.no_medications", color: .blue)
        }
    }

    private func chipList(_ items: [String], emptyKey: LocalizedStringKey, color: Color) -> some View {
        Group {
            if items.isEmpty {
                Text(emptyKey)
                    .scaledFont(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(items, id: \.self) { item in
                        Text(verbatim: item)
                            .scaledFont(.caption, weight: .medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(color.opacity(0.14), in: Capsule())
                            .foregroundStyle(color)
                    }
                }
            }
        }
    }

    // MARK: - Clearance / consent

    private var clearanceCard: some View {
        SectionCard("medical.clearance", icon: "doc.badge.gearshape.fill") {
            VStack(spacing: 6) {
                AthleteSummaryRow(
                    icon: "camera.fill",
                    labelKey: "consent.image_rights",
                    value: athlete.imageRightsConsent
                        ? NSLocalizedString("consent.granted", comment: "")
                        : NSLocalizedString("consent.missing", comment: ""),
                    valueColor: athlete.imageRightsConsent ? .green : .orange
                )
                AthleteSummaryRow(
                    icon: "airplane",
                    labelKey: "consent.travel",
                    value: athlete.travelPermission
                        ? NSLocalizedString("consent.granted", comment: "")
                        : NSLocalizedString("consent.missing", comment: ""),
                    valueColor: athlete.travelPermission ? .green : .orange
                )
                if let date = athlete.imageRightsConsentDate {
                    AthleteSummaryRow(
                        icon: "calendar",
                        labelKey: "consent.image_rights_date",
                        value: dateFormatter.string(from: date)
                    )
                }
                if let date = athlete.travelPermissionDate {
                    AthleteSummaryRow(
                        icon: "calendar",
                        labelKey: "consent.travel_date",
                        value: dateFormatter.string(from: date)
                    )
                }
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }
}

/// Wrapping flow layout used for the chip lists. Native to SwiftUI 16+ would
/// be `FlowLayout` from iOS 17 — we ship our own minimal variant so the file
/// has no platform-gated code paths.
private struct FlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 6) { self.spacing = spacing }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

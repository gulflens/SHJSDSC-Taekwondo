import SwiftUI

/// Documents tab — lists identity, federation and consent documents with
/// expiry status. Falls back to a comprehensive empty state when the dossier
/// is missing.
public struct AthleteDocumentsTab: View {
    public let athlete: Athlete
    public let canEdit: Bool
    public let onAdd: () -> Void

    public init(athlete: Athlete, canEdit: Bool, onAdd: @escaping () -> Void = {}) {
        self.athlete = athlete
        self.canEdit = canEdit
        self.onAdd = onAdd
    }

    public var body: some View {
        VStack(spacing: 14) {
            statusBanner
            SectionCard(
                "doc.section.identity",
                icon: "person.text.rectangle.fill",
                trailing: { addButton }
            ) {
                groupContent(filter: identityKinds)
            }
            SectionCard("doc.section.medical", icon: "cross.case.fill") {
                groupContent(filter: [.medicalClearance])
            }
            SectionCard("doc.section.consent", icon: "doc.text.fill") {
                groupContent(filter: [.imageRightsConsent, .travelPermission])
            }
            SectionCard("doc.section.federation", icon: "rosette") {
                groupContent(filter: [.federationLicence, .worldTaekwondoCard])
            }
            SectionCard("doc.section.other", icon: "doc.fill") {
                groupContent(filter: [.schoolID, .other])
            }
        }
    }

    private var statusBanner: some View {
        let total = AthleteDocumentKind.allCases.count
        let present = AthleteDocumentKind.allCases.filter { kind in
            athlete.documents.contains { $0.kind == kind }
        }.count
        let valid = athlete.documents.filter { $0.derivedStatus(asOf: Date()) == .valid }.count
        return SectionCard {
            HStack(spacing: 16) {
                ProgressRing(
                    value: total > 0 ? Double(present) / Double(total) : 0,
                    size: 80,
                    trackWidth: 8,
                    centerLabelKey: "doc.summary.completeness"
                )
                VStack(alignment: .leading, spacing: 6) {
                    Text("doc.summary.title")
                        .scaledFont(.subheadline, weight: .semibold)
                    AthleteSummaryRow(
                        icon: "doc.fill",
                        labelKey: "doc.summary.on_file",
                        value: "\(present) / \(total)"
                    )
                    AthleteSummaryRow(
                        icon: "checkmark.seal.fill",
                        labelKey: "doc.summary.valid",
                        value: "\(valid)",
                        valueColor: .green
                    )
                    let expiring = athlete.documents.filter {
                        $0.derivedStatus(asOf: Date()) == .expiringSoon || $0.derivedStatus(asOf: Date()) == .expired
                    }.count
                    if expiring > 0 {
                        AthleteSummaryRow(
                            icon: "exclamationmark.triangle.fill",
                            labelKey: "doc.summary.expiring",
                            value: "\(expiring)",
                            valueColor: .orange
                        )
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var addButton: some View {
        Group {
            if canEdit {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .scaledFont(.title3)
                        .foregroundStyle(.tint)
                }
                .accessibilityLabel(Text("doc.add"))
            }
        }
    }

    @ViewBuilder
    private func groupContent(filter kinds: [AthleteDocumentKind]) -> some View {
        let docs = athlete.documents.filter { kinds.contains($0.kind) }
        let missingKinds = kinds.filter { kind in
            !athlete.documents.contains(where: { $0.kind == kind })
        }
        VStack(spacing: 6) {
            ForEach(docs) { doc in
                DocumentRow(document: doc)
                    .padding(.vertical, 4)
                if doc.id != docs.last?.id || !missingKinds.isEmpty {
                    Divider().opacity(0.3)
                }
            }
            ForEach(missingKinds, id: \.rawValue) { kind in
                DocumentRow(document: AthleteDocument(kind: kind, status: .missing))
                    .opacity(0.55)
                    .padding(.vertical, 4)
                if kind != missingKinds.last {
                    Divider().opacity(0.3)
                }
            }
        }
    }

    private var identityKinds: [AthleteDocumentKind] {
        [.emiratesID, .passport]
    }
}

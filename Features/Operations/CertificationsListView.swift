import SwiftUI

public struct CertificationsListView: View {
    @Environment(AppSession.self) private var session
    @State private var store: CertificationsStore?
    @State private var coachLookup: [EntityID: Coach] = [:]
    @State private var coaches: [Coach] = []
    @State private var renewing: Certification?
    @State private var newExpiry: Date = Date().addingTimeInterval(365 * 24 * 3600)
    @State private var showingAdd = false

    public init() {}

    public var body: some View {
        Group {
            if let store {
                content(store: store)
            } else {
                ProgressView()
            }
        }
        .toolbar {
            if canEdit {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("cert.add"))
                    .bareToolbarButton()
                }
            }
        }
        .task {
            if store == nil { store = CertificationsStore(repository: session.repository) }
            await reload()
        }
        .sheet(item: $renewing) { cert in
            renewSheet(cert: cert)
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                AddCertificationSheet(coaches: coaches) { cert in
                    Task {
                        do {
                            try await session.repository.upsert(certification: cert)
                            await reload()
                        } catch {
                            print("CertificationsListView.add:", error)
                        }
                    }
                }
            }
        }
    }

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editCoach)
    }

    @ViewBuilder
    private func content(store: CertificationsStore) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                healthBanner(store: store)
                if store.certifications.isEmpty {
                    SectionCard {
                        EmptyStateCard(
                            icon: "checkmark.shield",
                            titleKey: "cert.empty.title",
                            messageKey: "cert.empty.message"
                        )
                    }
                } else {
                    sections(store: store)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    private func healthBanner(store: CertificationsStore) -> some View {
        let total = store.certifications.count
        let ok = store.certifications.filter { $0.severity == .ok }.count
        let expiring = store.expiringSoon.count
        let expired = store.expired.count
        let health = total > 0 ? Double(ok) / Double(total) : 0
        return SectionCard {
            HStack(alignment: .top, spacing: 16) {
                ProgressRing(
                    value: health,
                    size: 96,
                    trackWidth: 9,
                    centerLabelKey: "cert.health"
                )
                VStack(alignment: .leading, spacing: 6) {
                    Text("cert.dashboard_title")
                        .scaledFont(.subheadline, weight: .semibold)
                    AthleteSummaryRow(
                        icon: "checkmark.circle.fill",
                        labelKey: "cert.active",
                        value: "\(ok)",
                        valueColor: .green
                    )
                    AthleteSummaryRow(
                        icon: "exclamationmark.circle.fill",
                        labelKey: "cert.expiring",
                        value: "\(expiring)",
                        valueColor: expiring > 0 ? .orange : .secondary
                    )
                    AthleteSummaryRow(
                        icon: "xmark.circle.fill",
                        labelKey: "cert.expired",
                        value: "\(expired)",
                        valueColor: expired > 0 ? .red : .secondary
                    )
                }
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private func sections(store: CertificationsStore) -> some View {
        if !store.expired.isEmpty {
            SectionCard("cert.section.expired", icon: "xmark.octagon.fill") {
                certList(store.expired)
            }
        }
        if !store.expiringSoon.isEmpty {
            SectionCard("cert.section.expiring", icon: "exclamationmark.triangle.fill") {
                certList(store.expiringSoon)
            }
        }
        let ok = store.certifications.filter { $0.severity == .ok }
        if !ok.isEmpty {
            SectionCard("cert.section.active", icon: "checkmark.seal.fill") {
                certList(ok)
            }
        }
    }

    private func certList(_ certs: [Certification]) -> some View {
        VStack(spacing: 6) {
            ForEach(certs) { cert in
                certRow(cert: cert)
                if cert.id != certs.last?.id {
                    Divider().opacity(0.3)
                }
            }
        }
    }

    private func certRow(cert: Certification) -> some View {
        Button {
            renewing = cert
            newExpiry = max(cert.expiresAt, Date()).addingTimeInterval(365 * 24 * 3600)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(severityColor(cert.severity).opacity(0.12))
                    Image(systemName: kindIcon(cert.kind))
                        .scaledFont(.subheadline)
                        .foregroundStyle(severityColor(cert.severity))
                }
                .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizedKey: cert.kind.labelKey)
                        .scaledFont(.subheadline, weight: .semibold)
                    if let coach = coachLookup[cert.coachID] {
                        Text(verbatim: coach.fullName)
                            .scaledFont(.caption2)
                            .foregroundStyle(.secondary)
                    }
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
                    Text(verbatim: daysCaption(cert))
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func daysCaption(_ cert: Certification) -> String {
        let days = cert.daysUntilExpiry
        if days < 0 {
            return String(format: NSLocalizedString("cert.expired_days_ago", comment: ""), abs(days))
        }
        return String(format: NSLocalizedString("cert.in_days", comment: ""), days)
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

    private func renewSheet(cert: Certification) -> some View {
        NavigationStack {
            Form {
                Section(header: Text("cert.renew")) {
                    HStack {
                        Text(localizedKey: cert.kind.labelKey)
                        Spacer()
                        Text(verbatim: cert.issuer).foregroundStyle(.secondary)
                    }
                    DatePicker("cert.new_expiry", selection: $newExpiry, in: Date()...)
                }
                Section {
                    Button {
                        Task {
                            await store?.renew(cert, newExpiry: newExpiry)
                            await reload()
                            renewing = nil
                        }
                    } label: { Text("action.save") }
                }
            }
            .navigationTitle(Text("cert.renew"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") { renewing = nil }
                    .bareToolbarButton()
                }
            }
        }
    }

    private func severityDot(_ s: CertificationSeverity) -> some View {
        Circle()
            .fill(severityColor(s))
            .frame(width: 10, height: 10)
    }

    private func severityColor(_ s: CertificationSeverity) -> Color {
        switch s {
        case .ok: .green
        case .expiring: .orange
        case .expired: .red
        }
    }

    private func reload() async {
        await store?.loadAll()
        do {
            let loaded = try await session.repository.coaches()
            self.coaches = loaded
            coachLookup = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        } catch {
            print("CertificationsListView.reload:", error)
        }
    }
}

// MARK: - Add sheet

private struct AddCertificationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let coaches: [Coach]
    let onSave: (Certification) -> Void

    @State private var coachID: EntityID?
    @State private var kind: CertificationKind = .firstAid
    @State private var issuer: String = ""
    @State private var issuedAt: Date = Date()
    @State private var expiresAt: Date = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()

    var body: some View {
        Form {
            Section {
                Picker("cert.coach", selection: $coachID) {
                    Text("cert.coach_select").tag(EntityID?.none)
                    ForEach(coaches) { coach in
                        Text(verbatim: coach.fullName).tag(EntityID?.some(coach.id))
                    }
                }
                Picker("cert.kind", selection: $kind) {
                    ForEach(CertificationKind.allCases, id: \.self) { k in
                        Text(localizedKey: k.labelKey).tag(k)
                    }
                }
                TextField("cert.issuer", text: $issuer)
            } header: {
                Text("cert.add_section")
            }

            Section {
                DatePicker("cert.issued_at", selection: $issuedAt, displayedComponents: .date)
                DatePicker("cert.new_expiry", selection: $expiresAt, in: issuedAt..., displayedComponents: .date)
            } header: {
                Text("cert.dates")
            }
        }
        .navigationTitle(Text("cert.add"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
                .bareToolbarButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("action.save") {
                    guard let coachID else { return }
                    let cert = Certification(
                        coachID: coachID,
                        kind: kind,
                        issuer: issuer,
                        issuedAt: issuedAt,
                        expiresAt: expiresAt
                    )
                    onSave(cert)
                    dismiss()
                }
                .disabled(coachID == nil || issuer.trimmingCharacters(in: .whitespaces).isEmpty)
                .bareToolbarButton()
            }
        }
    }
}

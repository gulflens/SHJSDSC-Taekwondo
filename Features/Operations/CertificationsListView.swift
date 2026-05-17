import SwiftUI

// MARK: - Certifications
//
// Stage 1.10 — federation-grade compliance dashboard. Fixed header +
// compliance overview card + status filter pills + a custom certifications
// table with pagination. Single-column (no detail panel) so the page scrolls
// as one surface.

public struct CertificationsListView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var hSize

    @State private var store: CertificationsStore?
    @State private var coachLookup: [EntityID: Coach] = [:]
    @State private var coaches: [Coach] = []
    @State private var renewing: Certification?
    @State private var newExpiry: Date = Date().addingTimeInterval(365 * 24 * 3600)
    @State private var showingAdd = false
    @State private var search = ""
    @State private var statusFilter: CertificationSeverity?
    @State private var kindFilter: CertificationKind?
    @State private var page = 0

    @State private var rowsPerPage = 10

    public init() {}

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        VStack(spacing: 0) {
            header
            if let store {
                content(store)
            } else {
                Spacer(); ProgressView(); Spacer()
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task {
            if store == nil { store = CertificationsStore(repository: session.repository) }
            await reload()
        }
        .onChange(of: search) { _, _ in page = 0 }
        .onChange(of: statusFilter) { _, _ in page = 0 }
        .onChange(of: kindFilter) { _, _ in page = 0 }
        .onChange(of: rowsPerPage) { _, _ in page = 0 }
        .sheet(item: $renewing) { cert in renewSheet(cert: cert) }
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

    // MARK: Header

    private var header: some View {
        Group {
            if isWide {
                HStack(alignment: .center, spacing: 12) {
                    title
                    Spacer(minLength: 8)
                    SearchCertificationField(text: $search).frame(maxWidth: 240)
                    filterButton
                    if canEdit { addButton }
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        title
                        Spacer(minLength: 8)
                        filterButton
                        if canEdit { addButton }
                    }
                    SearchCertificationField(text: $search)
                }
            }
        }
        .padding(.horizontal, isWide ? 22 : 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var title: some View {
        Text("cert.title").scaledFont(.title2, weight: .bold)
    }

    private var filterButton: some View {
        Menu {
            Picker("cert.filter.kind", selection: $kindFilter) {
                Text("cert.filter.all_kinds").tag(CertificationKind?.none)
                ForEach(CertificationKind.allCases, id: \.self) { k in
                    Text(localizedKey: k.labelKey).tag(CertificationKind?.some(k))
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease")
                    .scaledFont(.caption, weight: .semibold)
                Text("cert.filter").scaledFont(.subheadline, weight: .semibold)
            }
            .foregroundStyle(kindFilter == nil ? Color.primary : Color.accentColor)
            .padding(.horizontal, 13).padding(.vertical, 8)
            .background(
                Capsule().fill(kindFilter == nil
                               ? Color.secondary.opacity(0.10)
                               : Color.accentColor.opacity(0.14))
            )
            .overlay(Capsule().stroke(Color.secondary.opacity(0.16), lineWidth: 1))
        }
        .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
    }

    private var addButton: some View {
        Button { showingAdd = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus").scaledFont(.footnote, weight: .semibold)
                Text("cert.add").scaledFont(.subheadline, weight: .semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(
                Capsule().fill(LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.82)],
                    startPoint: .top, endPoint: .bottom)))
            .shadow(color: Color.accentColor.opacity(0.32), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: Content

    private func content(_ store: CertificationsStore) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                complianceCard(store)
                filterPills
                if store.certifications.isEmpty {
                    EmptyStateCard(icon: "checkmark.shield",
                                   titleKey: "cert.empty.title",
                                   messageKey: "cert.empty.message")
                        .padding(.top, 8)
                } else {
                    tableCard
                }
            }
            .padding(.horizontal, isWide ? 22 : 14)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
    }

    // MARK: Compliance overview card

    private func complianceCard(_ store: CertificationsStore) -> some View {
        let total = store.certifications.count
        let active = store.certifications.filter { $0.severity == .ok }.count
        let expiring = store.expiringSoon.count
        let expired = store.expired.count
        let health = total > 0 ? Double(active) / Double(total) : 0
        return HStack(alignment: .center, spacing: isWide ? 28 : 18) {
            ComplianceRing(value: health, size: isWide ? 116 : 100)
            VStack(alignment: .leading, spacing: 10) {
                Text("cert.overview")
                    .scaledFont(.headline, weight: .semibold)
                legendRow(.ok, count: active)
                legendRow(.expiring, count: expiring)
                legendRow(.expired, count: expired)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.cardBackground)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color.secondaryAccent.opacity(0.10), .clear],
                        startPoint: .trailing, endPoint: .leading))
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 150))
                    .foregroundStyle(Color.secondaryAccent.opacity(0.06))
                    .offset(x: 30)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }

    private func legendRow(_ severity: CertificationSeverity, count: Int) -> some View {
        HStack(spacing: 9) {
            Image(systemName: "circle.fill")
                .font(.system(size: 9))
                .foregroundStyle(severity.tint)
            Text(localizedKey: severity.statusLabelKey)
                .scaledFont(.subheadline)
            Spacer(minLength: 12)
            Text(verbatim: "\(count)")
                .scaledFont(.headline, weight: .bold)
                .monospacedDigit()
                .foregroundStyle(severity.tint)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    // MARK: Filter pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                pill(nil, "cert.filter.all")
                pill(.ok, "cert.status.active")
                pill(.expiring, "cert.status.expiring")
                pill(.expired, "cert.status.expired")
            }
            .padding(.horizontal, 2)
        }
    }

    private func pill(_ severity: CertificationSeverity?, _ titleKey: String) -> some View {
        let on = statusFilter == severity
        return Button {
            withAnimation(.easeInOut(duration: 0.16)) { statusFilter = severity }
        } label: {
            Text(localizedKey: titleKey)
                .scaledFont(.caption, weight: .semibold)
                .padding(.horizontal, 13).padding(.vertical, 7)
                .foregroundStyle(on ? Color.white : Color.primary)
                .background(Capsule().fill(on ? Color.accentColor : Color.secondary.opacity(0.10)))
                .shadow(color: on ? Color.accentColor.opacity(0.3) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: Table

    private var tableCard: some View {
        VStack(spacing: 0) {
            if isWide { columnHeader }
            if filtered.isEmpty {
                EmptyStateCard(icon: "magnifyingglass",
                               titleKey: "cert.empty.filtered.title",
                               messageKey: "cert.empty.filtered.message")
                    .padding(.vertical, 12)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(pageSlice.enumerated()), id: \.element.id) { idx, cert in
                        if idx > 0 { Divider().opacity(0.4) }
                        certRow(cert)
                    }
                }
                Divider().opacity(0.5)
                paginationFooter
            }
        }
        .padding(isWide ? 6 : 8)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }

    private var columnHeader: some View {
        HStack(spacing: 12) {
            Text("cert.col.certificate")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("cert.col.branch")
                .frame(width: 170, alignment: .leading)
            Text("cert.col.status")
                .frame(width: 116, alignment: .leading)
            Text("cert.col.expiry")
                .frame(width: 140, alignment: .leading)
            Color.clear.frame(width: 30)
        }
        .scaledFont(.caption2, weight: .semibold)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func certRow(_ cert: Certification) -> some View {
        if isWide {
            HStack(spacing: 12) {
                certificateCell(cert).frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: branchName(cert)).scaledFont(.subheadline, weight: .medium)
                    Text(localizedKey: cert.kind.categoryLabelKey)
                        .scaledFont(.caption2).foregroundStyle(.secondary)
                }
                .frame(width: 170, alignment: .leading)
                StatusBadgeView(cert.severity).frame(width: 116, alignment: .leading)
                ExpiryMetadataView(cert).frame(width: 140, alignment: .leading)
                actionsMenu(cert).frame(width: 30)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    certificateCell(cert)
                    Spacer(minLength: 6)
                    actionsMenu(cert)
                }
                HStack(spacing: 8) {
                    StatusBadgeView(cert.severity)
                    Text(verbatim: branchName(cert) + " · "
                         + NSLocalizedString(cert.kind.categoryLabelKey, comment: ""))
                        .scaledFont(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    Spacer(minLength: 6)
                    ExpiryMetadataView(cert, alignment: .trailing)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }

    private func certificateCell(_ cert: Certification) -> some View {
        HStack(spacing: 11) {
            CertificationStatusIcon(kind: cert.kind, severity: cert.severity, size: 42)
            VStack(alignment: .leading, spacing: 1) {
                Text(localizedKey: cert.kind.labelKey)
                    .scaledFont(.subheadline, weight: .bold)
                    .lineLimit(1)
                Text(verbatim: coachLookup[cert.coachID]?.fullName ?? "—")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(verbatim: cert.issuer)
                    .scaledFont(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func actionsMenu(_ cert: Certification) -> some View {
        if canEdit {
            Menu {
                Button {
                    renewing = cert
                    newExpiry = max(cert.expiresAt, Date()).addingTimeInterval(365 * 24 * 3600)
                } label: { Label("cert.renew", systemImage: "arrow.clockwise") }
            } label: {
                Image(systemName: "ellipsis")
                    .scaledFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 28)
                    .contentShape(Rectangle())
            }
            .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
        } else {
            Color.clear.frame(width: 30, height: 28)
        }
    }

    // MARK: Pagination

    private var paginationFooter: some View {
        let total = filtered.count
        let lower = total == 0 ? 0 : page * rowsPerPage + 1
        let upper = min(total, (page + 1) * rowsPerPage)
        return HStack(spacing: 10) {
            RowsPerPageMenu(rowsPerPage: $rowsPerPage)
            Text(verbatim: String(format: NSLocalizedString("cert.showing.fmt", comment: ""),
                                   lower, upper, total))
                .scaledFont(.caption2).foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                pagerButton("chevron.left", enabled: page > 0) { page -= 1 }
                ForEach(0..<min(pageCount, 5), id: \.self) { i in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { page = i }
                    } label: {
                        Text(verbatim: "\(i + 1)")
                            .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                            .frame(width: 28, height: 28)
                            .foregroundStyle(page == i ? Color.white : Color.primary)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(page == i ? Color.accentColor : Color.secondary.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                }
                pagerButton("chevron.right", enabled: page + 1 < pageCount) { page += 1 }
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }

    private func pagerButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.15), action) } label: {
            Image(systemName: icon)
                .scaledFont(.caption, weight: .semibold)
                .frame(width: 28, height: 28)
                .background(Color.secondary.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain).disabled(!enabled).opacity(enabled ? 1 : 0.4)
    }

    // MARK: Data

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editCoach)
    }

    private var filtered: [Certification] {
        var out = store?.certifications ?? []
        if let statusFilter { out = out.filter { $0.severity == statusFilter } }
        if let kindFilter { out = out.filter { $0.kind == kindFilter } }
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            out = out.filter { cert in
                let name = coachLookup[cert.coachID]?.fullName ?? ""
                let hay = "\(NSLocalizedString(cert.kind.labelKey, comment: "")) \(name) \(cert.issuer) \(branchName(cert))"
                return hay.lowercased().contains(q)
            }
        }
        return out.sorted {
            if $0.severity != $1.severity {
                return severityRank($0.severity) < severityRank($1.severity)
            }
            return $0.expiresAt < $1.expiresAt
        }
    }

    private func severityRank(_ s: CertificationSeverity) -> Int {
        switch s {
        case .ok: 0
        case .expiring: 1
        case .expired: 2
        }
    }

    private var pageCount: Int {
        max(1, Int(ceil(Double(filtered.count) / Double(rowsPerPage))))
    }

    private var pageSlice: [Certification] {
        let all = filtered
        guard !all.isEmpty else { return [] }
        let safe = min(page, pageCount - 1)
        let start = safe * rowsPerPage
        return Array(all[start..<min(start + rowsPerPage, all.count)])
    }

    private func branchName(_ cert: Certification) -> String {
        guard let coach = coachLookup[cert.coachID],
              let branch = session.branch(id: coach.primaryBranchID) else {
            return NSLocalizedString("admin.no_branch", comment: "")
        }
        return branch.name
    }

    private func reload() async {
        await store?.loadAll()
        do {
            let loaded = try await session.repository.coaches()
            coaches = loaded
            coachLookup = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        } catch {
            print("CertificationsListView.reload:", error)
        }
    }

    // MARK: Renew sheet

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
                }
            }
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
            }
        }
    }
}

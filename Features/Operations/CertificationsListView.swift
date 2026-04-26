import SwiftUI

public struct CertificationsListView: View {
    @Environment(AppSession.self) private var session
    @State private var store: CertificationsStore?
    @State private var coachLookup: [EntityID: Coach] = [:]
    @State private var renewing: Certification?
    @State private var newExpiry: Date = Date().addingTimeInterval(365 * 24 * 3600)

    public init() {}

    public var body: some View {
        Group {
            if let store {
                content(store: store)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(Text("tab.certifications"))
        .task {
            if store == nil { store = CertificationsStore(repository: session.repository) }
            await reload()
        }
        .sheet(item: $renewing) { cert in
            renewSheet(cert: cert)
        }
    }

    @ViewBuilder
    private func content(store: CertificationsStore) -> some View {
        List {
            if !store.expired.isEmpty {
                Section(header: Text("cert.expired")) {
                    ForEach(store.expired) { row(cert: $0) }
                }
            }
            if !store.expiringSoon.isEmpty {
                Section(header: Text("cert.expiring")) {
                    ForEach(store.expiringSoon) { row(cert: $0) }
                }
            }
            let ok = store.certifications.filter { $0.severity == .ok }
            if !ok.isEmpty {
                Section(header: Text("cert.ok")) {
                    ForEach(ok) { row(cert: $0) }
                }
            }
            if store.certifications.isEmpty {
                Text("empty.no_certifications").foregroundStyle(.secondary)
            }
        }
    }

    private func row(cert: Certification) -> some View {
        HStack(spacing: 10) {
            severityDot(cert.severity)
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(cert.kind.labelKey)).font(.subheadline.bold())
                if let coach = coachLookup[cert.coachID] {
                    Text(verbatim: coach.fullName).font(.caption).foregroundStyle(.secondary)
                }
                Text(verbatim: cert.issuer).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(cert.expiresAt, style: .date).font(.caption.monospacedDigit())
                    .environment(\.layoutDirection, .leftToRight)
                Text(LocalizedStringKey(cert.severity.labelKey))
                    .font(.caption2)
                    .foregroundStyle(severityColor(cert.severity))
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            renewing = cert
            newExpiry = max(cert.expiresAt, Date()).addingTimeInterval(365 * 24 * 3600)
        }
    }

    private func renewSheet(cert: Certification) -> some View {
        NavigationStack {
            Form {
                Section(header: Text("cert.renew")) {
                    HStack {
                        Text(LocalizedStringKey(cert.kind.labelKey))
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
            let coaches = try await session.repository.coaches()
            coachLookup = Dictionary(uniqueKeysWithValues: coaches.map { ($0.id, $0) })
        } catch {
            print("CertificationsListView.reload:", error)
        }
    }
}

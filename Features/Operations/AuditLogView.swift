import SwiftUI

public struct AuditLogView: View {
    @Environment(AppSession.self) private var session
    @State private var store: AuditStore?
    @State private var selectedActor: EntityID?
    @State private var sinceDate: Date = Date().addingTimeInterval(-30 * 24 * 3600)
    @State private var users: [User] = []

    public init() {}

    public var body: some View {
        Group {
            if let store {
                content(store: store)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(Text("audit.title"))
        .task {
            if store == nil { store = AuditStore(repository: session.repository) }
            users = (try? await session.repository.availableUsers()) ?? []
            await reload()
        }
    }

    @ViewBuilder
    private func content(store: AuditStore) -> some View {
        VStack(spacing: 0) {
            HStack {
                Picker(selection: $selectedActor) {
                    Text("filter.all").tag(EntityID?.none)
                    ForEach(users) { u in
                        Text(verbatim: u.fullName).tag(Optional(u.id))
                    }
                } label: {
                    Text("audit.actor")
                }
                .onChange(of: selectedActor) { _, _ in
                    Task { await reload() }
                }
                DatePicker("audit.since", selection: $sinceDate, displayedComponents: .date)
                    .labelsHidden()
                    .onChange(of: sinceDate) { _, _ in
                        Task { await reload() }
                    }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            List(store.entries) { entry in
                row(entry: entry, store: store)
            }
        }
    }

    private func row(entry: AuditEntry, store: AuditStore) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(verbatim: entry.action).font(.subheadline.bold())
                Spacer()
                Text(entry.at, style: .time).font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            HStack(spacing: 6) {
                Image(systemName: "person.fill").font(.caption2)
                Text(verbatim: store.userLookup[entry.actorUserID]?.fullName ?? "—")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: "·").font(.caption)
                Text(verbatim: entry.targetEntity).font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !entry.changes.isEmpty {
                Text(verbatim: entry.changes.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func reload() async {
        store?.actorFilter = selectedActor
        store?.sinceFilter = sinceDate
        await store?.load()
    }
}

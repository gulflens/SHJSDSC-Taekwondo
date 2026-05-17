import SwiftUI

public struct SquadListView: View {
    @Environment(AppSession.self) private var session
    @State private var store: AthleteGroupStore?
    @State private var showingCreate = false
    @State private var showArchived = false

    public init() {}

    public var body: some View {
        Group {
            if let store {
                content(store: store)
            } else {
                ProgressView()
            }
        }
        .subviewChrome(Text("squad.title")) {
            Button { showingCreate = true } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel(Text("squad.create"))
        }
        .sheet(isPresented: $showingCreate) {
            if let store {
                NavigationStack {
                    CreateSquadView { group in
                        Task { await store.save(group) }
                    }
                }
            }
        }
        .task {
            if store == nil { store = AthleteGroupStore(repository: session.repository) }
            await store?.load()
        }
    }

    @ViewBuilder
    private func content(store: AthleteGroupStore) -> some View {
        List {
            if store.activeGroups.isEmpty && store.archivedGroups.isEmpty {
                Text("squad.empty").foregroundStyle(.secondary)
            }

            if !store.activeGroups.isEmpty {
                Section(header: Text("squad.active")) {
                    ForEach(store.activeGroups) { group in
                        NavigationLink(destination: SquadDetailView(group: group)) {
                            SquadRow(group: group)
                        }
                    }
                    .onDelete { offsets in
                        let active = store.activeGroups
                        for i in offsets {
                            Task { await store.archive(active[i]) }
                        }
                    }
                }
            }

            if !store.archivedGroups.isEmpty {
                Section(header: Text("squad.archived")) {
                    DisclosureGroup(isExpanded: $showArchived) {
                        ForEach(store.archivedGroups) { group in
                            NavigationLink(destination: SquadDetailView(group: group)) {
                                SquadRow(group: group)
                                    .opacity(0.6)
                            }
                        }
                        .onDelete { offsets in
                            let archived = store.archivedGroups
                            for i in offsets {
                                Task { await store.delete(id: archived[i].id) }
                            }
                        }
                    } label: {
                        Text("squad.show_archived (\(store.archivedGroups.count))")
                    }
                }
            }
        }
    }
}

private struct SquadRow: View {
    let group: AthleteGroup

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: purposeIcon)
                .scaledFont(.title3)
                .foregroundStyle(purposeColor)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: group.name).scaledFont(.headline)
                HStack(spacing: 6) {
                    Text(localizedKey: group.purpose.labelKey)
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                    Text(verbatim: "·")
                        .foregroundStyle(.secondary)
                    Text("squad.member_count \(group.athleteIDs.count)")
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                }
                if let expiresAt = group.expiresAt {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(expiresAt, style: .date)
                    }
                    .scaledFont(.caption2)
                    .foregroundStyle(group.isExpired ? .red : .orange)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var purposeIcon: String {
        switch group.purpose {
        case .competition: "trophy"
        case .trainingCamp: "figure.martial.arts"
        case .grading: "rosette"
        case .notification: "bell"
        case .custom: "person.3"
        }
    }

    private var purposeColor: Color {
        switch group.purpose {
        case .competition: .orange
        case .trainingCamp: .blue
        case .grading: .green
        case .notification: .purple
        case .custom: .secondary
        }
    }
}

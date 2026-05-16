import SwiftUI

public struct TournamentListView: View {
    @Environment(AppSession.self) private var session
    @State private var store: TournamentsStore?
    @State private var scope: Scope = .upcoming
    @State private var showingAdd = false

    public enum Scope: Hashable { case upcoming, past }

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
            if canCreate {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("tournament.add"))
                    .bareToolbarButton()
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                AddTournamentView { _ in
                    Task { await store?.loadTournaments() }
                }
            }
        }
        .task {
            if store == nil { store = TournamentsStore(repository: session.repository) }
            await store?.loadTournaments()
        }
    }

    private var canCreate: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .createTournament)
    }

    @ViewBuilder
    private func content(store: TournamentsStore) -> some View {
        VStack(spacing: 0) {
            Picker(selection: $scope) {
                Text("tournament.upcoming").tag(Scope.upcoming)
                Text("tournament.past").tag(Scope.past)
            } label: { EmptyView() }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal)
            .padding(.top, 8)

            let items = scope == .upcoming ? store.upcoming : store.past
            List {
                if items.isEmpty {
                    Text("empty.no_tournaments").foregroundStyle(.secondary)
                } else {
                    ForEach(items) { t in
                        NavigationLink(destination: TournamentDetailView(tournamentID: t.id)) {
                            row(tournament: t)
                        }
                    }
                }
            }
        }
    }

    private func row(tournament t: Tournament) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(verbatim: t.name).scaledFont(.headline)
                Spacer()
                if t.isOfficial {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.tint)
                        .accessibilityLabel(Text("tournament.official"))
                }
            }
            if let nameAr = t.nameAr {
                Text(verbatim: nameAr).scaledFont(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .scaledFont(.caption2)
                Text(t.startsAt, style: .date).scaledFont(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(verbatim: t.location).scaledFont(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

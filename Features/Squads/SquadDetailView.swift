import SwiftUI

public struct SquadDetailView: View {
    @Environment(AppSession.self) private var session
    @State private var group: AthleteGroup
    @State private var members: [Athlete] = []
    @State private var tournament: Tournament?
    @State private var showingEdit = false
    @State private var store: AthleteGroupStore?

    public init(group: AthleteGroup) {
        _group = State(initialValue: group)
    }

    public var body: some View {
        List {
            headerSection
            if let tournament {
                tournamentSection(tournament)
            }
            if let notes = group.notes, !notes.isEmpty {
                Section(header: Text("squad.notes")) {
                    Text(verbatim: notes).scaledFont(.subheadline)
                }
            }
            membersSection
        }
        .navigationTitle(Text(verbatim: group.name))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel(Text("squad.edit"))
                .bareToolbarButton()
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                CreateSquadView(existing: group) { updated in
                    Task {
                        await store?.save(updated)
                        group = updated
                        await loadMembers()
                    }
                }
            }
        }
        .task {
            if store == nil { store = AthleteGroupStore(repository: session.repository) }
            await loadMembers()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    PurposeBadge(purpose: group.purpose)
                    if group.isExpired {
                        Text("squad.expired")
                            .scaledFont(.caption, weight: .bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    } else if group.isArchived {
                        Text("squad.archived_label")
                            .scaledFont(.caption, weight: .bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }
                }
                if let nameAr = group.nameAr {
                    Text(verbatim: nameAr)
                        .scaledFont(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 16) {
                    Label {
                        Text(verbatim: "\(group.athleteIDs.count)")
                    } icon: {
                        Image(systemName: "person.3")
                    }
                    .scaledFont(.subheadline)

                    if let expiresAt = group.expiresAt {
                        Label {
                            Text(expiresAt, style: .date)
                        } icon: {
                            Image(systemName: "calendar.badge.clock")
                        }
                        .scaledFont(.subheadline)
                        .foregroundStyle(group.isExpired ? .red : .primary)
                    }
                }
                if let nat = group.nationalityFilter {
                    filterPill(icon: "flag", text: nat == "AE" ? String(localized: "squad.filter.emirati_only") : nat)
                }
                if let ag = group.ageGroupFilter {
                    filterPill(icon: "person.crop.circle", text: String(localized: LocalizedStringResource(stringLiteral: ag.labelKey)))
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func tournamentSection(_ tournament: Tournament) -> some View {
        Section(header: Text("squad.linked_tournament")) {
            HStack(spacing: 10) {
                Image(systemName: "trophy").foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: tournament.name).scaledFont(.subheadline, weight: .bold)
                    HStack(spacing: 4) {
                        Text(tournament.startsAt, style: .date)
                        Text(verbatim: "—")
                        Text(tournament.endsAt, style: .date)
                    }
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var membersSection: some View {
        Section(header: Text("squad.members (\(members.count))")) {
            if members.isEmpty {
                Text("squad.no_members").foregroundStyle(.secondary)
            } else {
                ForEach(members) { athlete in
                    NavigationLink(destination: AthleteDetailView(athlete: athlete)) {
                        HStack(spacing: 10) {
                            Avatar(seed: athlete.avatarSeed, label: athlete.initials, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: athlete.fullName).scaledFont(.subheadline)
                                HStack(spacing: 4) {
                                    Text(localizedKey: athlete.currentBelt.label)
                                    Text(verbatim: "·")
                                    Text(localizedKey: athlete.ageGroup.labelKey)
                                    if athlete.nationality == "AE" {
                                        Text(verbatim: "🇦🇪")
                                    }
                                }
                                .scaledFont(.caption2)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            StatusPill(status: athlete.status)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func filterPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(verbatim: text)
        }
        .scaledFont(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.blue.opacity(0.10))
        .foregroundStyle(.blue)
        .clipShape(Capsule())
    }

    private func loadMembers() async {
        do {
            let all = try await session.repository.athletes()
            let idSet = Set(group.athleteIDs)
            members = all.filter { idSet.contains($0.id) }
                .sorted { $0.fullName < $1.fullName }
            if let tid = group.linkedTournamentID {
                tournament = try await session.repository.tournament(id: tid)
            }
        } catch {
            print("SquadDetailView.loadMembers:", error)
        }
    }
}

private struct PurposeBadge: View {
    let purpose: SquadPurpose

    var body: some View {
        Text(localizedKey: purpose.labelKey)
            .scaledFont(.caption, weight: .bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch purpose {
        case .competition: .orange
        case .trainingCamp: .blue
        case .grading: .green
        case .notification: .purple
        case .custom: .secondary
        }
    }
}

import SwiftUI

public struct CoachListView: View {
    @Environment(AppSession.self) private var session
    @State private var coaches: [Coach] = []
    @State private var branches: [EntityID: Branch] = [:]
    @State private var query: String = ""
    @State private var showingAdd = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            AppSearchField(text: $query)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

            List {
                let filtered = coaches.filter { c in
                    query.isEmpty
                        || c.fullName.localizedCaseInsensitiveContains(query)
                        || c.fullNameAr.contains(query)
                }
                if filtered.isEmpty {
                    Text("empty.search_no_results").foregroundStyle(.secondary)
                } else {
                    ForEach(filtered) { c in
                        NavigationLink(destination: CoachDetailView(coach: c)) {
                            CoachRow(coach: c, branch: branches[c.primaryBranchID])
                        }
                    }
                }
            }
        }
        .toolbar {
            if let role = session.currentUser?.role,
               PermissionMatrix.allowed(role: role, permission: .editCoach) {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("coach.add"))
                    .bareToolbarButton()
                }
            }
        }
        .navigationDestination(isPresented: $showingAdd) {
            AddCoachView(initialBranchID: session.currentUser?.primaryBranchID) { newCoach in
                if let i = coaches.firstIndex(where: { $0.id == newCoach.id }) {
                    coaches[i] = newCoach
                } else {
                    coaches.append(newCoach)
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            coaches = try await session.repository.coaches()
            let bs = try await session.repository.branches()
            branches = Dictionary(uniqueKeysWithValues: bs.map { ($0.id, $0) })
        } catch {
            print("CoachListView.load:", error)
        }
    }
}

private struct CoachRow: View {
    let coach: Coach
    let branch: Branch?

    var body: some View {
        HStack(spacing: 12) {
            Avatar(seed: coach.avatarSeed, label: coach.initials)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: coach.fullName)
                HStack(spacing: 6) {
                    if let branch {
                        Text(verbatim: branch.name)
                            .scaledFont(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if coach.onCall {
                        Text("coach.on_call_short")
                            .scaledFont(.caption2, weight: .bold)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Color.green.opacity(0.18), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }
            }
            Spacer()
            expiryWarning
            Text(verbatim: "\(coach.danRank) Dan")
                .scaledFont(.caption, weight: .bold)
                .foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
                .help(Text("tooltip.dan"))
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var expiryWarning: some View {
        if let next = coach.nextCertificationExpiry {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0
            if days < 0 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .accessibilityLabel(Text("certs.expired"))
            } else if days < 60 {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundStyle(.orange)
                    .accessibilityLabel(Text("cert.severity.expiring"))
            }
        }
    }
}

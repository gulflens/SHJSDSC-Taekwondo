import SwiftUI

public struct CoachListView: View {
    @Environment(AppSession.self) private var session
    @State private var coaches: [Coach] = []
    @State private var branches: [EntityID: Branch] = [:]

    public init() {}

    public var body: some View {
        List(coaches) { c in
            HStack(spacing: 12) {
                Avatar(seed: c.avatarSeed, label: c.initials)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: c.fullName)
                    if let b = branches[c.primaryBranchID] {
                        Text(verbatim: b.name).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if c.firstAidExpiry < Date() || c.safeguardingExpiry < Date() {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .accessibilityLabel(Text("certs.expired"))
                }
                Text(verbatim: "\(c.danRank) Dan")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(Text("tab.coaches"))
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

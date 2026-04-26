import SwiftUI

public struct BranchListView: View {
    @Environment(AppSession.self) private var session
    @State private var store: BranchesStore?

    public init() {}

    public var body: some View {
        Group {
            if let store {
                List(store.summaries) { s in
                    NavigationLink(destination: AthleteListView(scope: .byBranch(s.branch.id))) {
                        BranchRow(summary: s)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(Text("tab.branches"))
        .task {
            if store == nil { store = BranchesStore(repository: session.repository) }
            await store?.loadAll()
        }
    }
}

private struct BranchRow: View {
    let summary: BranchSummary

    var body: some View {
        HStack(spacing: 12) {
            GradeBadge(grade: summary.grade, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: summary.branch.name).font(.headline)
                Text(verbatim: summary.branch.nameAr).font(.caption).foregroundStyle(.secondary)
                ProgressView(value: summary.utilisation)
            }
        }
        .padding(.vertical, 4)
    }
}

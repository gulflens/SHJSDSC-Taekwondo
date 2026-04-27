import SwiftUI

public struct BranchListView: View {
    @Environment(AppSession.self) private var session
    @State private var store: BranchesStore?
    @State private var mediaLookup: [EntityID: BranchMedia] = [:]
    @State private var hoursLookup: [EntityID: BranchHours] = [:]
    @State private var manageTarget: EntityID?

    public init() {}

    public var body: some View {
        Group {
            if let store {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.summaries) { s in
                            NavigationLink(destination: BranchProfileView(branchID: s.branch.id)) {
                                BranchCard(
                                    summary: s,
                                    media: mediaLookup[s.branch.id],
                                    hours: hoursLookup[s.branch.id]
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if let role = session.currentUser?.role,
                                   PermissionMatrix.allowed(role: role, permission: .editBranchProfile) {
                                    Button {
                                        manageTarget = s.branch.id
                                    } label: {
                                        Label("manager.dashboard", systemImage: "slider.horizontal.3")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                ProgressView()
            }
        }
        .navigationTitle(Text("tab.branches"))
        .navigationDestination(item: $manageTarget) { id in
            BranchEditView(branchID: id)
        }
        .task {
            if store == nil { store = BranchesStore(repository: session.repository) }
            await store?.loadAll()
            await loadAuxiliary()
        }
    }

    private func loadAuxiliary() async {
        guard let store else { return }
        for s in store.summaries {
            async let m = (try? await session.repository.media(branchID: s.branch.id))
            async let h = (try? await session.repository.hours(branchID: s.branch.id))
            let (media, hours) = await (m, h)
            if let media = media ?? nil { mediaLookup[s.branch.id] = media }
            if let hours = hours ?? nil { hoursLookup[s.branch.id] = hours }
        }
    }
}

private struct BranchCard: View {
    let summary: BranchSummary
    let media: BranchMedia?
    let hours: BranchHours?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroBackground
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 6) {
                        if let isOpen = hours?.isOpenNow() {
                            Label(isOpen ? "branch.open_now" : "branch.closed_now",
                                  systemImage: isOpen ? "checkmark.circle.fill" : "moon.stars.fill")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background((isOpen ? Color.green : Color.gray).opacity(0.85), in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(8)
                }
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: summary.branch.name).font(.headline)
                        Text(verbatim: summary.branch.nameAr).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    GradeBadge(grade: summary.grade, size: 32)
                }
                HStack(spacing: 12) {
                    statChip(icon: "person.3.fill",
                             value: "\(summary.athleteCount)/\(summary.branch.capacity)")
                    statChip(icon: "gauge.with.needle",
                             value: "\(Int(summary.utilisation * 100))%")
                    statChip(icon: "mappin.circle.fill",
                             value: summary.branch.area)
                }
            }
            .padding(12)
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private var heroBackground: some View {
        if let url = media?.heroPhotoURL, let parsed = URL(string: url) {
            AsyncImage(url: parsed) { phase in
                switch phase {
                case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                default: brandFallback
                }
            }
        } else {
            brandFallback
        }
    }

    private var brandFallback: some View {
        let color: Color = summary.branch.brandHexColor.map { Color(hex: $0) } ?? .accentColor
        return color.opacity(0.85)
    }

    private func statChip(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2).foregroundStyle(.secondary)
            Text(verbatim: value).font(.caption.monospacedDigit())
                .environment(\.layoutDirection, .leftToRight)
        }
    }
}

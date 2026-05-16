import SwiftUI

/// Developer-only tool that pushes the four seeded branches (Al Rahmania,
/// Al Nasserya, Al Nouf, Industrial 18) and their full profile sub-records
/// — facility, hours, programs, pricing, inventory, compliance, media,
/// social links, safeguarding, milestones — to the **currently-active**
/// repository.
///
/// When the app is running against `SupabaseRepository`, that means the data
/// lands in your live Supabase database. When running against
/// `DemoRepository`, it's a no-op refresh.
///
/// FK-bearing fields that point at users/coaches that may not exist in the
/// live `user_profiles` / `coaches` tables are nulled out before upsert
/// (`Branch.managerID`, `BranchSafeguarding.safeguardingOfficerCoachID`).
public struct DevDataSyncView: View {
    @Environment(AppSession.self) private var session

    @State private var bundle: SeedBundle?
    @State private var working = false
    @State private var log: [LogLine] = []

    private struct LogLine: Identifiable {
        let id = UUID()
        let text: String
        let kind: Kind
        enum Kind { case info, success, error }
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if let bundle {
                    previewCard(bundle: bundle)
                } else {
                    ProgressView().frame(maxWidth: .infinity)
                }
                actionButton
                if !log.isEmpty {
                    logCard
                }
            }
            .padding(16)
        }
        .background(Color.appBackground)
        .navigationTitle(Text("dev.sync.title"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            if bundle == nil { bundle = SeedData.build() }
        }
    }

    // MARK: - UI pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("dev.sync.title", systemImage: "arrow.up.circle.fill")
                .scaledFont(.title2, weight: .bold)
            Text("dev.sync.description")
                .scaledFont(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Image(systemName: "server.rack")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                Text(verbatim: repositoryLabel)
                    .scaledFont(.caption, monospacedDigit: true)
                    .foregroundStyle(.primary)
            }
        }
    }

    private func previewCard(bundle: SeedBundle) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("dev.sync.preview")
                .scaledFont(.subheadline, weight: .bold)
            ForEach(bundle.branches) { branch in
                branchRow(branch: branch, bundle: bundle)
            }
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
    }

    private func branchRow(branch: Branch, bundle: SeedBundle) -> some View {
        let counts = countsFor(branchID: branch.id, bundle: bundle)
        return VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: "\(branch.code) · \(branch.name)").scaledFont(.callout, weight: .bold)
            Text(verbatim: counts).scaledFont(.caption2, monospacedDigit: true)
                .foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.vertical, 4)
    }

    private var actionButton: some View {
        Button {
            Task { await runSync() }
        } label: {
            HStack {
                if working {
                    ProgressView().controlSize(.small)
                }
                Label("dev.sync.push", systemImage: "icloud.and.arrow.up.fill")
                    .scaledFont(.callout, weight: .bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(working || bundle == nil)
    }

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(log) { line in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: icon(for: line.kind))
                        .scaledFont(.caption2)
                        .foregroundStyle(color(for: line.kind))
                    Text(verbatim: line.text)
                        .scaledFont(.caption, monospacedDigit: true)
                        .foregroundStyle(.primary)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private var repositoryLabel: String {
        let name = String(describing: type(of: session.repository))
        return "Target: \(name)"
    }

    private func countsFor(branchID: EntityID, bundle: SeedBundle) -> String {
        let facility = bundle.facilities.contains { $0.branchID == branchID } ? 1 : 0
        let hours = bundle.branchHours.contains { $0.branchID == branchID } ? 1 : 0
        let programs = bundle.branchPrograms.filter { $0.branchID == branchID }.count
        let pricing = bundle.branchPricings.contains { $0.branchID == branchID } ? 1 : 0
        let inventory = bundle.branchInventories.contains { $0.branchID == branchID } ? 1 : 0
        let compliance = bundle.branchCompliances.contains { $0.branchID == branchID } ? 1 : 0
        let media = bundle.branchMedias.contains { $0.branchID == branchID } ? 1 : 0
        let social = bundle.branchSocialLinks.contains { $0.branchID == branchID } ? 1 : 0
        let safe = bundle.branchSafeguardings.contains { $0.branchID == branchID } ? 1 : 0
        let milestones = bundle.branchMilestones.filter { $0.branchID == branchID }.count
        return "fac:\(facility) hrs:\(hours) prog:\(programs) price:\(pricing) inv:\(inventory) comp:\(compliance) media:\(media) soc:\(social) safe:\(safe) miles:\(milestones)"
    }

    private func icon(for kind: LogLine.Kind) -> String {
        switch kind {
        case .info: "info.circle"
        case .success: "checkmark.circle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    private func color(for kind: LogLine.Kind) -> Color {
        switch kind {
        case .info: .secondary
        case .success: .green
        case .error: .red
        }
    }

    // MARK: - Sync

    private func runSync() async {
        guard let bundle else { return }
        working = true
        log = []
        defer { working = false }

        for var branch in bundle.branches {
            // Strip the FK to user_profiles — the seeded manager UUID won't
            // exist in the live `user_profiles` table.
            branch.managerID = nil
            do {
                try await session.repository.upsert(branch)
                append(.success, "branch \(branch.code) · \(branch.name)")
            } catch {
                append(.error, "branch \(branch.code): \(error)")
                continue
            }

            await pushSubrecords(for: branch.id, bundle: bundle)
        }

        append(.info, "done.")
    }

    private func pushSubrecords(for branchID: EntityID, bundle: SeedBundle) async {
        if let facility = bundle.facilities.first(where: { $0.branchID == branchID }) {
            await tryUpsert("facility") { try await session.repository.upsert(facility) }
        }
        if let hours = bundle.branchHours.first(where: { $0.branchID == branchID }) {
            await tryUpsert("hours") { try await session.repository.upsert(hours) }
        }
        for program in bundle.branchPrograms.filter({ $0.branchID == branchID }) {
            await tryUpsert("program") { try await session.repository.upsert(program) }
        }
        if let pricing = bundle.branchPricings.first(where: { $0.branchID == branchID }) {
            await tryUpsert("pricing") { try await session.repository.upsert(pricing) }
        }
        if let inventory = bundle.branchInventories.first(where: { $0.branchID == branchID }) {
            await tryUpsert("inventory") { try await session.repository.upsert(inventory) }
        }
        if let compliance = bundle.branchCompliances.first(where: { $0.branchID == branchID }) {
            await tryUpsert("compliance") { try await session.repository.upsert(compliance) }
        }
        if let media = bundle.branchMedias.first(where: { $0.branchID == branchID }) {
            await tryUpsert("media") { try await session.repository.upsert(media) }
        }
        if let social = bundle.branchSocialLinks.first(where: { $0.branchID == branchID }) {
            await tryUpsert("social") { try await session.repository.upsert(social) }
        }
        if var safe = bundle.branchSafeguardings.first(where: { $0.branchID == branchID }) {
            // Strip FK to coaches — the seeded coach UUID won't exist live.
            safe.safeguardingOfficerCoachID = nil
            await tryUpsert("safeguarding") { try await session.repository.upsert(safe) }
        }
        for milestone in bundle.branchMilestones.filter({ $0.branchID == branchID }) {
            await tryUpsert("milestone") { try await session.repository.upsert(milestone) }
        }
    }

    private func tryUpsert(_ label: String, _ op: () async throws -> Void) async {
        do {
            try await op()
            append(.info, "  ↳ \(label)")
        } catch {
            append(.error, "  ↳ \(label): \(error)")
        }
    }

    private func append(_ kind: LogLine.Kind, _ text: String) {
        log.append(LogLine(text: text, kind: kind))
    }
}

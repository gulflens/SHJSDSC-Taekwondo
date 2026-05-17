import SwiftUI

/// The full coaching dossier for an athlete who also serves as an assistant
/// coach. Rendered inside the athlete profile's Roles section. Surfaces the
/// development-pipeline rung, mentorship, branch assignment, the limited
/// coaching permissions (allowed vs. restricted), and coaching evaluations.
public struct CoachingDevelopmentCard: View {
    public let dossier: AssistantCoachProfile
    public let supervisingCoachName: String?
    public let primaryBranchName: String?
    public let supportBranchNames: [String]

    public init(
        dossier: AssistantCoachProfile,
        supervisingCoachName: String? = nil,
        primaryBranchName: String? = nil,
        supportBranchNames: [String] = []
    ) {
        self.dossier = dossier
        self.supervisingCoachName = supervisingCoachName
        self.primaryBranchName = primaryBranchName
        self.supportBranchNames = supportBranchNames
    }

    public var body: some View {
        SectionCard("coaching.development_dossier", icon: "figure.taekwondo") {
            VStack(alignment: .leading, spacing: 16) {
                pipelineRow
                ReadinessMeter(value: dossier.promotionReadiness)
                Divider().opacity(0.4)
                mentorshipBlock
                branchBlock
                Divider().opacity(0.4)
                permissionsBlock
                if !dossier.evaluations.isEmpty {
                    Divider().opacity(0.4)
                    evaluationsBlock
                }
            }
        }
    }

    // MARK: - Pipeline rung

    private var pipelineRow: some View {
        HStack(spacing: 10) {
            DevelopmentLevelBadge(level: dossier.developmentLevel)
            Spacer(minLength: 0)
            if let next = dossier.developmentLevel.next {
                HStack(spacing: 4) {
                    Text("coaching.next_stage")
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                    Image(systemName: "arrow.right")
                        .scaledFont(.caption2, weight: .semibold)
                        .flipsForRightToLeftLayoutDirection(true)
                        .foregroundStyle(.secondary)
                    Text(localizedKey: next.labelKey)
                        .scaledFont(.caption, weight: .semibold)
                        .foregroundStyle(next.tint)
                }
            }
        }
    }

    // MARK: - Mentorship

    private var mentorshipBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            blockTitle("coaching.mentorship", icon: "person.fill.checkmark")
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color.secondaryAccent.opacity(0.16))
                    Image(systemName: "person.fill.checkmark")
                        .scaledFont(.footnote)
                        .foregroundStyle(.secondaryAccent)
                }
                .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("coaching.supervising_coach")
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                    Text(verbatim: supervisingCoachName ?? NSLocalizedString("coaching.unassigned_mentor", comment: ""))
                        .scaledFont(.subheadline, weight: .semibold)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(verbatim: "\(dossier.monthsCoaching)")
                        .scaledFont(.subheadline, weight: .bold, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                    Text("coaching.stat.months_coaching")
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Branches

    private var branchBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            blockTitle("coaching.branch_assignment", icon: "building.2.fill")
            FlowChipRow {
                BranchAssignmentChip(kind: .primary, branchName: primaryBranchName ?? "—")
                ForEach(supportBranchNames, id: \.self) { name in
                    BranchAssignmentChip(kind: .support, branchName: name)
                }
            }
        }
    }

    // MARK: - Permissions

    private var permissionsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            blockTitle("coaching.permissions", icon: "checkmark.shield.fill")
            VStack(spacing: 6) {
                ForEach(CoachingPermission.assistantCoachGrantable) { permission in
                    permissionRow(permission, granted: dossier.permissions.contains(permission))
                }
            }
            Text("coaching.permissions.restricted_note")
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            VStack(spacing: 6) {
                ForEach(CoachingPermission.restricted) { permission in
                    permissionRow(permission, granted: false, restricted: true)
                }
            }
        }
    }

    private func permissionRow(_ permission: CoachingPermission, granted: Bool, restricted: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: permission.systemIcon)
                .scaledFont(.caption)
                .foregroundStyle(restricted ? Color.red.opacity(0.7) : (granted ? .secondaryAccent : .secondary))
                .frame(width: 20)
            Text(localizedKey: permission.labelKey)
                .scaledFont(.footnote, weight: .medium)
                .foregroundStyle(restricted || !granted ? .secondary : .primary)
            Spacer(minLength: 0)
            Image(systemName: restricted ? "lock.fill" : (granted ? "checkmark.circle.fill" : "circle"))
                .scaledFont(.caption)
                .foregroundStyle(restricted ? .red : (granted ? .secondaryAccent : Color.secondary.opacity(0.5)))
        }
        .padding(.vertical, 2)
        .opacity(restricted ? 0.85 : 1)
    }

    // MARK: - Evaluations

    private var evaluationsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            blockTitle("coaching.evaluations", icon: "text.bubble.fill")
            ForEach(sortedEvaluations) { eval in
                evaluationRow(eval)
                if eval.id != sortedEvaluations.last?.id {
                    Divider().opacity(0.3)
                }
            }
        }
    }

    private var sortedEvaluations: [CoachingEvaluation] {
        dossier.evaluations.sorted { $0.date > $1.date }
    }

    private func evaluationRow(_ eval: CoachingEvaluation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(verbatim: eval.evaluatorName)
                    .scaledFont(.footnote, weight: .semibold)
                Spacer(minLength: 0)
                Text(eval.date, format: .dateTime.day().month(.abbreviated).year())
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            EvaluationStars(score: Double(eval.overallScore))
            HStack(spacing: 12) {
                miniScore("coaching.eval.reliability", value: eval.reliability)
                miniScore("coaching.eval.leadership", value: eval.leadership)
            }
            if !eval.notes.isEmpty {
                Text(verbatim: eval.notes)
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }

    private func miniScore(_ key: LocalizedStringKey, value: Int) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
            Text(verbatim: "\(value)/5")
                .scaledFont(.caption2, weight: .semibold, monospacedDigit: true)
                .foregroundStyle(.primary)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    // MARK: - Helpers

    private func blockTitle(_ key: LocalizedStringKey, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.tint)
            Text(key)
                .scaledFont(.footnote, weight: .semibold)
                .foregroundStyle(.primary)
        }
    }
}

/// Lightweight wrapping chip row — wraps to a new line when chips overflow the
/// available width. Built on `Layout` so it auto-mirrors under RTL.
public struct FlowChipRow: Layout {
    public var spacing: CGFloat = 6

    public init(spacing: CGFloat = 6) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var rowWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append(size)
            rowWidth += size.width + spacing
        }
        let height = rows.reduce(CGFloat(0)) { partial, row in
            partial + (row.map(\.height).max() ?? 0) + spacing
        } - spacing
        return CGSize(width: maxWidth == .infinity ? rowWidth : maxWidth, height: max(0, height))
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

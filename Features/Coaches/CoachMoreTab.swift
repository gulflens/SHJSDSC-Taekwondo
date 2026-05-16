import SwiftUI

/// More tab — assigned branches, contract details, bio, and coach notes
/// (peer / HQ feedback). Catches everything that doesn't fit the seven
/// primary tabs.
public struct CoachMoreTab: View {
    public let coach: Coach
    public let primaryBranchName: String?
    public let secondaryBranchNames: [String]
    public let isWide: Bool

    public init(
        coach: Coach,
        primaryBranchName: String?,
        secondaryBranchNames: [String],
        isWide: Bool
    ) {
        self.coach = coach
        self.primaryBranchName = primaryBranchName
        self.secondaryBranchNames = secondaryBranchNames
        self.isWide = isWide
    }

    public var body: some View {
        VStack(spacing: 14) {
            contractCard
            branchesCard
            bioCard
            coachNotesCard
        }
    }

    private var contractCard: some View {
        SectionCard("coach.more.contract", icon: "briefcase.fill") {
            VStack(spacing: 6) {
                AthleteSummaryRow(
                    icon: "doc.fill",
                    labelKey: "coach.field.contract_type",
                    value: NSLocalizedString(coach.contractType.labelKey, comment: "")
                )
                AthleteSummaryRow(
                    icon: "calendar",
                    labelKey: "coach.field.hired_at",
                    value: dateString(coach.hiredAt)
                )
                AthleteSummaryRow(
                    icon: "rosette",
                    labelKey: "coach.field.employment_status",
                    value: NSLocalizedString(coach.employmentStatus.labelKey, comment: ""),
                    valueColor: coach.employmentStatus == .active ? .green : .orange
                )
                if let target = coach.weeklyHoursTarget {
                    AthleteSummaryRow(
                        icon: "clock.fill",
                        labelKey: "coach.field.weekly_target",
                        value: "\(target)h"
                    )
                }
                AthleteSummaryRow(
                    icon: "bell.badge.fill",
                    labelKey: "coach.field.on_call",
                    value: coach.onCall
                        ? NSLocalizedString("yes", comment: "")
                        : NSLocalizedString("no", comment: "")
                )
            }
        }
    }

    private var branchesCard: some View {
        SectionCard("coach.more.assignments", icon: "building.2.fill") {
            VStack(spacing: 6) {
                AthleteSummaryRow(
                    icon: "star.fill",
                    labelKey: "coach.field.primary_branch",
                    value: primaryBranchName ?? "—"
                )
                if !secondaryBranchNames.isEmpty {
                    Divider().padding(.vertical, 2)
                    ForEach(secondaryBranchNames, id: \.self) { name in
                        AthleteSummaryRow(
                            icon: "circle.fill",
                            labelKey: "coach.field.secondary_branch",
                            value: name
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var bioCard: some View {
        if let bio = coach.bio, !bio.isEmpty {
            SectionCard("coach.more.bio", icon: "text.alignleft") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: bio)
                        .scaledFont(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    if let bioAr = coach.bioAr, !bioAr.isEmpty {
                        Divider().padding(.vertical, 2)
                        Text(verbatim: bioAr)
                            .scaledFont(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                }
            }
        }
    }

    private var coachNotesCard: some View {
        SectionCard("coach.more.notes", icon: "text.bubble.fill") {
            if coach.coachNotes.isEmpty {
                EmptyStateCard(
                    icon: "text.bubble",
                    titleKey: "coach.notes.empty.title",
                    messageKey: "coach.notes.empty.message"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(coach.coachNotes.sorted { lhs, rhs in
                        if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
                        return lhs.date > rhs.date
                    }) { note in
                        CoachNoteCard(note: note)
                    }
                }
            }
        }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

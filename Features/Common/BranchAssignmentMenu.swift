import SwiftUI

/// Compact "Assign to branch" picker used on the Athlete and Coach detail
/// hero rows. Renders as a Menu when the caller can edit; as a static label
/// otherwise. Tapping a branch row triggers `onAssign` with the new id.
public struct BranchAssignmentMenu: View {
    public let currentBranchID: EntityID?
    public let branches: [Branch]
    public let canEdit: Bool
    public let onAssign: (EntityID) -> Void

    public init(
        currentBranchID: EntityID?,
        branches: [Branch],
        canEdit: Bool,
        onAssign: @escaping (EntityID) -> Void
    ) {
        self.currentBranchID = currentBranchID
        self.branches = branches
        self.canEdit = canEdit
        self.onAssign = onAssign
    }

    public var body: some View {
        if canEdit {
            Menu {
                ForEach(branches) { branch in
                    Button {
                        guard branch.id != currentBranchID else { return }
                        onAssign(branch.id)
                    } label: {
                        if branch.id == currentBranchID {
                            Label {
                                Text(verbatim: branch.name)
                            } icon: {
                                Image(systemName: "checkmark")
                            }
                        } else {
                            Text(verbatim: branch.name)
                        }
                    }
                }
            } label: {
                pillContent
            }
        } else {
            pillContent
        }
    }

    private var pillContent: some View {
        HStack(spacing: 6) {
            Image(systemName: "building.2.fill")
                .scaledFont(.caption)
                .foregroundStyle(.tint)
            VStack(alignment: .trailing, spacing: 1) {
                Text("branch.assignment")
                    .scaledFont(size: 9, weight: .semibold)
                    .foregroundStyle(.secondary)
                Text(verbatim: currentName)
                    .scaledFont(.caption, weight: .bold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            if canEdit {
                Image(systemName: "chevron.up.chevron.down")
                    .scaledFont(size: 9)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 0.5)
        )
    }

    private var currentName: String {
        guard let id = currentBranchID,
              let name = branches.first(where: { $0.id == id })?.name else {
            return String(localized: "branch.unassigned")
        }
        return name
    }
}

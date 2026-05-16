import SwiftUI

/// Coach Notes tab — pinned notes first, then chronological. Filter chips
/// by category, compose-note FAB gated by `canEdit`.
public struct AthleteCoachNotesTab: View {
    public let athlete: Athlete
    public let canEdit: Bool
    public let onCompose: () -> Void

    @State private var categoryFilter: CoachNoteCategory?

    public init(athlete: Athlete, canEdit: Bool, onCompose: @escaping () -> Void = {}) {
        self.athlete = athlete
        self.canEdit = canEdit
        self.onCompose = onCompose
    }

    public var body: some View {
        VStack(spacing: 14) {
            filterStrip
            if filteredNotes.isEmpty {
                SectionCard {
                    EmptyStateCard(
                        icon: "text.bubble",
                        titleKey: "coach_note.empty.title",
                        messageKey: "coach_note.empty.message"
                    )
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredNotes) { note in
                        CoachNoteCard(note: note)
                    }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if canEdit {
                Button(action: onCompose) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.pencil")
                        Text("coach_note.compose")
                    }
                    .scaledFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.accentColor, in: Capsule())
                    .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .padding(20)
            }
        }
    }

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(nil, labelKey: "coach_note.filter.all", icon: "tray.full")
                ForEach(CoachNoteCategory.allCases, id: \.rawValue) { cat in
                    filterChip(cat, labelKey: LocalizedStringKey(cat.labelKey), icon: cat.systemIcon)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func filterChip(_ cat: CoachNoteCategory?, labelKey: LocalizedStringKey, icon: String) -> some View {
        let isSelected = categoryFilter == cat
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                categoryFilter = cat
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon).scaledFont(.caption2)
                Text(labelKey).scaledFont(.caption, weight: .medium)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private var filteredNotes: [CoachNote] {
        let base = athlete.coachNotes.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return lhs.date > rhs.date
        }
        guard let cat = categoryFilter else { return base }
        return base.filter { $0.category == cat }
    }
}

import SwiftUI

/// Roster surface for a coach's assigned athletes. Filter chips + grid of
/// athlete cards (tap → AthleteDetailView).
public struct CoachAthletesTab: View {
    public let athletes: [Athlete]
    public let isWide: Bool

    @State private var statusFilter: AthleteStatus?
    @State private var searchText: String = ""

    public init(athletes: [Athlete], isWide: Bool) {
        self.athletes = athletes
        self.isWide = isWide
    }

    public var body: some View {
        VStack(spacing: 14) {
            kpiStrip
            filterStrip
            rosterCard
        }
    }

    private var kpiStrip: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 5 : 2),
            spacing: 12
        ) {
            KPITile(title: "coach.team.total", value: "\(athletes.count)", icon: "person.3.fill")
            KPITile(title: "coach.team.elite", value: "\(athletes.filter { $0.status == .competitionTeam }.count)", icon: "flame.fill")
            KPITile(title: "coach.team.ready_to_grade", value: "\(athletes.filter { $0.status == .readyToGrade }.count)", icon: "checkmark.seal.fill")
            KPITile(title: "coach.team.watch", value: "\(athletes.filter { $0.status == .watch }.count)", icon: "eye.fill")
            KPITile(title: "coach.team.injured", value: "\(athletes.filter { !$0.fitToTrain }.count)", icon: "bandage.fill")
        }
    }

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(nil, labelKey: "coach.team.filter.all", icon: "tray.full")
                ForEach(AthleteStatus.allCases, id: \.rawValue) { status in
                    filterChip(status, labelKey: LocalizedStringKey(status.labelKey), icon: "circle.fill")
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func filterChip(_ status: AthleteStatus?, labelKey: LocalizedStringKey, icon: String) -> some View {
        let isSelected = statusFilter == status
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                statusFilter = status
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

    private var rosterCard: some View {
        SectionCard("coach.team.roster", icon: "list.bullet.rectangle") {
            if filteredAthletes.isEmpty {
                EmptyStateCard(
                    icon: "person.crop.circle.badge.questionmark",
                    titleKey: "coach.team.empty.title",
                    messageKey: "coach.team.empty.message"
                )
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 3 : 1),
                    spacing: 12
                ) {
                    ForEach(filteredAthletes) { athlete in
                        NavigationLink {
                            AthleteDetailView(athlete: athlete)
                        } label: {
                            athleteCard(athlete)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func athleteCard(_ athlete: Athlete) -> some View {
        HStack(spacing: 12) {
            Avatar(
                seed: athlete.avatarSeed,
                label: athlete.initials,
                size: 44,
                urlString: athlete.avatarURL
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: athlete.fullName)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(localizedKey: athlete.ageGroup.labelKey)
                        .scaledFont(.caption2)
                    Text(verbatim: "·")
                        .scaledFont(.caption2)
                    Text(verbatim: String(format: "%.0fkg", athlete.weightKg))
                        .scaledFont(.caption2, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                }
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            StatusPill(status: athlete.status)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var filteredAthletes: [Athlete] {
        guard let statusFilter else { return athletes }
        return athletes.filter { $0.status == statusFilter }
    }
}

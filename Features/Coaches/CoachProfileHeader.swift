import SwiftUI

/// Federation-grade coach header. Visually mirrors `AthleteProfileHeader` so
/// both profile modules feel part of the same ecosystem — same primitives,
/// same spacing rhythm, same status-badge grammar.
public struct CoachProfileHeader: View {
    public let coach: Coach
    public let primaryBranchName: String?
    public let isWide: Bool
    public let onEditPhoto: () -> Void

    public init(
        coach: Coach,
        primaryBranchName: String?,
        isWide: Bool,
        onEditPhoto: @escaping () -> Void = {}
    ) {
        self.coach = coach
        self.primaryBranchName = primaryBranchName
        self.isWide = isWide
        self.onEditPhoto = onEditPhoto
    }

    public var body: some View {
        Group {
            if isWide {
                HStack(alignment: .top, spacing: 24) {
                    photoBlock
                    infoColumn
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        photoBlock
                        nameBlock
                    }
                    metadataChips
                    identityGrid
                    statusBadgesRow
                }
            }
        }
        .padding(isWide ? 20 : 16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 18, y: 8)
    }

    // MARK: - Photo

    private var photoBlock: some View {
        ZStack(alignment: .bottomTrailing) {
            Avatar(
                seed: coach.avatarSeed,
                label: coach.initials,
                size: isWide ? 132 : 88,
                urlString: coach.avatarURL
            )
            .overlay(
                Circle().stroke(strokeColor, lineWidth: 3)
            )
            Button(action: onEditPhoto) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    Image(systemName: "pencil")
                        .scaledFont(.caption, weight: .bold)
                        .foregroundStyle(.white)
                }
                .frame(width: isWide ? 30 : 26, height: isWide ? 30 : 26)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("coach.edit_photo"))
        }
    }

    /// Black dan-belt-ish stroke for coaches by default — overridden to gold
    /// for international-level coaches.
    private var strokeColor: Color {
        switch coach.coachLevel {
        case .international: Color(red: 0.86, green: 0.65, blue: 0.13)
        case .national: Color(red: 0.12, green: 0.43, blue: 0.92)
        default: Color(white: 0.18)
        }
    }

    // MARK: - Info column (wide layout)

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 14) {
            nameBlock
            metadataChips
            identityGrid
            statusBadgesRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Name + verification

    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: coach.fullName)
                    .font(isWide ? .title.bold() : .title2.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                if isVerified {
                    VerificationBadge()
                }
            }
            Text(verbatim: coach.fullNameAr)
                .font(isWide ? .title3 : .body)
                .foregroundStyle(.secondary)
                .environment(\.layoutDirection, .rightToLeft)
        }
    }

    private var isVerified: Bool {
        let hasFederation = (coach.federationCoachID ?? "").isEmpty == false
        let hasID = (coach.emiratesID ?? "").isEmpty == false
            || (coach.passportNumber ?? "").isEmpty == false
        let hasPhoto = (coach.avatarURL ?? "").isEmpty == false
        return hasFederation && hasID && hasPhoto
    }

    // MARK: - Metadata chips

    private var metadataChips: some View {
        HStack(spacing: 8) {
            MetaChip(
                "coach.field.nationality",
                value: coach.nationality,
                icon: "flag.fill"
            )
            MetaChip(
                "coach.field.experience",
                value: "\(coach.yearsOfExperience) yr",
                icon: "calendar"
            )
            if let level = coach.coachLevel {
                MetaChip(
                    "coach.field.level",
                    value: NSLocalizedString(level.labelKey, comment: ""),
                    icon: "rosette"
                )
            }
            MetaChip(
                "coach.field.dan",
                value: "\(coach.danRank) Dan",
                icon: "circle.hexagongrid.fill"
            )
        }
    }

    // MARK: - Identity grid

    private var identityGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 4 : 2),
            alignment: .leading,
            spacing: 12
        ) {
            IDChip(
                "coach.id.federation",
                value: coach.federationCoachID ?? "—",
                icon: "rosette"
            )
            IDChip(
                "coach.id.world_taekwondo",
                value: coach.worldTaekwondoCoachID ?? "—",
                icon: "globe"
            )
            IDChip(
                "athlete.id.emirates",
                value: coach.emiratesID ?? "—",
                icon: "person.text.rectangle"
            )
            IDChip(
                "athlete.id.passport",
                value: coach.passportNumber ?? "—",
                icon: "book.closed"
            )
            IDChip(
                "athlete.field.blood_group",
                value: coach.bloodType?.display ?? "—",
                icon: "drop.fill"
            )
            IDChip(
                "coach.field.branch",
                value: primaryBranchName ?? "—",
                icon: "building.2.fill"
            )
        }
    }

    // MARK: - Status badges

    private var statusBadgesRow: some View {
        HStack(spacing: 8) {
            if coach.coachLevel == .head || coach.coachLevel == .national || coach.coachLevel == .international {
                CategoryBadge(
                    "coach.badge.head",
                    value: NSLocalizedString((coach.coachLevel ?? .head).labelKey, comment: ""),
                    tone: .elite,
                    icon: "crown.fill"
                )
            }
            if let spec = coach.specialisation {
                CategoryBadge(
                    "coach.field.specialisation",
                    value: NSLocalizedString(spec.labelKey, comment: ""),
                    tone: .neutral,
                    icon: spec.systemIcon
                )
            }
            if coach.nationalTeamStatus != .none {
                CategoryBadge(
                    "coach.badge.national_team",
                    value: NSLocalizedString(coach.nationalTeamStatus.labelKey, comment: ""),
                    tone: .elite,
                    icon: "flag.fill"
                )
            }
            if coach.olympicProgramStatus != .none {
                CategoryBadge(
                    "coach.badge.olympic",
                    value: NSLocalizedString(coach.olympicProgramStatus.labelKey, comment: ""),
                    tone: .dark,
                    icon: "rosette"
                )
            }
            Spacer(minLength: 0)
        }
    }
}

import SwiftUI

/// Federation-grade athlete header used at the top of the redesigned
/// AthleteDetailView. Renders the large photo, bilingual name with the
/// verification badge, identity chips, and the squad / weight-cat / belt
/// status badges.
///
/// Adapts between compact (iPhone) and regular (iPad landscape) size classes
/// via `isWide`. On wide, the photo is anchored to the leading edge and the
/// info column sits beside it. On compact, the photo is centered above the
/// info column.
public struct AthleteProfileHeader: View {
    public let athlete: Athlete
    public let branchName: String?
    public let isWide: Bool
    public let onEditPhoto: () -> Void

    public init(
        athlete: Athlete,
        branchName: String?,
        isWide: Bool,
        onEditPhoto: @escaping () -> Void = {}
    ) {
        self.athlete = athlete
        self.branchName = branchName
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
                seed: athlete.avatarSeed,
                label: athlete.initials,
                size: isWide ? 132 : 88,
                urlString: athlete.avatarURL
            )
            .overlay(
                Circle()
                    .stroke(beltStrokeColor, lineWidth: 3)
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
            .accessibilityLabel(Text("athlete.edit_photo"))
        }
    }

    private var beltStrokeColor: Color {
        switch athlete.currentBelt.color {
        case .white: Color(red: 0.85, green: 0.85, blue: 0.85)
        case .yellow: Color(red: 1.00, green: 0.82, blue: 0.25)
        case .green: Color(red: 0.18, green: 0.62, blue: 0.36)
        case .blue: Color(red: 0.12, green: 0.43, blue: 0.92)
        case .red: Color(red: 0.90, green: 0.22, blue: 0.22)
        case .black: Color(white: 0.10)
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
                Text(verbatim: athlete.fullName)
                    .font(isWide ? .title.bold() : .title2.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                if isVerified {
                    VerificationBadge()
                }
            }
            Text(verbatim: athlete.fullNameAr)
                .font(isWide ? .title3 : .body)
                .foregroundStyle(.secondary)
                .environment(\.layoutDirection, .rightToLeft)
        }
    }

    private var isVerified: Bool {
        let hasID = (athlete.emiratesID ?? "").isEmpty == false
            || (athlete.passportNumber ?? "").isEmpty == false
        let hasFederation = (athlete.federationLicenceNumber ?? "").isEmpty == false
        let hasPhoto = (athlete.avatarURL ?? "").isEmpty == false
        return hasID && hasFederation && hasPhoto
    }

    // MARK: - Metadata chips (Gender / Age / Nationality)

    private var metadataChips: some View {
        HStack(spacing: 8) {
            MetaChip(
                "athlete.field.gender",
                value: NSLocalizedString("gender.\(athlete.gender.rawValue)", comment: ""),
                icon: athlete.gender == .female ? "figure.stand.dress" : "figure.stand"
            )
            MetaChip(
                "athlete.field.age",
                value: "\(athlete.age) y",
                icon: "calendar"
            )
            MetaChip(
                "athlete.field.nationality",
                value: athlete.nationality,
                icon: "flag.fill"
            )
        }
    }

    // MARK: - Identity grid (federation IDs + Emirates ID + Passport + Blood Group)

    private var identityGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 4 : 2),
            alignment: .leading,
            spacing: 12
        ) {
            IDChip(
                "athlete.id.federation",
                value: athlete.federationLicenceNumber ?? "—",
                icon: "rosette"
            )
            IDChip(
                "athlete.id.world_taekwondo",
                value: athlete.worldTaekwondoID ?? "—",
                icon: "globe"
            )
            IDChip(
                "athlete.id.emirates",
                value: athlete.emiratesID ?? "—",
                icon: "person.text.rectangle"
            )
            IDChip(
                "athlete.id.passport",
                value: athlete.passportNumber ?? "—",
                icon: "book.closed"
            )
            IDChip(
                "athlete.field.blood_group",
                value: athlete.bloodType?.display ?? "—",
                icon: "drop.fill"
            )
            IDChip(
                "athlete.field.member_number",
                value: "#\(athlete.memberNumber)",
                icon: "number"
            )
        }
    }

    // MARK: - Status badges (Squad / Weight Cat / Belt)

    private var statusBadgesRow: some View {
        HStack(spacing: 8) {
            CategoryBadge(
                "athlete.field.squad",
                value: NSLocalizedString(athlete.status.labelKey, comment: ""),
                tone: athlete.status == .competitionTeam ? .elite : .neutral,
                icon: "shield.fill"
            )
            if let weightClass = athlete.weightClass {
                CategoryBadge(
                    "athlete.field.weight_category",
                    value: NSLocalizedString(weightClass.labelKey, comment: ""),
                    tone: .neutral,
                    icon: "scalemass.fill"
                )
            }
            CategoryBadge(
                "athlete.field.belt",
                value: NSLocalizedString(athlete.currentBelt.color.labelKey, comment: ""),
                tone: athlete.currentBelt.color == .black ? .dark : .neutral,
                icon: "circle.hexagongrid.fill"
            )
            Spacer(minLength: 0)
        }
    }
}

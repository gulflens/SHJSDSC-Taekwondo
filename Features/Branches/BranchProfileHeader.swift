import SwiftUI

/// Federation-grade branch hero. Visual sibling of `AthleteProfileHeader` /
/// `CoachProfileHeader` — branded gradient banner with the branch image,
/// main/secondary chip, status pill, manager avatar, and key stat row.
public struct BranchProfileHeader: View {
    public let branch: Branch
    public let manager: Coach?
    public let athleteCount: Int
    public let coachCount: Int
    public let sessionsPerWeek: Int
    public let attendancePct: Double
    public let mediaHeroURL: String?
    public let isWide: Bool
    public let onEditPhoto: () -> Void

    public init(
        branch: Branch,
        manager: Coach?,
        athleteCount: Int,
        coachCount: Int,
        sessionsPerWeek: Int,
        attendancePct: Double,
        mediaHeroURL: String?,
        isWide: Bool,
        onEditPhoto: @escaping () -> Void = {}
    ) {
        self.branch = branch
        self.manager = manager
        self.athleteCount = athleteCount
        self.coachCount = coachCount
        self.sessionsPerWeek = sessionsPerWeek
        self.attendancePct = attendancePct
        self.mediaHeroURL = mediaHeroURL
        self.isWide = isWide
        self.onEditPhoto = onEditPhoto
    }

    public var body: some View {
        VStack(spacing: 0) {
            bannerSection
            statRow
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 18, y: 8)
    }

    // MARK: - Banner

    private var bannerSection: some View {
        ZStack(alignment: .bottomLeading) {
            backgroundLayer
            LinearGradient(
                colors: [.black.opacity(0.65), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    if branch.isMain {
                        CategoryBadge(
                            value: NSLocalizedString("branch.badge.main", comment: ""),
                            tone: .elite,
                            icon: "crown.fill"
                        )
                    } else {
                        CategoryBadge(
                            value: NSLocalizedString("branch.badge.secondary", comment: ""),
                            tone: .neutral,
                            icon: "building"
                        )
                    }
                    statusBadge
                    if branch.isActive == false {
                        CategoryBadge(
                            value: NSLocalizedString("branch.badge.inactive", comment: ""),
                            tone: .warning,
                            icon: "exclamationmark.triangle.fill"
                        )
                    }
                }
                Text(verbatim: branch.name)
                    .font(isWide ? .largeTitle.bold() : .title.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(verbatim: branch.nameAr)
                    .font(isWide ? .title3 : .headline)
                    .foregroundStyle(.white.opacity(0.9))
                    .environment(\.layoutDirection, .rightToLeft)
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .scaledFont(.caption, weight: .semibold)
                    Text(verbatim: locationLabel)
                        .scaledFont(.caption)
                }
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(20)
            VStack {
                HStack {
                    Spacer()
                    editButton.padding(16)
                }
                Spacer()
            }
        }
        .frame(height: isWide ? 260 : 200)
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if let url = mediaHeroURL.flatMap(URL.init(string:)) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    gradientFallback
                }
            }
        } else {
            gradientFallback
        }
    }

    private var gradientFallback: some View {
        LinearGradient(
            colors: [brandColor, brandColor.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var brandColor: Color {
        if let hex = branch.brandHexColor, !hex.isEmpty {
            return Color(hex: hex)
        }
        return Color(red: 0.12, green: 0.43, blue: 0.92)
    }

    private var statusBadge: some View {
        let (tone, icon): (CategoryBadge.Tone, String) = switch branch.operationalStatus {
        case .active: (.success, "checkmark.circle.fill")
        case .maintenance: (.warning, "wrench.and.screwdriver.fill")
        case .tournamentMode: (.elite, "trophy.fill")
        case .closed: (.neutral, "lock.fill")
        }
        return CategoryBadge(
            value: NSLocalizedString(branch.operationalStatus.labelKey, comment: ""),
            tone: tone,
            icon: icon
        )
    }

    private var editButton: some View {
        Button(action: onEditPhoto) {
            Image(systemName: "camera.fill")
                .scaledFont(.subheadline)
                .foregroundStyle(.white)
                .padding(10)
                .background(.black.opacity(0.32), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("branch.edit_photo"))
    }

    private var locationLabel: String {
        let area = branch.area.isEmpty ? branch.emirate : "\(branch.area), \(branch.emirate)"
        return area.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Stat row

    private var statRow: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: isWide ? 5 : 4),
            spacing: 0
        ) {
            statBlock(icon: "person.3.fill", value: "\(athleteCount)", labelKey: "branch.stat.athletes")
            statBlock(icon: "graduationcap.fill", value: "\(coachCount)", labelKey: "branch.stat.coaches")
            statBlock(icon: "calendar.badge.checkmark", value: "\(sessionsPerWeek)", labelKey: "branch.stat.sessions_week")
            statBlock(icon: "checkmark.circle.fill", value: String(format: "%.0f%%", attendancePct * 100), labelKey: "branch.stat.attendance")
            if isWide, let manager {
                managerBlock(manager)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
    }

    private func statBlock(icon: String, value: String, labelKey: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .scaledFont(.caption2)
                    .foregroundStyle(.tint)
                Text(labelKey)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(verbatim: value)
                .scaledFont(.title3, weight: .bold, monospacedDigit: true)
                .environment(\.layoutDirection, .leftToRight)
        }
        .frame(maxWidth: .infinity)
    }

    private func managerBlock(_ manager: Coach) -> some View {
        HStack(spacing: 10) {
            Avatar(seed: manager.avatarSeed, label: manager.initials, size: 36, urlString: manager.avatarURL)
            VStack(alignment: .leading, spacing: 1) {
                Text("branch.stat.manager")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                Text(verbatim: manager.fullName)
                    .scaledFont(.caption, weight: .semibold)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
    }
}


import SwiftUI

/// Premium branch card used in the Branches Overview screen. Renders the
/// branch hero color band, name + emirate, status pill, main/secondary
/// badge, and the four key operational counters.
///
/// `isDominant=true` enlarges padding, raises elevation, and adds a
/// gradient-accented border for the main branch.
public struct BranchCard: View {
    public let branch: Branch
    public let athleteCount: Int
    public let coachCount: Int
    public let sessionsPerWeek: Int
    public let isDominant: Bool
    public let isWide: Bool

    public init(
        branch: Branch,
        athleteCount: Int,
        coachCount: Int,
        sessionsPerWeek: Int,
        isDominant: Bool,
        isWide: Bool
    ) {
        self.branch = branch
        self.athleteCount = athleteCount
        self.coachCount = coachCount
        self.sessionsPerWeek = sessionsPerWeek
        self.isDominant = isDominant
        self.isWide = isWide
    }

    public var body: some View {
        NavigationLink {
            BranchProfileView(branchID: branch.id)
        } label: {
            VStack(alignment: .leading, spacing: isDominant ? 14 : 12) {
                heroBand
                metaRow
                statsRow
            }
            .padding(isDominant ? 18 : 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: isDominant ? 18 : 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: isDominant ? 18 : 14, style: .continuous)
                    .stroke(borderColor, lineWidth: isDominant ? 1.5 : 1)
            )
            .shadow(color: shadowColor, radius: isDominant ? 16 : 8, y: isDominant ? 8 : 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hero band

    private var heroBand: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(brandGradient)
                .frame(height: isDominant ? 96 : 72)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .scaledFont(size: isDominant ? 44 : 32)
                        .foregroundStyle(.white.opacity(0.22))
                        .padding(.trailing, 16)
                        .padding(.top, 12),
                    alignment: .topTrailing
                )
            HStack(spacing: 6) {
                if branch.isMain {
                    CategoryBadge(
                        value: NSLocalizedString("branch.badge.main", comment: ""),
                        tone: .dark,
                        icon: "crown.fill"
                    )
                } else {
                    CategoryBadge(
                        value: NSLocalizedString("branch.badge.secondary", comment: ""),
                        tone: .neutral,
                        icon: "building"
                    )
                }
                Spacer(minLength: 0)
                statusPill
            }
            .padding(12)
        }
    }

    private var brandGradient: LinearGradient {
        let base = brandColor
        return LinearGradient(
            colors: [base, base.opacity(0.65)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Use the branch's `brandHexColor` when set, otherwise fall back to
    /// a deterministic shade based on `code`.
    private var brandColor: Color {
        if let hex = branch.brandHexColor, !hex.isEmpty {
            return Color(hex: hex)
        }
        let palette: [Color] = [
            Color(red: 0.12, green: 0.43, blue: 0.92),
            Color(red: 0.20, green: 0.65, blue: 0.65),
            Color(red: 0.55, green: 0.40, blue: 0.75),
            Color(red: 0.95, green: 0.55, blue: 0.20)
        ]
        let sum = branch.code.utf8.reduce(0) { $0 &+ Int($1) }
        return palette[sum % palette.count]
    }

    private var statusPill: some View {
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

    // MARK: - Meta row

    private var metaRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: branch.name)
                    .font(isDominant ? .title3.bold() : .headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                Text(verbatim: branch.area.isEmpty ? branch.emirate : "\(branch.area), \(branch.emirate)")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: isDominant ? 18 : 12) {
            statItem(icon: "person.3.fill", value: "\(athleteCount)", labelKey: "branch.card.athletes")
            statItem(icon: "graduationcap.fill", value: "\(coachCount)", labelKey: "branch.card.coaches")
            statItem(icon: "calendar.badge.checkmark", value: "\(sessionsPerWeek)", labelKey: "branch.card.sessions_week")
            statItem(icon: "person.crop.rectangle.stack.fill", value: utilizationLabel, labelKey: "branch.card.utilization")
        }
    }

    private func statItem(icon: String, value: String, labelKey: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .scaledFont(.caption2)
                    .foregroundStyle(.tint)
                Text(labelKey)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(verbatim: value)
                .scaledFont(.headline, monospacedDigit: true)
                .foregroundStyle(.primary)
                .environment(\.layoutDirection, .leftToRight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var utilizationLabel: String {
        guard branch.capacity > 0 else { return "—" }
        let pct = Double(athleteCount) / Double(branch.capacity) * 100
        return String(format: "%.0f%%", pct)
    }

    // MARK: - Style helpers

    private var borderColor: Color {
        if isDominant {
            return brandColor.opacity(0.5)
        }
        return Color.secondary.opacity(0.15)
    }

    private var shadowColor: Color {
        if isDominant {
            return brandColor.opacity(0.18)
        }
        return Color.black.opacity(0.04)
    }
}


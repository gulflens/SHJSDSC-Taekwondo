import SwiftUI

/// Soft-gradient identity hero used at the top of `MyProfileView` and the
/// Settings dashboard. Layout follows the federation references in
/// `/References`: avatar + bilingual identity on the left, a 2×2 status grid
/// (Member Since / Role / Account Status / User ID) on the right, with an
/// "Edit Profile" capsule pinned top-right.
public struct ProfileHeroCard: View {
    private let user: User
    private let primaryBranch: Branch?
    private let isWide: Bool
    private let onEdit: () -> Void

    public init(
        user: User,
        primaryBranch: Branch?,
        isWide: Bool,
        onEdit: @escaping () -> Void
    ) {
        self.user = user
        self.primaryBranch = primaryBranch
        self.isWide = isWide
        self.onEdit = onEdit
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            content
                .padding(isWide ? 24 : 18)
            Button(action: onEdit) {
                Label("profile.edit.title", systemImage: "pencil")
                    .scaledFont(.footnote, weight: .semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
            .padding(isWide ? 16 : 12)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.22),
                    Color.accentColor.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 14, y: 6)
    }

    @ViewBuilder
    private var content: some View {
        if isWide {
            HStack(alignment: .top, spacing: 22) {
                identityBlock
                Spacer(minLength: 12)
                statGrid
                    .frame(width: 360)
            }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                identityBlock
                statGrid
            }
        }
    }

    private var identityBlock: some View {
        let avatarSize: CGFloat = isWide ? 96 : 72
        let cornerRadius: CGFloat = avatarSize * 0.22
        return HStack(alignment: .top, spacing: 14) {
            Avatar(
                seed: user.avatarSeed,
                label: initials,
                size: avatarSize,
                urlString: user.avatarURL,
                shape: .roundedRect(cornerRadius: cornerRadius),
                localCacheID: user.id
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
            )
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(verbatim: user.fullName.isEmpty ? "—" : user.fullName)
                        .font(isWide ? .title.bold() : .title2.bold())
                        .foregroundStyle(.primary)
                    Image(systemName: "checkmark.seal.fill")
                        .scaledFont(.subheadline)
                        .foregroundStyle(.tint)
                }
                if !user.fullNameAr.isEmpty {
                    Text(verbatim: user.fullNameAr)
                        .scaledFont(.body)
                        .foregroundStyle(.secondary)
                        .environment(\.layoutDirection, .rightToLeft)
                }
                HStack(spacing: 6) {
                    HeroChip(text: NSLocalizedString(user.role.label, comment: ""), tone: .accent)
                    HeroChip(text: NSLocalizedString("profile.status.active", comment: ""), tone: .success, dot: true)
                }
                .padding(.top, 4)
                Text("profile.tagline")
                    .scaledFont(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
    }

    private var statGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
        return LazyVGrid(columns: columns, spacing: 10) {
            HeroStatTile(
                icon: "calendar",
                label: "profile.hero.member_since",
                value: "—"
            )
            HeroStatTile(
                icon: "clock.arrow.circlepath",
                label: "profile.hero.last_login",
                value: NSLocalizedString("profile.hero.last_login.now", comment: "")
            )
            HeroStatTile(
                icon: "checkmark.seal.fill",
                label: "profile.hero.status",
                value: NSLocalizedString("profile.status.active", comment: ""),
                accent: .secondaryAccent,
                showsDot: true
            )
            HeroStatTile(
                icon: "number",
                label: "profile.hero.user_id",
                value: shortUserID
            )
        }
    }

    private var initials: String {
        let parts = user.fullName.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }

    private var shortUserID: String {
        let raw = user.id.uuidString.replacingOccurrences(of: "-", with: "")
        return "USR-\(raw.prefix(6).uppercased())"
    }
}

/// Compact translucent stat tile used in the right column of `ProfileHeroCard`.
public struct HeroStatTile: View {
    private let icon: String
    private let label: LocalizedStringKey
    private let value: String
    private let accent: Color
    private let showsDot: Bool

    public init(
        icon: String,
        label: LocalizedStringKey,
        value: String,
        accent: Color = .accentColor,
        showsDot: Bool = false
    ) {
        self.icon = icon
        self.label = label
        self.value = value
        self.accent = accent
        self.showsDot = showsDot
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .scaledFont(.caption2, weight: .semibold)
                    .foregroundStyle(accent)
                Text(label)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            HStack(spacing: 6) {
                if showsDot {
                    Circle()
                        .fill(accent)
                        .frame(width: 7, height: 7)
                }
                Text(verbatim: value)
                    .scaledFont(.footnote, weight: .semibold, monospacedDigit: true)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Small pill chip used inside the hero identity block (role + status).
private struct HeroChip: View {
    enum Tone { case accent, success }
    let text: String
    let tone: Tone
    var dot: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            if dot {
                Circle().fill(color).frame(width: 6, height: 6)
            }
            Text(verbatim: text)
                .scaledFont(.caption, weight: .semibold)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(color.opacity(0.15), in: Capsule())
        .foregroundStyle(color)
    }

    private var color: Color {
        switch tone {
        case .accent: .accentColor
        case .success: .secondaryAccent
        }
    }
}

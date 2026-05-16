import SwiftUI

// MARK: - Drill design tokens
//
// Stage 1.8 — Drill Library remodel. Colour mapping for drill categories and
// difficulty lives in the Features layer (Core/ must not import SwiftUI).
// These extensions plus the small chip primitives below are the shared
// vocabulary every Drill Library surface is built from.

public extension DrillCategory {
    /// Pastel accent used for the category pill, thumbnail tint, and row icon.
    var tint: Color {
        switch self {
        case .technique:    .accentColor
        case .sparring:     .orange
        case .flexibility:  .purple
        case .conditioning: .secondaryAccent
        case .poomsae:      .cyan
        case .footwork:     .indigo
        case .strength:     .pink
        }
    }
}

public extension DrillDifficulty {
    /// Beginner → emerald, Intermediate → orange, Advanced → red.
    var tint: Color {
        switch self {
        case .beginner:     .secondaryAccent
        case .intermediate: .orange
        case .advanced:     .red
        }
    }
}

// MARK: - Level badge

/// Lightweight, rounded difficulty badge — "Beginner / Intermediate / Advanced".
public struct DrillLevelBadge: View {
    private let difficulty: DrillDifficulty

    public init(_ difficulty: DrillDifficulty) {
        self.difficulty = difficulty
    }

    public var body: some View {
        Text(localizedKey: difficulty.labelKey)
            .scaledFont(.caption2, weight: .semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(difficulty.tint.opacity(0.16), in: Capsule())
            .foregroundStyle(difficulty.tint)
    }
}

// MARK: - Tag chip

/// Small `#hashtag`-style chip for a drill's free-text descriptive tags.
public struct DrillTagChip: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "number")
                .scaledFont(.caption2, weight: .bold)
                .foregroundStyle(.tertiary)
            Text(verbatim: text)
                .scaledFont(.caption2, weight: .medium)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.08), in: Capsule())
    }
}

// MARK: - Equipment chip

/// Equipment requirement row — icon + name + optional quantity note.
public struct EquipmentChip: View {
    private let item: DrillEquipmentItem

    public init(_ item: DrillEquipmentItem) {
        self.item = item
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.systemIcon)
                .scaledFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(verbatim: item.name)
                .scaledFont(.subheadline)
                .foregroundStyle(.primary)
            if let note = item.quantityNote, !note.isEmpty {
                Text(verbatim: "(\(note))")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Muscle-focus chip

/// Soft, rounded pastel chip naming one targeted muscle group.
public struct MuscleFocusChip: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(verbatim: text)
            .scaledFont(.caption, weight: .medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.accentColor.opacity(0.10), in: Capsule())
            .foregroundStyle(Color.accentColor)
    }
}

// MARK: - Intensity dots

/// Five-dot intensity meter. Filled dots use the accent colour.
public struct IntensityDots: View {
    private let level: Int

    public init(level: Int) {
        self.level = max(0, min(5, level))
    }

    public var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(i < level ? Color.accentColor : Color.secondary.opacity(0.18))
                    .frame(width: 9, height: 9)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

// MARK: - Drill thumbnail

/// Square rounded drill thumbnail. Loads an asset-catalogue image by
/// `imageAssetName` when present; otherwise renders a category-tinted
/// gradient with the category glyph so the UI is never empty.
public struct DrillThumbnail: View {
    private let drill: DrillLibraryEntry
    private let size: CGFloat
    private let corner: CGFloat

    public init(_ drill: DrillLibraryEntry, size: CGFloat = 52, corner: CGFloat = 12) {
        self.drill = drill
        self.size = size
        self.corner = corner
    }

    public var body: some View {
        Group {
            if let img = loadedImage {
                img.resizable().scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [drill.category.tint.opacity(0.85), drill.category.tint.opacity(0.5)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: drill.category.systemIcon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
        )
    }

    /// Resolves the asset only if it actually exists in the bundle, so a
    /// missing image falls back to the gradient rather than rendering blank.
    private var loadedImage: Image? {
        guard let name = drill.imageAssetName, !name.isEmpty else { return nil }
        #if os(iOS)
        if let ui = UIImage(named: name) { return Image(uiImage: ui) }
        #elseif os(macOS)
        if let ns = NSImage(named: name) { return Image(nsImage: ns) }
        #endif
        return nil
    }
}

// MARK: - Primary action button

/// Premium filled blue button with an icon — used for "New drill" and
/// "Start timer".
public struct PrimaryActionButton: View {
    private let titleKey: String
    private let systemIcon: String
    private let action: () -> Void

    public init(titleKey: String, systemIcon: String, action: @escaping () -> Void) {
        self.titleKey = titleKey
        self.systemIcon = systemIcon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemIcon)
                    .scaledFont(.footnote, weight: .semibold)
                Text(localizedKey: titleKey)
                    .scaledFont(.subheadline, weight: .semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(
                    LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.82)],
                                   startPoint: .top, endPoint: .bottom))
            )
            .shadow(color: Color.accentColor.opacity(0.32), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mode switcher (Timer / Library)

/// Capsule segmented control for the Timer / Library mode switch in the
/// Drill Library header.
public struct DrillModeSwitcher: View {
    @Binding private var isLibrary: Bool

    public init(isLibrary: Binding<Bool>) {
        _isLibrary = isLibrary
    }

    public var body: some View {
        HStack(spacing: 3) {
            segment(titleKey: "drills.tab.timer", active: !isLibrary) { isLibrary = false }
            segment(titleKey: "drills.tab.library", active: isLibrary) { isLibrary = true }
        }
        .padding(3)
        .background(Color.secondary.opacity(0.10), in: Capsule())
    }

    private func segment(titleKey: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { action() }
        } label: {
            Text(localizedKey: titleKey)
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(active ? Color.white : Color.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(active ? Color.accentColor : Color.clear)
                        .shadow(color: active ? Color.accentColor.opacity(0.3) : .clear,
                                radius: 5, y: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Drill list row

/// Premium drill row for the library list panel — thumbnail + title + level
/// badge + tag chips + duration, with a contextual menu. The caller wraps it
/// in the row's tap target; `selected` paints the active blue-border state.
public struct DrillListRow: View {
    private let drill: DrillLibraryEntry
    private let selected: Bool
    private let canEdit: Bool
    private let onEdit: () -> Void
    private let onDelete: () -> Void

    public init(
        drill: DrillLibraryEntry,
        selected: Bool,
        canEdit: Bool,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.drill = drill
        self.selected = selected
        self.canEdit = canEdit
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            DrillThumbnail(drill, size: 54)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(verbatim: drill.name)
                        .scaledFont(.subheadline, weight: .bold)
                        .lineLimit(1)
                    if let diff = drill.difficulty {
                        DrillLevelBadge(diff)
                    }
                }
                if !drill.tags.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(drill.tags.prefix(3), id: \.self) { DrillTagChip($0) }
                    }
                } else {
                    Text(verbatim: drill.summary)
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if let mins = drill.durationMinutes {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .scaledFont(.caption2, weight: .medium)
                    Text(verbatim: "\(mins) min")
                        .scaledFont(.caption, weight: .medium)
                        .environment(\.layoutDirection, .leftToRight)
                }
                .foregroundStyle(.secondary)
            }
            if canEdit {
                Menu {
                    Button { onEdit() } label: { Label("action.edit", systemImage: "pencil") }
                    Button(role: .destructive) { onDelete() } label: {
                        Label("action.delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .scaledFont(.subheadline, weight: .semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(selected ? Color.accentColor.opacity(0.07) : Color.secondary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(selected ? Color.accentColor : Color.secondary.opacity(0.08),
                        lineWidth: selected ? 1.5 : 1)
        )
        .shadow(color: selected ? Color.accentColor.opacity(0.18) : .clear, radius: 8, y: 3)
        .contentShape(Rectangle())
    }
}

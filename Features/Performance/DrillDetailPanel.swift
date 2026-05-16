import SwiftUI

// MARK: - Drill detail panel
//
// Stage 1.8 — the right-hand panel of the Drill Library. Header + metadata
// card strip + segmented tabs + a two-column body (tab content on the left,
// a persistent preview column on the right).

public struct DrillDetailPanel: View {
    private let drill: DrillLibraryEntry
    private let related: [DrillLibraryEntry]
    private let canEdit: Bool
    private let onEdit: () -> Void
    private let onStartTimer: () -> Void
    private let onSelectRelated: (DrillLibraryEntry) -> Void

    @State private var tab: DrillTab = .overview
    @Environment(\.horizontalSizeClass) private var hSize

    public init(
        drill: DrillLibraryEntry,
        related: [DrillLibraryEntry],
        canEdit: Bool,
        onEdit: @escaping () -> Void,
        onStartTimer: @escaping () -> Void,
        onSelectRelated: @escaping (DrillLibraryEntry) -> Void
    ) {
        self.drill = drill
        self.related = related
        self.canEdit = canEdit
        self.onEdit = onEdit
        self.onStartTimer = onStartTimer
        self.onSelectRelated = onSelectRelated
    }

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                metadataStrip
                tabBar
                if isWide {
                    HStack(alignment: .top, spacing: 20) {
                        tabContent.frame(maxWidth: .infinity, alignment: .leading)
                        DrillPreviewPanel(drill: drill).frame(width: 248)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 18) {
                        tabContent
                        DrillPreviewPanel(drill: drill)
                    }
                }
            }
            .padding(20)
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
        .id(drill.id)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: drill.category.systemIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(verbatim: drill.name)
                            .scaledFont(.title3, weight: .bold)
                        if let diff = drill.difficulty {
                            DrillLevelBadge(diff)
                        }
                    }
                    Text(verbatim: drill.summary)
                        .scaledFont(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            actionRow
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            PrimaryActionButton(titleKey: "drill.start_timer", systemIcon: "timer", action: onStartTimer)
            if canEdit {
                Button(action: onEdit) {
                    Label("action.edit", systemImage: "pencil")
                        .scaledFont(.subheadline, weight: .semibold)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .foregroundStyle(.primary)
                        .background(Color.secondary.opacity(0.10), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            Menu {
                if let url = drill.videoURL, let link = URL(string: url) {
                    Link(destination: link) { Label("drill.open_video", systemImage: "play.rectangle") }
                }
                Button { onStartTimer() } label: { Label("drill.start_timer", systemImage: "timer") }
            } label: {
                Image(systemName: "ellipsis")
                    .scaledFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 38, height: 38)
                    .background(Color.secondary.opacity(0.10), in: Circle())
            }
            .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
            Spacer(minLength: 0)
        }
    }

    // MARK: Metadata strip

    private var metadataStrip: some View {
        let cols = [GridItem(.adaptive(minimum: 116), spacing: 10)]
        return LazyVGrid(columns: cols, spacing: 10) {
            if let mins = drill.durationMinutes {
                DrillMetadataCard(labelKey: "drill.meta.duration",
                                  value: .text("\(mins) min"))
            }
            if let diff = drill.difficulty {
                DrillMetadataCard(labelKey: "drill.meta.level",
                                  value: .localized(diff.labelKey))
            }
            DrillMetadataCard(labelKey: "drill.meta.category",
                              value: .localized(drill.category.labelKey))
            if !drill.equipment.isEmpty {
                DrillMetadataCard(labelKey: "drill.meta.equipment",
                                  value: .text(drill.equipment.map(\.name).joined(separator: ", ")))
            }
            if let intensity = drill.intensity {
                DrillMetadataCard(labelKey: "drill.meta.intensity",
                                  value: .intensity(intensity))
            }
        }
    }

    // MARK: Tabs

    private var visibleTabs: [DrillTab] {
        DrillTab.allCases.filter { tab in
            switch tab {
            case .overview:  return true
            case .steps:     return !drill.instructions.isEmpty
            case .equipment: return !drill.equipment.isEmpty
            case .variations: return !drill.variations.isEmpty
            case .notes:     return drill.notes?.isEmpty == false
            case .related:   return !related.isEmpty
            }
        }
    }

    private var tabBar: some View {
        SegmentedTabBar(
            selection: $tab,
            tabs: visibleTabs,
            title: { NSLocalizedString($0.titleKey, comment: "") }
        )
        .onChange(of: drill.id) { _, _ in tab = .overview }
    }

    // MARK: Tab content

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .overview:   overviewTab
        case .steps:      stepsSection
        case .equipment:  equipmentTab
        case .variations: variationsTab
        case .notes:      notesTab
        case .related:    relatedTab
        }
    }

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            section(titleKey: "drill.section.description") {
                Text(verbatim: drill.summary)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !drill.instructions.isEmpty { stepsSection }
            if let tip = drill.coachingTip, !tip.isEmpty {
                CoachingTipCard(text: tip)
            }
            if let metrics = drill.metrics, !metrics.isEmpty {
                DrillMetricsGrid(metrics: metrics)
            }
        }
    }

    private var stepsSection: some View {
        section(titleKey: "drill.section.how_to") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(drill.instructions.enumerated()), id: \.offset) { idx, step in
                    DrillInstructionStep(number: idx + 1, text: step)
                }
            }
        }
    }

    private var equipmentTab: some View {
        section(titleKey: "drill.meta.equipment") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(drill.equipment) { EquipmentChip($0) }
            }
        }
    }

    private var variationsTab: some View {
        section(titleKey: "drill.tab.variations") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(drill.variations) { v in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: v.title).scaledFont(.subheadline, weight: .semibold)
                        Text(verbatim: v.detail)
                            .scaledFont(.caption).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.secondary.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private var notesTab: some View {
        section(titleKey: "drill.tab.notes") {
            Text(verbatim: drill.notes ?? "")
                .scaledFont(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var relatedTab: some View {
        section(titleKey: "drill.tab.related") {
            VStack(spacing: 8) {
                ForEach(related) { r in
                    Button { onSelectRelated(r) } label: {
                        HStack(spacing: 10) {
                            DrillThumbnail(r, size: 38, corner: 9)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: r.name).scaledFont(.subheadline, weight: .semibold)
                                Text(localizedKey: r.category.labelKey)
                                    .scaledFont(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.forward")
                                .scaledFont(.caption2, weight: .semibold)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func section<Content: View>(
        titleKey: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedKey: titleKey)
                .scaledFont(.headline, weight: .semibold)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Detail tabs

enum DrillTab: String, CaseIterable, Identifiable, Hashable {
    case overview, steps, equipment, variations, notes, related
    var id: String { rawValue }
    var titleKey: String {
        switch self {
        case .overview:   "drill.tab.overview"
        case .steps:      "drill.tab.steps"
        case .equipment:  "drill.tab.equipment"
        case .variations: "drill.tab.variations"
        case .notes:      "drill.tab.notes"
        case .related:    "drill.tab.related"
        }
    }
}

// MARK: - Metadata card

/// Small rounded card in the detail header strip — caption label over a bold
/// value, or an intensity dot meter.
public struct DrillMetadataCard: View {
    public enum Value {
        case text(String)
        case localized(String)
        case intensity(Int)
    }

    private let labelKey: String
    private let value: Value

    public init(labelKey: String, value: Value) {
        self.labelKey = labelKey
        self.value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localizedKey: labelKey)
                .scaledFont(.caption2, weight: .medium)
                .foregroundStyle(.secondary)
            switch value {
            case .text(let s):
                Text(verbatim: s)
                    .scaledFont(.subheadline, weight: .bold)
                    .lineLimit(1)
            case .localized(let key):
                Text(localizedKey: key)
                    .scaledFont(.subheadline, weight: .bold)
                    .lineLimit(1)
            case .intensity(let level):
                IntensityDots(level: level).padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

// MARK: - Instruction step

/// One numbered "how to perform" row — blue circle + step text.
public struct DrillInstructionStep: View {
    private let number: Int
    private let text: String

    public init(number: Int, text: String) {
        self.number = number
        self.text = text
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Text(verbatim: "\(number)")
                .scaledFont(.caption, weight: .bold, monospacedDigit: true)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24, height: 24)
                .background(Color.accentColor.opacity(0.12), in: Circle())
                .environment(\.layoutDirection, .leftToRight)
            Text(verbatim: text)
                .scaledFont(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Coaching tip card

/// Highlighted soft-blue panel carrying a single coaching cue.
public struct CoachingTipCard: View {
    private let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "lightbulb.fill")
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 3) {
                Text("drill.coaching_tip")
                    .scaledFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Color.accentColor)
                Text(verbatim: text)
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.07),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.accentColor.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Metrics grid

/// Pastel grid of compact drill metrics (sets / distance / rest / …).
public struct DrillMetricsGrid: View {
    private let metrics: DrillMetrics

    public init(metrics: DrillMetrics) {
        self.metrics = metrics
    }

    public var body: some View {
        let cols = [GridItem(.adaptive(minimum: 92), spacing: 9)]
        LazyVGrid(columns: cols, spacing: 9) {
            if let s = metrics.sets {
                DrillMetricsCard(labelKey: "drill.metric.sets", value: "\(s)")
            }
            if let d = metrics.distance {
                DrillMetricsCard(labelKey: "drill.metric.distance", value: d)
            }
            if let r = metrics.rest {
                DrillMetricsCard(labelKey: "drill.metric.rest", value: r)
            }
            if let t = metrics.totalTime {
                DrillMetricsCard(labelKey: "drill.metric.total_time", value: t)
            }
            if let a = metrics.athleteLevelNote {
                DrillMetricsCard(labelKey: "drill.metric.athletes", value: a)
            }
            if let sp = metrics.spaceRequired {
                DrillMetricsCard(labelKey: "drill.metric.space", value: sp)
            }
        }
    }
}

/// One pastel metric card — caption over a bold value.
public struct DrillMetricsCard: View {
    private let labelKey: String
    private let value: String

    public init(labelKey: String, value: String) {
        self.labelKey = labelKey
        self.value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(localizedKey: labelKey)
                .scaledFont(.caption2, weight: .medium)
                .foregroundStyle(.secondary)
            Text(verbatim: value)
                .scaledFont(.callout, weight: .bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(Color.accentColor.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Preview panel

/// Far-right column: video preview + equipment list + muscle-focus chips.
public struct DrillPreviewPanel: View {
    private let drill: DrillLibraryEntry

    public init(drill: DrillLibraryEntry) {
        self.drill = drill
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            videoPreview
            if !drill.equipment.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    Text("drill.meta.equipment")
                        .scaledFont(.headline, weight: .semibold)
                    ForEach(drill.equipment) { EquipmentChip($0) }
                }
            }
            if !drill.muscleFocus.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    Text("drill.muscle_focus")
                        .scaledFont(.headline, weight: .semibold)
                    FlowChips(drill.muscleFocus) { MuscleFocusChip($0) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var videoPreview: some View {
        let thumb = ZStack {
            DrillThumbnailWide(drill: drill)
            Circle()
                .fill(.white)
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                        .offset(x: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
            if let secs = drill.videoDurationSeconds {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(verbatim: timeLabel(secs))
                            .scaledFont(.caption2, weight: .semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 5))
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
                .padding(8)
            }
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

        if let url = drill.videoURL, let link = URL(string: url) {
            Link(destination: link) { thumb }.buttonStyle(.plain)
        } else {
            thumb
        }
    }

    private func timeLabel(_ secs: Int) -> String {
        String(format: "%d:%02d", secs / 60, secs % 60)
    }
}

/// Wide 16:9-ish drill image used inside the video preview, with the same
/// asset-or-gradient fallback as `DrillThumbnail`.
private struct DrillThumbnailWide: View {
    let drill: DrillLibraryEntry

    var body: some View {
        Group {
            if let img = loaded {
                img.resizable().scaledToFill()
            } else {
                LinearGradient(
                    colors: [drill.category.tint.opacity(0.9), drill.category.tint.opacity(0.55)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: drill.category.systemIcon)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var loaded: Image? {
        guard let name = drill.imageAssetName, !name.isEmpty else { return nil }
        #if os(iOS)
        if let ui = UIImage(named: name) { return Image(uiImage: ui) }
        #elseif os(macOS)
        if let ns = NSImage(named: name) { return Image(nsImage: ns) }
        #endif
        return nil
    }
}

// MARK: - Flow layout for chips

/// Simple wrapping row of chips. Uses SwiftUI's native `Layout` so it mirrors
/// correctly under RTL.
public struct FlowChips<Item: Hashable, Chip: View>: View {
    private let items: [Item]
    private let chip: (Item) -> Chip

    public init(_ items: [Item], @ViewBuilder chip: @escaping (Item) -> Chip) {
        self.items = items
        self.chip = chip
    }

    public var body: some View {
        DrillFlowLayout(spacing: 6) {
            ForEach(items, id: \.self) { chip($0) }
        }
    }
}

/// Minimal flow layout — places subviews left-to-right, wrapping to a new
/// line when the row is full.
public struct DrillFlowLayout: Layout {
    var spacing: CGFloat = 6

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidth - spacing)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth - spacing)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sv.place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                     proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

import SwiftUI

/// Theme tokens for the app.
///
/// `Color.appBackground` / `Color.cardBackground` / `Color.sidebarBackground`
/// etc. are intentionally **not** declared here — Xcode 15+ auto-generates
/// static `Color` properties from the asset catalogue (driven by the
/// `Generate Swift Asset Symbol Extensions` build setting). Declaring them
/// again would produce "Invalid redeclaration" errors.
///
/// To rename a colour token, rename its asset in `Assets.xcassets` and the
/// auto-generated symbol updates with it. Add new tokens by adding a new
/// `.colorset` to the asset catalogue rather than to this file.
///
/// The one *non*-asset alias below (`Color.tint`) lives here so it has a
/// single source of truth — removing four file-private copies that had
/// drifted across `AddAthleteView`, `GoalsCard`, `ImprovementPlanCard`,
/// and `CertificateView`.
extension Color {
    /// Semantic alias for the app's accent colour. Use this instead of
    /// `Color.accentColor` directly so a future palette change is a
    /// one-line edit.
    static var tint: Color { .accentColor }
}

public extension Text {
    /// Renders a localised string whose key is computed at runtime. Use this
    /// instead of `Text(localizedKey: runtimeStringVar)` — SwiftUI's
    /// LocalizedStringKey lookup is unreliable for runtime-built keys, which
    /// produced the dotted-key "athlete.tab.overview" etc. text users saw in
    /// the Stage 1.7 surface. This helper consults `Bundle.main` directly via
    /// `NSLocalizedString` and renders the resolved value verbatim.
    init(localizedKey key: String) {
        self.init(verbatim: NSLocalizedString(key, comment: ""))
    }
}

/// Premium navigation chrome — uses the system's translucent material so the
/// nav bar feels like a layered glass overlay rather than a solid colored bar.
/// Stage 1.7 (full app remodel) removed the explicit colored fill that used
/// to bake "SidebarBackground" into every toolbar.
public struct AppNavigationChrome: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        #if os(iOS)
        content
            .toolbarBackground(.thinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        #else
        content
        #endif
    }
}

public struct AppSearchField: View {
    @Binding private var text: String
    private let prompt: LocalizedStringKey

    public init(text: Binding<String>, prompt: LocalizedStringKey = "action.search") {
        _text = text
        self.prompt = prompt
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("", text: $text, prompt: Text(prompt))
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.cardBackground, in: Capsule())
    }
}

public extension View {
    func bareToolbarButton() -> some View {
        self
    }

    func appNavigationChrome() -> some View {
        self.modifier(AppNavigationChrome())
    }
}

/// Compact chip rendered on placeholder rows in Profile + Settings to flag
/// features that are visually present but not yet wired to a real backend.
/// Pair with `.opacity(0.55)` on the surrounding row + a `.disabled(true)`
/// so the row is honest about its non-interactive state.
public struct ComingSoonChip: View {
    public init() {}

    public var body: some View {
        Text("ui.coming_soon")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.secondary.opacity(0.15), in: Capsule())
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

/// User-selectable accent palette wired to Settings → Appearance → Accent.
/// `rawValue` is what gets persisted in `@AppStorage("prefs.accent")`.
/// `color` is the resolved SwiftUI Color applied via `.tint(_:)` at the app
/// root — same swatches the Settings picker shows. The default `.blue` case
/// resolves to the asset-catalogue `AccentColor`, so an unset preference
/// matches the existing app identity.
public enum AppAccent: String, CaseIterable, Identifiable, Sendable {
    case blue
    case emerald
    case cyan
    case purple
    case orange
    case red

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .blue:    Color.accentColor                                    // asset-catalogue default
        case .emerald: Color(red: 0.06, green: 0.64, blue: 0.42)
        case .cyan:    Color(red: 0.07, green: 0.66, blue: 0.78)
        case .purple:  Color(red: 0.55, green: 0.36, blue: 0.85)
        case .orange:  Color(red: 0.94, green: 0.55, blue: 0.18)
        case .red:     Color(red: 0.88, green: 0.28, blue: 0.34)
        }
    }

    /// Tolerant lookup: any unrecognized string falls back to the default.
    public static func from(_ raw: String) -> AppAccent {
        AppAccent(rawValue: raw) ?? .blue
    }
}

public extension View {
    /// Applies the user-chosen accent in both forms SwiftUI consults:
    /// `.tint(_:)` for modern ShapeStyle slots (`.foregroundStyle(.tint)`,
    /// progress views, toggles, etc.) and `.accentColor(_:)` for legacy
    /// `Color.accentColor` lookups that pre-Stage-1.7 code uses for fills.
    /// Apply once at the app root.
    @ViewBuilder
    func appAccent(_ accent: AppAccent) -> some View {
        // `accentColor(_:)` is deprecated but is still the only modifier that
        // reliably propagates to `Color.accentColor` references throughout
        // the view tree. Pairing it with `.tint(_:)` covers both lookups.
        self
            .tint(accent.color)
            .accentColor(accent.color)
    }
}

/// macOS-only UI zoom preset. The iPad-tuned layouts render very small at
/// macOS's default text sizes — this enum maps user-friendly tiers onto
/// `DynamicTypeSize` so the app root can resize all system text styles (and
/// any icons drawn with `.font(.title3)` etc.) in one place.
public enum MacUIScale: String, CaseIterable, Identifiable, Sendable {
    case standard
    case large
    case xLarge
    case xxLarge

    public var id: String { rawValue }

    /// Drives `.dynamicTypeSize` for views that use semantic system fonts
    /// (`.body`, `.caption`, `.title3`, etc.) — the vast majority of the app,
    /// including sidebar labels and input-field text. The baseline starts at
    /// `.xLarge` (not `.large`) because the iPad-tuned layout renders too
    /// small at macOS defaults — testers reported even "Standard" felt
    /// zoomed-out. "Huge" reaches into the accessibility range deliberately.
    public var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .standard: .xLarge
        case .large:    .xxLarge
        case .xLarge:   .xxxLarge
        case .xxLarge:  .accessibility1
        }
    }

    /// Linear multiplier applied to fixed-size fonts (`.font(.system(size:))`)
    /// via the `.scaledFont(...)` helper, plus explicit `.frame(_)` numbers
    /// that opt into `\.uiScale` (sidebar column width, icon boxes, etc.).
    /// `.dynamicTypeSize` can't touch these because the size is hard-coded —
    /// this multiplier fills that gap.
    public var scaleFactor: CGFloat {
        switch self {
        case .standard: 1.10
        case .large:    1.25
        case .xLarge:   1.40
        case .xxLarge:  1.60
        }
    }

    /// Drives `.controlSize` so text fields, buttons, pickers, steppers, and
    /// toggles grow with the zoom tier. macOS/iOS only expose a handful of
    /// discrete control sizes, so the four tiers collapse onto two steps.
    public var controlSize: ControlSize {
        switch self {
        case .standard, .large: .large
        case .xLarge, .xxLarge: .extraLarge
        }
    }

    public var labelKey: LocalizedStringKey {
        switch self {
        case .standard: "settings.ui_scale.standard"
        case .large:    "settings.ui_scale.large"
        case .xLarge:   "settings.ui_scale.xlarge"
        case .xxLarge:  "settings.ui_scale.xxlarge"
        }
    }

    /// Tolerant lookup: any unrecognized string falls back to the macOS
    /// default (`xLarge`) so existing installs upgrade smoothly.
    public static func from(_ raw: String) -> MacUIScale {
        MacUIScale(rawValue: raw) ?? .xLarge
    }
}

/// iPad UI zoom preset. The app's layouts are tuned for a comfortable iPad
/// reading distance, but some users want a larger interface. This enum drives
/// an **opt-in** zoom on iPad: `\.uiScale` (which every `.scaledFont` view and
/// every uiScale-aware dimension honours) plus `.controlSize` for native
/// controls. `.standard` is a true 1.0 baseline — iPad renders exactly as
/// before until the user picks a larger tier in Settings → Appearance.
public enum IPadUIScale: String, CaseIterable, Identifiable, Sendable {
    case standard
    case large
    case xLarge
    case xxLarge

    public var id: String { rawValue }

    /// Linear multiplier applied via `\.uiScale`. `1.0` at `.standard` so the
    /// baseline is a genuine no-op.
    public var scaleFactor: CGFloat {
        switch self {
        case .standard: 1.0
        case .large:    1.20
        case .xLarge:   1.40
        case .xxLarge:  1.60
        }
    }

    /// Native-control sizing so text fields, buttons, pickers and steppers
    /// keep pace with the zoomed text.
    public var controlSize: ControlSize {
        switch self {
        case .standard:         .regular
        case .large:            .large
        case .xLarge, .xxLarge: .extraLarge
        }
    }

    /// Reuses the macOS UI-zoom labels — the tiers read identically.
    public var labelKey: LocalizedStringKey {
        switch self {
        case .standard: "settings.ui_scale.standard"
        case .large:    "settings.ui_scale.large"
        case .xLarge:   "settings.ui_scale.xlarge"
        case .xxLarge:  "settings.ui_scale.xxlarge"
        }
    }

    /// Tolerant lookup — unrecognised strings fall back to the 1.0 baseline.
    public static func from(_ raw: String) -> IPadUIScale {
        IPadUIScale(rawValue: raw) ?? .standard
    }
}

/// Whether a list module should render its side-by-side list + detail split.
///
/// The split layout is reserved for a genuinely wide canvas — iPad in
/// landscape (and macOS). iPhone, and **iPad in portrait**, return `false`:
/// those drop the detail panel and push a separate detail screen instead.
///
/// `size` is the module's canvas, measured by a `GeometryReader`. Once the
/// iPhone idiom is excluded, width-greater-than-height is a reliable,
/// rotation-reactive proxy for a landscape interface — `horizontalSizeClass`
/// cannot tell iPad portrait from landscape (both are `.regular`).
public func usesSplitDetailLayout(for size: CGSize) -> Bool {
    #if os(iOS)
    guard UIDevice.current.userInterfaceIdiom == .pad else { return false }
    #endif
    return size.width > size.height
}

// MARK: - UI scale environment + scaled-font helper

private struct UIScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

public extension EnvironmentValues {
    /// Multiplier for fixed-size visual primitives that need to honor the
    /// macOS UI Zoom preset. Set at the scene root from
    /// `MacUIScale.scaleFactor`; defaults to `1.0` everywhere else so iOS /
    /// iPadOS / previews render unchanged.
    var uiScale: CGFloat {
        get { self[UIScaleKey.self] }
        set { self[UIScaleKey.self] = newValue }
    }
}

private struct ScaledFontModifier: ViewModifier {
    @Environment(\.uiScale) private var uiScale
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    let monospacedDigit: Bool

    func body(content: Content) -> some View {
        var font: Font = .system(size: size * uiScale, weight: weight, design: design)
        if monospacedDigit { font = font.monospacedDigit() }
        return content.font(font)
    }
}

public extension Font.TextStyle {
    /// Base point size for this text style, used by `scaledFont(_:)`. macOS
    /// renders semantic fonts (`.body` etc.) noticeably smaller than the
    /// iPad-tuned layout expects, and — unlike iOS — does NOT meaningfully
    /// honor `\.dynamicTypeSize`. So the app drives one explicit ramp here
    /// and multiplies by `\.uiScale` at render time. Tuned to match the
    /// sidebar (title3 ≈ 16, subheadline ≈ 12, caption2 ≈ 10).
    var scaledBaseSize: CGFloat {
        switch self {
        case .largeTitle:  26
        case .title:       22
        case .title2:      18
        case .title3:      16
        case .headline:    14
        case .body:        14
        case .callout:     13
        case .subheadline: 12
        case .footnote:    11
        case .caption:     11
        case .caption2:    10
        @unknown default:  14
        }
    }

    /// Weight a bare `.font(.headline)` implies — headline is semibold by
    /// convention, everything else regular.
    var impliedWeight: Font.Weight {
        self == .headline ? .semibold : .regular
    }
}

public extension View {
    /// Drop-in replacement for `.font(.system(size:weight:design:))` that
    /// multiplies the point size by `\.uiScale`. Use this for any explicit
    /// point size you'd otherwise hard-code so the macOS UI Zoom picker
    /// affects it. Pass `monospacedDigit: true` to replace
    /// `.font(.system(size:).monospacedDigit())` chains in one shot.
    func scaledFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        monospacedDigit: Bool = false
    ) -> some View {
        modifier(ScaledFontModifier(size: size, weight: weight, design: design, monospacedDigit: monospacedDigit))
    }

    /// Drop-in replacement for `.font(.body)` / `.font(.caption.weight(...))`
    /// etc. Maps the semantic style onto `scaledBaseSize × \.uiScale` so the
    /// whole app scales off one ramp — required on macOS, which ignores
    /// `\.dynamicTypeSize` for semantic fonts. `weight: nil` uses the style's
    /// implied weight (semibold for headline, regular otherwise).
    func scaledFont(
        _ style: Font.TextStyle,
        weight: Font.Weight? = nil,
        design: Font.Design = .default,
        monospacedDigit: Bool = false
    ) -> some View {
        modifier(ScaledFontModifier(
            size: style.scaledBaseSize,
            weight: weight ?? style.impliedWeight,
            design: design,
            monospacedDigit: monospacedDigit
        ))
    }
}

import SwiftUI

// Picker destinations for the Settings → Preferences card. Each writes to a
// `@AppStorage("prefs.*")` key and shows a live preview of the chosen value.
//
// Plumbing status:
//   • PreferredLanguagePickerView writes `appLanguage`, which `SHJSDSCApp`
//     already consumes to drive `.environment(\.locale, …)` and the
//     RTL/LTR layout direction. Selecting a language re-skins the app.
//   • DateFormatPickerView / TimeFormatPickerView / NumberFormatPickerView
//     persist the user's choice but the rest of the app does not yet read
//     from these keys. The pickers are honest about that via a small
//     "saved-but-not-yet-applied" footer.
//   • DashboardPreferencesView toggles cosmetic flags for a future dashboard
//     customization surface.
//
// All five views share the same visual shell: SectionCard with a list of
// option rows + an explanatory footer. Rows show a label, a preview, and a
// checkmark on the selected entry.

// MARK: - Generic picker row

private struct PickerOptionRow: View {
    let title: String
    let preview: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: title)
                        .scaledFont(.subheadline, weight: .semibold)
                        .foregroundStyle(.primary)
                    if let preview {
                        Text(verbatim: preview)
                            .scaledFont(.caption, monospacedDigit: true)
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .scaledFont(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.4))
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PickerShell<Content: View>: View {
    let titleKey: LocalizedStringKey
    let icon: String
    let footnoteKey: LocalizedStringKey?
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                SectionCard(titleKey, icon: icon) {
                    content()
                }
                if let footnoteKey {
                    Text(footnoteKey)
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(Text(titleKey))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Date Format

public struct DateFormatPickerView: View {
    @AppStorage("prefs.dateFormat") private var pref: String = "DD MMM YYYY"

    public init() {}

    public var body: some View {
        PickerShell(
            titleKey: "profile.date_format",
            icon: "calendar",
            footnoteKey: "prefs.format.footnote"
        ) {
            VStack(spacing: 0) {
                ForEach(Self.options, id: \.value) { opt in
                    PickerOptionRow(
                        title: opt.value,
                        preview: format(opt.formatString),
                        isSelected: pref == opt.value
                    ) { pref = opt.value }
                    if opt.value != Self.options.last?.value {
                        Divider().opacity(0.32)
                    }
                }
            }
        }
    }

    private func format(_ template: String) -> String {
        let f = DateFormatter()
        f.dateFormat = template
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }

    private static let options: [(value: String, formatString: String)] = [
        ("DD MMM YYYY",  "dd MMM yyyy"),
        ("MMM DD, YYYY", "MMM dd, yyyy"),
        ("DD/MM/YYYY",   "dd/MM/yyyy"),
        ("MM/DD/YYYY",   "MM/dd/yyyy"),
        ("YYYY-MM-DD",   "yyyy-MM-dd")
    ]
}

// MARK: - Time Format

public struct TimeFormatPickerView: View {
    @AppStorage("prefs.timeFormat") private var pref: String = "24h"

    public init() {}

    public var body: some View {
        PickerShell(
            titleKey: "profile.time_format",
            icon: "clock",
            footnoteKey: "prefs.format.footnote"
        ) {
            VStack(spacing: 0) {
                PickerOptionRow(
                    title: "12-hour",
                    preview: preview(format: "h:mm a"),
                    isSelected: pref == "12h"
                ) { pref = "12h" }
                Divider().opacity(0.32)
                PickerOptionRow(
                    title: "24-hour",
                    preview: preview(format: "HH:mm"),
                    isSelected: pref == "24h"
                ) { pref = "24h" }
            }
        }
    }

    private func preview(format: String) -> String {
        let f = DateFormatter()
        f.dateFormat = format
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }
}

// MARK: - Number Format

public struct NumberFormatPickerView: View {
    @AppStorage("prefs.numberFormat") private var pref: String = "1,234.56"

    public init() {}

    public var body: some View {
        PickerShell(
            titleKey: "profile.number_format",
            icon: "number",
            footnoteKey: "prefs.format.footnote"
        ) {
            VStack(spacing: 0) {
                ForEach(Self.options, id: \.value) { opt in
                    PickerOptionRow(
                        title: opt.value,
                        preview: format(decimal: opt.decimal, group: opt.group),
                        isSelected: pref == opt.value
                    ) { pref = opt.value }
                    if opt.value != Self.options.last?.value {
                        Divider().opacity(0.32)
                    }
                }
            }
        }
    }

    private func format(decimal: String, group: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        f.decimalSeparator = decimal
        f.groupingSeparator = group
        f.usesGroupingSeparator = !group.isEmpty
        return f.string(from: 1234.56) ?? "1234.56"
    }

    private static let options: [(value: String, decimal: String, group: String)] = [
        ("1,234.56", ".", ","),
        ("1.234,56", ",", "."),
        ("1 234,56", ",", " "),
        ("1234.56",  ".", "")
    ]
}

// MARK: - Preferred Language

public struct PreferredLanguagePickerView: View {
    @AppStorage("appLanguage") private var pref: String = "en"

    public init() {}

    public var body: some View {
        PickerShell(
            titleKey: "profile.preferred_language",
            icon: "globe",
            footnoteKey: "prefs.language.footnote"
        ) {
            VStack(spacing: 0) {
                ForEach(Self.options, id: \.value) { opt in
                    PickerOptionRow(
                        title: NSLocalizedString(opt.labelKey, comment: ""),
                        preview: opt.preview,
                        isSelected: pref == opt.value
                    ) { pref = opt.value }
                    if opt.value != Self.options.last?.value {
                        Divider().opacity(0.32)
                    }
                }
            }
        }
    }

    private static let options: [(value: String, labelKey: String, preview: String?)] = [
        ("en", "language.english", "Hello"),
        ("ar", "language.arabic",  "مرحباً"),
        ("fr", "language.french",  "Bonjour")
    ]
}

// MARK: - Dashboard Preferences

public struct DashboardPreferencesView: View {
    @AppStorage("prefs.dashboard.showStats")        private var showStats: Bool = true
    @AppStorage("prefs.dashboard.showSchedule")     private var showSchedule: Bool = true
    @AppStorage("prefs.dashboard.showAnnouncements") private var showAnnouncements: Bool = true
    @AppStorage("prefs.dashboard.showActivity")     private var showActivity: Bool = true

    public init() {}

    public var body: some View {
        PickerShell(
            titleKey: "profile.prefs.dashboard",
            icon: "rectangle.3.group.fill",
            footnoteKey: "prefs.dashboard.footnote"
        ) {
            VStack(spacing: 0) {
                DashboardToggleRow(
                    icon: "chart.bar.xaxis",
                    label: "prefs.dashboard.row.stats",
                    subtitle: "prefs.dashboard.row.stats.subtitle",
                    isOn: $showStats
                )
                Divider().opacity(0.32)
                DashboardToggleRow(
                    icon: "calendar",
                    label: "prefs.dashboard.row.schedule",
                    subtitle: "prefs.dashboard.row.schedule.subtitle",
                    isOn: $showSchedule
                )
                Divider().opacity(0.32)
                DashboardToggleRow(
                    icon: "megaphone.fill",
                    label: "prefs.dashboard.row.announcements",
                    subtitle: "prefs.dashboard.row.announcements.subtitle",
                    isOn: $showAnnouncements
                )
                Divider().opacity(0.32)
                DashboardToggleRow(
                    icon: "list.bullet.rectangle",
                    label: "prefs.dashboard.row.activity",
                    subtitle: "prefs.dashboard.row.activity.subtitle",
                    isOn: $showActivity
                )
            }
        }
    }
}

private struct DashboardToggleRow: View {
    let icon: String
    let label: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.accentColor.opacity(0.14))
                Image(systemName: icon)
                    .scaledFont(.footnote, weight: .semibold)
                    .foregroundStyle(.tint)
            }
            .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).scaledFont(.subheadline, weight: .semibold)
                Text(subtitle).scaledFont(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.secondaryAccent)
        }
        .padding(.vertical, 11)
    }
}

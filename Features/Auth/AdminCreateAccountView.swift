import SwiftUI

/// Premium "Create account" experience — a federation-grade onboarding
/// surface that replaces the old grouped `Form`. Renders inside the role
/// shell's detail pane.
///
/// Layout: custom header → onboarding hero → adaptive two-column form
/// (Account details + Contact on the left; Role + Preferences on the right)
/// → security & compliance panel. Collapses to a single column on iPhone.
///
/// Persistence note: `Repository.createAccount` accepts name, email,
/// password, role, and branch — those are wired. The richer fields (phone,
/// alternative email, access level, preferences) are collected in the form
/// for the operator's review; persisting them is a backend follow-up.
public struct AdminCreateAccountView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSize

    // Account details
    @State private var fullName = ""
    @State private var fullNameAr = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var revealPassword = false
    @State private var revealConfirm = false

    // Contact
    @State private var phone = ""
    @State private var countryCode = CountryDial.uae
    @State private var altEmail = ""

    // Role assignment
    @State private var selectedRole: Role = .coach
    @State private var accessLevel: ProvisionAccessLevel = .standard
    @State private var selectedBranchID: EntityID?

    // Preferences
    @State private var preferredLanguage = "en"
    @State private var timeZone = "uae"
    @State private var sendWelcomeEmail = true
    @State private var requirePasswordReset = true

    // Status
    @State private var error: String?
    @State private var success: String?
    @State private var saving = false
    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case name, nameAr, email, password, confirm, phone, altEmail
    }

    private let creatableRoles: [Role] = Role.allCases.filter { $0 != .developer }

    public init(initialRole: Role = .coach) {
        _selectedRole = State(initialValue: initialRole)
    }

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                CreateAccountHeader(
                    saving: saving,
                    canCreate: isValid,
                    onCancel: { dismiss() },
                    onCreate: { Task { await handleCreate() } }
                )
                HeroOnboardingCard(isWide: isWide)
                statusBanner
                mainGrid
                SecurityComplianceCard(isWide: isWide)
            }
            .padding(.horizontal, isWide ? 28 : 16)
            .padding(.top, 16)
            .padding(.bottom, 36)
            .frame(maxWidth: 1180)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    // MARK: - Status

    @ViewBuilder
    private var statusBanner: some View {
        if let error {
            banner(text: error, icon: "exclamationmark.triangle.fill", tint: .red)
        } else if let success {
            banner(text: success, icon: "checkmark.seal.fill", tint: .secondaryAccent)
        }
    }

    private func banner(text: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).scaledFont(.subheadline, weight: .semibold)
            Text(verbatim: text).scaledFont(.subheadline, weight: .medium)
            Spacer(minLength: 0)
        }
        .foregroundStyle(tint)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Main grid

    @ViewBuilder
    private var mainGrid: some View {
        if isWide {
            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: 20) {
                    accountDetailsCard
                    contactCard
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 20) {
                    roleCard
                    preferencesCard
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: 20) {
                accountDetailsCard
                contactCard
                roleCard
                preferencesCard
            }
        }
    }

    // MARK: - Account details

    private var accountDetailsCard: some View {
        FormCard(title: "admin.account_details", icon: "person.text.rectangle.fill") {
            VStack(spacing: 14) {
                ModernInputField(
                    label: "auth.full_name", icon: "person.fill",
                    placeholder: "cacct.placeholder.name_en", text: $fullName,
                    isFocused: focus == .name
                )
                .focused($focus, equals: .name)

                ModernInputField(
                    label: "auth.full_name_ar", icon: "character.textbox",
                    placeholder: "cacct.placeholder.name_ar", text: $fullNameAr,
                    isFocused: focus == .nameAr
                )
                .focused($focus, equals: .nameAr)
                .environment(\.layoutDirection, .rightToLeft)

                ModernInputField(
                    label: "auth.email", icon: "envelope.fill",
                    placeholder: "cacct.placeholder.email", text: $email,
                    isFocused: focus == .email, kind: .email
                )
                .focused($focus, equals: .email)

                ModernSecureField(
                    label: "auth.password", placeholder: "cacct.placeholder.password",
                    text: $password, reveal: $revealPassword, isFocused: focus == .password
                )
                .focused($focus, equals: .password)

                if !password.isEmpty {
                    PasswordStrengthView(password: password)
                }

                ModernSecureField(
                    label: "cacct.field.confirm_password", placeholder: "cacct.placeholder.confirm",
                    text: $confirmPassword, reveal: $revealConfirm, isFocused: focus == .confirm,
                    mismatch: !confirmPassword.isEmpty && confirmPassword != password
                )
                .focused($focus, equals: .confirm)
            }
        }
    }

    // MARK: - Contact

    private var contactCard: some View {
        FormCard(title: "cacct.section.contact", icon: "phone.bubble.fill") {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("cacct.field.phone")
                        .scaledFont(.caption, weight: .semibold)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        CountryCodeMenu(selected: $countryCode)
                        FieldShell(isFocused: focus == .phone) {
                            TextField(text: $phone) { Text("cacct.placeholder.phone") }
                                .textFieldStyle(.plain)
                                #if os(iOS)
                                .keyboardType(.phonePad)
                                #endif
                                .focused($focus, equals: .phone)
                        }
                    }
                }
                ModernInputField(
                    label: "cacct.field.alt_email", icon: "envelope.badge.fill",
                    placeholder: "cacct.placeholder.optional", text: $altEmail,
                    isFocused: focus == .altEmail, kind: .email
                )
                .focused($focus, equals: .altEmail)
            }
        }
    }

    // MARK: - Role assignment

    private var roleCard: some View {
        FormCard(title: "admin.role_assignment", icon: "person.badge.shield.checkmark.fill") {
            VStack(spacing: 14) {
                ModernPickerField(label: "admin.role", icon: "briefcase.fill") {
                    ForEach(creatableRoles, id: \.self) { role in
                        Button { selectedRole = role } label: { Text(localizedKey: role.label) }
                    }
                } valueLabel: {
                    Text(localizedKey: selectedRole.label)
                }

                ModernPickerField(label: "cacct.field.access_level", icon: "lock.shield.fill") {
                    ForEach(ProvisionAccessLevel.allCases, id: \.self) { level in
                        Button { accessLevel = level } label: { Text(level.labelKey) }
                    }
                } valueLabel: {
                    Text(accessLevel.labelKey)
                }

                ModernPickerField(label: "admin.branch", icon: "building.2.fill") {
                    Button { selectedBranchID = nil } label: { Text("admin.no_branch") }
                    ForEach(session.branches) { branch in
                        Button { selectedBranchID = branch.id } label: { Text(verbatim: branch.name) }
                    }
                } valueLabel: {
                    if let id = selectedBranchID, let branch = session.branches.first(where: { $0.id == id }) {
                        Text(verbatim: branch.name)
                    } else {
                        Text("admin.no_branch").foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Preferences

    private var preferencesCard: some View {
        FormCard(title: "cacct.section.preferences", icon: "slider.horizontal.3") {
            VStack(spacing: 14) {
                ModernPickerField(label: "cacct.field.preferred_language", icon: "globe") {
                    Button { preferredLanguage = "en" } label: { Text("language.english") }
                    Button { preferredLanguage = "ar" } label: { Text("language.arabic") }
                    Button { preferredLanguage = "fr" } label: { Text("language.french") }
                } valueLabel: {
                    Text(languageLabel)
                }

                ModernPickerField(label: "cacct.field.time_zone", icon: "clock.fill") {
                    Button { timeZone = "uae" } label: { Text("cacct.tz.uae") }
                    Button { timeZone = "ksa" } label: { Text("cacct.tz.ksa") }
                    Button { timeZone = "egypt" } label: { Text("cacct.tz.egypt") }
                } valueLabel: {
                    Text(timeZoneLabel)
                }

                ModernToggleRow(
                    icon: "paperplane.fill", tint: .accentColor,
                    title: "cacct.toggle.welcome_email",
                    subtitle: "cacct.toggle.welcome_email.sub",
                    isOn: $sendWelcomeEmail
                )
                ModernToggleRow(
                    icon: "key.horizontal.fill", tint: .secondaryAccent,
                    title: "cacct.toggle.password_reset",
                    subtitle: "cacct.toggle.password_reset.sub",
                    isOn: $requirePasswordReset
                )
            }
        }
    }

    private var languageLabel: LocalizedStringKey {
        switch preferredLanguage {
        case "ar": "language.arabic"
        case "fr": "language.french"
        default: "language.english"
        }
    }

    private var timeZoneLabel: LocalizedStringKey {
        switch timeZone {
        case "ksa": "cacct.tz.ksa"
        case "egypt": "cacct.tz.egypt"
        default: "cacct.tz.uae"
        }
    }

    // MARK: - Logic

    private var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty
            && email.contains("@") && email.contains(".")
            && password.count >= 8
            && password == confirmPassword
    }

    private func handleCreate() async {
        saving = true
        defer { saving = false }
        withAnimation { error = nil; success = nil }
        do {
            try await session.repository.createAccount(
                email: email,
                password: password,
                fullName: fullName,
                fullNameAr: fullNameAr.isEmpty ? fullName : fullNameAr,
                role: selectedRole,
                branchID: selectedBranchID
            )
            withAnimation {
                success = String(localized: "admin.account_created") + " \(email)"
            }
            fullName = ""; fullNameAr = ""; email = ""
            password = ""; confirmPassword = ""
            phone = ""; altEmail = ""
        } catch {
            withAnimation { self.error = error.localizedDescription }
        }
    }
}

// MARK: - Access level

private enum ProvisionAccessLevel: String, CaseIterable {
    case standard, elevated, full

    var labelKey: LocalizedStringKey {
        switch self {
        case .standard: "cacct.access.standard"
        case .elevated: "cacct.access.elevated"
        case .full:     "cacct.access.full"
        }
    }
}

// MARK: - Country dial code

private struct CountryDial: Hashable {
    let flag: String
    let code: String

    static let uae = CountryDial(flag: "🇦🇪", code: "+971")
    static let all: [CountryDial] = [
        uae,
        CountryDial(flag: "🇸🇦", code: "+966"),
        CountryDial(flag: "🇶🇦", code: "+974"),
        CountryDial(flag: "🇪🇬", code: "+20"),
        CountryDial(flag: "🇬🇧", code: "+44"),
        CountryDial(flag: "🇺🇸", code: "+1"),
    ]
}

// MARK: - Header

private struct CreateAccountHeader: View {
    let saving: Bool
    let canCreate: Bool
    let onCancel: () -> Void
    let onCreate: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("admin.create_account")
                    .scaledFont(.title2, weight: .bold)
                Text("cacct.header.subtitle")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button(action: onCancel) {
                Text("action.cancel")
                    .scaledFont(.subheadline, weight: .semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Color.cardBackground, in: Capsule())
                    .overlay(Capsule().stroke(Color.secondary.opacity(0.18), lineWidth: 1))
            }
            .buttonStyle(.plain)

            PrimaryGradientButton(
                title: "admin.create",
                icon: "person.crop.circle.badge.checkmark",
                loading: saving,
                enabled: canCreate,
                action: onCreate
            )
        }
    }
}

// MARK: - Hero

private struct HeroOnboardingCard: View {
    let isWide: Bool

    var body: some View {
        Group {
            if isWide {
                HStack(alignment: .center, spacing: 24) {
                    heroText.frame(maxWidth: .infinity, alignment: .leading)
                    HeroIllustration()
                        .frame(width: 260, height: 200)
                }
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    HeroIllustration()
                        .frame(height: 170)
                        .frame(maxWidth: .infinity)
                    heroText
                }
            }
        }
        .padding(isWide ? 26 : 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.14),
                            Color.secondaryAccent.opacity(0.08),
                            Color.cardBackground,
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 18, y: 8)
    }

    private var heroText: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("cacct.hero.title")
                    .scaledFont(.title, weight: .bold)
                Text("cacct.hero.subtitle")
                    .scaledFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            featureRow
        }
    }

    private var featureRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) { featureChips }
            VStack(spacing: 10) { featureChips }
        }
    }

    @ViewBuilder
    private var featureChips: some View {
        HeroFeatureChip(icon: "lock.shield.fill", tint: .accentColor,
                        title: "cacct.feature.secure.title",
                        subtitle: "cacct.feature.secure.subtitle")
        HeroFeatureChip(icon: "slider.horizontal.3", tint: .secondaryAccent,
                        title: "cacct.feature.flexible.title",
                        subtitle: "cacct.feature.flexible.subtitle")
        HeroFeatureChip(icon: "sparkles", tint: .orange,
                        title: "cacct.feature.easy.title",
                        subtitle: "cacct.feature.easy.subtitle")
    }
}

private struct HeroFeatureChip: View {
    let icon: String
    let tint: Color
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).scaledFont(.footnote, weight: .semibold)
                Text(subtitle)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }
}

/// Abstract user-creation illustration, drawn entirely from SF Symbols and
/// gradient shapes — soft floating circles, a hero person glyph, and small
/// security marks. No stock art.
private struct HeroIllustration: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.16))
                .frame(width: 150, height: 150)
                .blur(radius: 4)
                .offset(x: 30, y: -18)
            Circle()
                .fill(Color.secondaryAccent.opacity(0.18))
                .frame(width: 88, height: 88)
                .blur(radius: 3)
                .offset(x: -56, y: 44)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.78)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: Color.accentColor.opacity(0.35), radius: 16, y: 10)
                .overlay(
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 56, weight: .regular))
                        .foregroundStyle(.white)
                )
                .rotationEffect(.degrees(-6))

            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color.secondaryAccent)
                .padding(8)
                .background(Color.cardBackground, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .offset(x: 64, y: 52)

            Image(systemName: "key.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .padding(7)
                .background(Color.cardBackground, in: Circle())
                .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
                .offset(x: -64, y: -44)
        }
    }
}

// MARK: - Form card shell

private struct FormCard<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .scaledFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30, height: 30)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(title).scaledFont(.headline)
                Spacer(minLength: 0)
            }
            Divider().opacity(0.5)
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }
}

// MARK: - Field shell (focus ring)

private struct FieldShell<Content: View>: View {
    var isFocused: Bool = false
    var mismatch: Bool = false
    @ViewBuilder var content: Content

    private var ringColor: Color {
        if mismatch { return .red }
        return isFocused ? Color.accentColor : Color.secondary.opacity(0.16)
    }

    var body: some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(ringColor, lineWidth: isFocused || mismatch ? 1.6 : 1)
            )
            .animation(.easeInOut(duration: 0.18), value: isFocused)
            .animation(.easeInOut(duration: 0.18), value: mismatch)
    }
}

// MARK: - Modern input field

private struct ModernInputField: View {
    enum Kind { case plain, email }

    let label: LocalizedStringKey
    let icon: String
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var isFocused: Bool = false
    var kind: Kind = .plain

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
            FieldShell(isFocused: isFocused) {
                HStack(spacing: 9) {
                    Image(systemName: icon)
                        .scaledFont(.footnote, weight: .medium)
                        .foregroundStyle(isFocused ? Color.accentColor : .secondary)
                        .frame(width: 18)
                    TextField(text: $text) { Text(placeholder) }
                        .textFieldStyle(.plain)
                        #if os(iOS)
                        .textInputAutocapitalization(kind == .email ? .never : .words)
                        .keyboardType(kind == .email ? .emailAddress : .default)
                        .autocorrectionDisabled(kind == .email)
                        #endif
                }
            }
        }
    }
}

// MARK: - Secure field with reveal

private struct ModernSecureField: View {
    let label: LocalizedStringKey
    let placeholder: LocalizedStringKey
    @Binding var text: String
    @Binding var reveal: Bool
    var isFocused: Bool = false
    var mismatch: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
            FieldShell(isFocused: isFocused, mismatch: mismatch) {
                HStack(spacing: 9) {
                    Image(systemName: "lock.fill")
                        .scaledFont(.footnote, weight: .medium)
                        .foregroundStyle(isFocused ? Color.accentColor : .secondary)
                        .frame(width: 18)
                    Group {
                        if reveal {
                            TextField(text: $text) { Text(placeholder) }
                        } else {
                            SecureField(text: $text) { Text(placeholder) }
                        }
                    }
                    .textFieldStyle(.plain)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif
                    Button {
                        reveal.toggle()
                    } label: {
                        Image(systemName: reveal ? "eye.slash.fill" : "eye.fill")
                            .scaledFont(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Password strength

private struct PasswordStrengthView: View {
    let password: String

    private var score: Int {
        var s = 0
        if password.count >= 8 { s += 1 }
        if password.contains(where: \.isUppercase) && password.contains(where: \.isLowercase) { s += 1 }
        let hasDigit = password.contains(where: \.isNumber)
        let hasSymbol = password.contains { !$0.isLetter && !$0.isNumber }
        if hasDigit || hasSymbol { s += 1 }
        return min(s, 3)
    }

    private var tint: Color {
        switch score {
        case 3:  .secondaryAccent
        case 2:  .orange
        default: .red
        }
    }

    private var labelKey: LocalizedStringKey {
        switch score {
        case 3:  "cacct.strength.strong"
        case 2:  "cacct.strength.fair"
        default: "cacct.strength.weak"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(i < score ? tint : Color.secondary.opacity(0.18))
                        .frame(height: 5)
                }
            }
            Text(labelKey)
                .scaledFont(.caption2, weight: .semibold)
                .foregroundStyle(tint)
        }
        .animation(.easeInOut(duration: 0.2), value: score)
    }
}

// MARK: - Picker field

private struct ModernPickerField<MenuContent: View, Value: View>: View {
    let label: LocalizedStringKey
    let icon: String
    @ViewBuilder var menu: MenuContent
    @ViewBuilder var valueLabel: Value

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
            Menu {
                menu
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: icon)
                        .scaledFont(.footnote, weight: .medium)
                        .foregroundStyle(.secondary)
                        .frame(width: 18)
                    valueLabel
                        .scaledFont(.subheadline, weight: .medium)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.up.chevron.down")
                        .scaledFont(.caption2, weight: .semibold)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
                )
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
        }
    }
}

// MARK: - Country code menu

private struct CountryCodeMenu: View {
    @Binding var selected: CountryDial

    var body: some View {
        Menu {
            ForEach(CountryDial.all, id: \.self) { dial in
                Button {
                    selected = dial
                } label: {
                    Text(verbatim: "\(dial.flag)  \(dial.code)")
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(verbatim: selected.flag).scaledFont(.subheadline)
                Text(verbatim: selected.code)
                    .scaledFont(.subheadline, weight: .semibold)
                    .environment(\.layoutDirection, .leftToRight)
                Image(systemName: "chevron.down")
                    .scaledFont(.caption2, weight: .semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
            )
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

// MARK: - Toggle row

private struct ModernToggleRow: View {
    let icon: String
    let tint: Color
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .scaledFont(.footnote, weight: .semibold)
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).scaledFont(.subheadline, weight: .semibold)
                Text(subtitle)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.accentColor)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Security & compliance

private struct SecurityComplianceCard: View {
    let isWide: Bool

    var body: some View {
        Group {
            if isWide {
                HStack(alignment: .top, spacing: 20) {
                    beforeYouCreate.frame(maxWidth: .infinity, alignment: .leading)
                    Divider().frame(height: 96)
                    secureCompliant.frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(alignment: .leading, spacing: 18) {
                    beforeYouCreate
                    Divider()
                    secureCompliant
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }

    private var beforeYouCreate: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checklist")
                .scaledFont(.title3, weight: .semibold)
                .foregroundStyle(Color.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text("cacct.before.title").scaledFont(.headline)
                Text("cacct.before.body")
                    .scaledFont(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var secureCompliant: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.secondaryAccent, Color.secondaryAccent.opacity(0.75)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: Color.secondaryAccent.opacity(0.35), radius: 8, y: 4)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("cacct.compliant.title").scaledFont(.headline)
                Text("cacct.compliant.body")
                    .scaledFont(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Primary gradient button

private struct PrimaryGradientButton: View {
    let title: LocalizedStringKey
    let icon: String
    var loading: Bool = false
    var enabled: Bool = true
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if loading {
                    ProgressView().controlSize(.small).tint(.white)
                } else {
                    Image(systemName: icon).scaledFont(.footnote, weight: .semibold)
                }
                Text(title).scaledFont(.subheadline, weight: .semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.82)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            )
            .shadow(color: Color.accentColor.opacity(enabled ? 0.35 : 0), radius: 10, y: 5)
            .opacity(enabled ? 1 : 0.5)
            .scaleEffect(pressed ? 0.96 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!enabled || loading)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressed = $0 }, perform: {})
    }
}

import SwiftUI

public struct AddBranchView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let onCreated: (Branch) -> Void

    @State private var code: String = ""
    @State private var name: String = ""
    @State private var nameAr: String = ""
    @State private var area: String = "Sharjah"
    @State private var capacity: Int = 60
    @State private var focus: String = "fundamentals"
    @State private var streetAddress: String = ""
    @State private var streetAddressAr: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var taglineEn: String = ""
    @State private var taglineAr: String = ""
    @State private var brandHex: String = ""
    @State private var foundedAt: Date = Date()
    @State private var latitude: Double = 0
    @State private var longitude: Double = 0

    @State private var saving = false
    @State private var error: String?
    @State private var showErrorAlert = false

    public init(onCreated: @escaping (Branch) -> Void) {
        self.onCreated = onCreated
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                identityCard
                addressCard
                contactCard
                brandingCard
                Color.clear.frame(height: 16)
            }
            .padding(.horizontal, 16).padding(.top, 8)
        }
        .background(Color.appBackground)
        .subviewChrome(Text("branch.add")) {
            Button {
                Task { await save() }
            } label: {
                if saving { ProgressView() } else { Text("action.save") }
            }
            .disabled(saving || !isValid)
        }
        .alert("branch.save_error", isPresented: $showErrorAlert) {
            Button("action.ok", role: .cancel) {}
        } message: {
            Text(verbatim: error ?? "")
        }
    }

    private var identityCard: some View {
        sectionCard(icon: "info.circle.fill", title: "branch.tab.identity") {
            FieldRow {
                InlineField(label: "branch.code") {
                    plainTextField($code, placeholder: "BR-X")
                        .environment(\.layoutDirection, .leftToRight)
                }
                InlineField(label: "branch.area") {
                    plainTextField($area, placeholder: "branch.area")
                }
            }
            FieldRow {
                InlineField(label: "auth.full_name") {
                    plainTextField($name, placeholder: "auth.full_name")
                }
                InlineField(label: "auth.full_name_ar") {
                    arabicTextField($nameAr, placeholder: "auth.full_name_ar")
                }
            }
            FieldRow {
                InlineField(label: "branch.focus") {
                    plainTextField($focus, placeholder: "branch.focus")
                }
                InlineField(label: "branch.capacity") {
                    CompactStepper(value: $capacity, range: 0...500, step: 5)
                }
            }
            InlineField(label: "branch.founded") {
                DropdownDatePicker(date: $foundedAt, minYear: 1990, maxYear: currentYear)
            }
        }
    }

    private var addressCard: some View {
        sectionCard(icon: "mappin.and.ellipse", title: "branch.address") {
            InlineField(label: "branch.address") {
                plainTextField($streetAddress, placeholder: "branch.address")
            }
            InlineField(label: "branch.address_ar") {
                arabicTextField($streetAddressAr, placeholder: "branch.address_ar")
            }
            BranchLocationField(latitude: $latitude, longitude: $longitude)
                .padding(.top, 4)
        }
    }

    private var contactCard: some View {
        sectionCard(icon: "phone.fill", title: "branch.connect") {
            FieldRow {
                InlineField(label: "branch.phone") {
                    plainTextField($phone, placeholder: "+971 6 555 0000")
                        .environment(\.layoutDirection, .leftToRight)
                }
                InlineField(label: "branch.email") {
                    plainTextField($email, placeholder: "branch@ssdsc.ae")
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
        }
    }

    private var brandingCard: some View {
        sectionCard(icon: "paintbrush.fill", title: "branch.branding") {
            InlineField(label: "branch.tagline_en") {
                plainTextField($taglineEn, placeholder: "branch.tagline_en")
            }
            InlineField(label: "branch.tagline_ar") {
                arabicTextField($taglineAr, placeholder: "branch.tagline_ar")
            }
            InlineField(label: "branch.brand_color", footer: "branch.brand_color_hint") {
                plainTextField($brandHex, placeholder: "#E24B4A")
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
    }

    // MARK: - Helpers

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    private var isValid: Bool {
        !code.trimmingCharacters(in: .whitespaces).isEmpty
        && !name.trimmingCharacters(in: .whitespaces).isEmpty
        && !nameAr.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func plainTextField(_ binding: Binding<String>, placeholder: LocalizedStringKey) -> some View {
        TextField(placeholder, text: binding).textFieldStyle(.plain).scaledFont(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func arabicTextField(_ binding: Binding<String>, placeholder: LocalizedStringKey) -> some View {
        TextField(placeholder, text: binding).textFieldStyle(.plain).scaledFont(.callout)
            .multilineTextAlignment(.trailing)
            .environment(\.layoutDirection, .rightToLeft)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func save() async {
        saving = true
        defer { saving = false }
        let branch = Branch(
            code: code.trimmingCharacters(in: .whitespaces),
            name: name.trimmingCharacters(in: .whitespaces),
            nameAr: nameAr.trimmingCharacters(in: .whitespaces),
            area: area.trimmingCharacters(in: .whitespaces),
            capacity: capacity,
            focus: focus.trimmingCharacters(in: .whitespaces),
            streetAddress: streetAddress, streetAddressAr: streetAddressAr,
            latitude: latitude, longitude: longitude,
            phone: phone, email: email,
            foundedAt: foundedAt,
            brandHexColor: brandHex.isEmpty ? nil : brandHex,
            taglineEn: taglineEn.isEmpty ? nil : taglineEn,
            taglineAr: taglineAr.isEmpty ? nil : taglineAr
        )
        do {
            try await session.repository.upsert(branch)
            onCreated(branch)
            dismiss()
        } catch {
            self.error = String(describing: error)
            self.showErrorAlert = true
        }
    }

    // MARK: - Layout primitives

    private func sectionCard<Content: View>(
        icon: String, title: LocalizedStringKey,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .scaledFont(.caption, weight: .bold).foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 5))
                Text(title).scaledFont(.subheadline, weight: .bold)
                Spacer()
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) { content() }
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct InlineField<Content: View>: View {
    let label: LocalizedStringKey
    var footer: LocalizedStringKey?
    @ViewBuilder let content: Content

    init(label: LocalizedStringKey, footer: LocalizedStringKey? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).scaledFont(.caption2, weight: .semibold).foregroundStyle(.primary.opacity(0.55))
            content
            if let footer {
                Text(footer).scaledFont(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct FieldRow<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) { content }
    }
}

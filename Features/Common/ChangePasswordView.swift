import SwiftUI

/// Change Password screen. Works against any `AuthenticatingRepository`
/// (the live cloud backend); on demo data — which has no real account
/// system — it shows an honest note instead of a non-functional form.
public struct ChangePasswordView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var saving = false
    @State private var errorText: String?
    @State private var didSucceed = false

    public init() {}

    private var auth: (any AuthenticatingRepository)? {
        session.repository as? AuthenticatingRepository
    }

    private let minLength = 8

    private var validationError: LocalizedStringKey? {
        if newPassword.count < minLength { return "password.error.too_short" }
        if newPassword != confirmPassword { return "password.error.mismatch" }
        return nil
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if auth == nil {
                    unavailableCard
                } else if didSucceed {
                    successCard
                } else {
                    formCard
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.appBackground)
        .subviewChrome(Text("profile.security.password"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("password.new_title").scaledFont(.headline)
            SecureField(text: $newPassword) { Text("password.new_field") }
                .textFieldStyle(.roundedBorder)
            SecureField(text: $confirmPassword) { Text("password.confirm_field") }
                .textFieldStyle(.roundedBorder)
            Text("password.requirement")
                .scaledFont(.caption)
                .foregroundStyle(.secondary)
            if let errorText {
                Text(verbatim: errorText)
                    .scaledFont(.caption)
                    .foregroundStyle(.red)
            }
            Button {
                Task { await save() }
            } label: {
                HStack(spacing: 8) {
                    if saving { ProgressView().controlSize(.small) }
                    Text(saving ? "password.saving" : "password.save")
                }
                .scaledFont(.subheadline, weight: .semibold)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(saving || validationError != nil)
            if let validationError, !newPassword.isEmpty || !confirmPassword.isEmpty {
                Text(validationError)
                    .scaledFont(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var successCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .scaledFont(.largeTitle)
                .foregroundStyle(.green)
            Text("password.success_title").scaledFont(.headline)
            Text("password.success_body")
                .scaledFont(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("action.done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var unavailableCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill").foregroundStyle(.tint)
                Text("password.unavailable_title").scaledFont(.headline)
            }
            Text("password.unavailable_body")
                .scaledFont(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func save() async {
        guard let auth, validationError == nil else { return }
        saving = true
        errorText = nil
        do {
            try await auth.changePassword(newPassword: newPassword)
            didSucceed = true
        } catch {
            errorText = error.localizedDescription
        }
        saving = false
    }
}

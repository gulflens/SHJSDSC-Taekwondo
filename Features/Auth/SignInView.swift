import SwiftUI
import AuthenticationServices

public struct SignInView: View {
    @Environment(AppSession.self) private var session

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var useEmail: Bool = false
    @State private var error: String?
    @State private var signing: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("auth.welcome").font(.title.bold())
            Text("auth.subtitle").font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 24)

            if useEmail {
                emailForm
            } else {
                appleButton
                Button {
                    useEmail = true
                } label: {
                    Text("auth.use_email")
                        .font(.callout)
                        .foregroundStyle(.tint)
                }
            }

            if let error {
                Text(verbatim: error).font(.caption).foregroundStyle(.red).padding(.horizontal)
            }

            Spacer()

            Button {
                Task { await session.signInDemoFallback() }
            } label: {
                Text("auth.use_demo_session")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 12)
        }
        .padding()
    }

    private var appleButton: some View {
        SignInWithAppleButton { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case .success(let authResults):
                Task { await handleAppleResult(authResults) }
            case .failure(let err):
                error = err.localizedDescription
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 48)
        .padding(.horizontal, 32)
    }

    private var emailForm: some View {
        VStack(spacing: 12) {
            TextField("auth.email", text: $email)
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                #endif
            SecureField("auth.password", text: $password)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button {
                    Task { await handleEmailSignIn() }
                } label: {
                    if signing {
                        HStack { ProgressView(); Text("auth.signing_in") }
                    } else {
                        Text("auth.sign_in")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(signing || email.isEmpty || password.isEmpty)
                Spacer()
                Button {
                    useEmail = false
                } label: {
                    Text("action.cancel")
                }
            }
        }
        .padding(.horizontal, 32)
    }

    private func handleAppleResult(_ result: ASAuthorization) async {
        guard let credential = result.credential as? ASAuthorizationAppleIDCredential else {
            error = "auth.invalid_credential"
            return
        }
        signing = true
        defer { signing = false }
        do {
            try await session.signInWithApple(credential: credential)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func handleEmailSignIn() async {
        signing = true
        defer { signing = false }
        do {
            try await session.signInWithEmail(email: email, password: password)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

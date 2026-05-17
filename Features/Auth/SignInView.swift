import SwiftUI

public struct SignInView: View {
    @Environment(AppSession.self) private var session

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var passwordVisible: Bool = false
    @State private var showParentSignUp = false
    @State private var error: String?
    @State private var signing: Bool = false

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: geo.size.height * 0.08)

                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(.tint.opacity(0.12))
                                .frame(width: 96, height: 96)
                            Image(systemName: "figure.taekwondo")
                                .scaledFont(size: 44, weight: .medium)
                                .foregroundStyle(.tint)
                        }

                        Text("auth.welcome")
                            .scaledFont(.title, weight: .bold)

                        Text("auth.subtitle")
                            .scaledFont(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 32)

                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "envelope")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                TextField("auth.email", text: $email)
                                    #if os(iOS)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    #endif
                            }
                            .padding(12)
                            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))

                            HStack(spacing: 10) {
                                Image(systemName: "lock")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                Group {
                                    if passwordVisible {
                                        TextField("auth.password", text: $password)
                                            #if os(iOS)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                            #endif
                                    } else {
                                        SecureField("auth.password", text: $password)
                                    }
                                }
                                Button {
                                    passwordVisible.toggle()
                                } label: {
                                    Image(systemName: passwordVisible ? "eye.slash" : "eye")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text(passwordVisible ? "auth.password.hide" : "auth.password.show"))
                            }
                            .padding(12)
                            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                        }

                        Button {
                            Task { await handleEmailSignIn() }
                        } label: {
                            Group {
                                if signing {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .tint(.white)
                                        Text("auth.signing_in")
                                    }
                                } else {
                                    Text("auth.sign_in")
                                }
                            }
                            .scaledFont(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 12))
                        .disabled(signing || email.isEmpty || password.isEmpty)

                        if let error {
                            Text(verbatim: error)
                                .scaledFont(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer(minLength: 40)

                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("auth.parent_prompt")
                                .scaledFont(.footnote)
                                .foregroundStyle(.secondary)
                            Button {
                                showParentSignUp = true
                            } label: {
                                Text("auth.parent_sign_up")
                                    .scaledFont(.callout, weight: .medium)
                            }
                        }

                        // Always-available one-tap developer login. The
                        // seeded developer account is hard-wired here so it
                        // never gets locked out behind a forgotten password.
                        Button {
                            Task { await session.signInAsDeveloper() }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "hammer.fill")
                                Text("auth.sign_in_developer")
                            }
                            .scaledFont(.callout, weight: .semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle(radius: 12))
                        .tint(.accentColor)

                        Button {
                            Task { await session.signInDemoFallback() }
                        } label: {
                            Text("auth.use_demo_session")
                                .scaledFont(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: 380)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .frame(minHeight: geo.size.height)
            }
        }
        .sheet(isPresented: $showParentSignUp) {
            ParentSignUpView()
        }
    }

    private func handleEmailSignIn() async {
        signing = true
        defer { signing = false }
        do {
            try await session.signInWithEmail(email: email, password: password, rememberMe: true)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

import SwiftUI

public struct SignInView: View {
    @Environment(AppSession.self) private var session

    @State private var email: String = ""
    @State private var password: String = ""
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
                                .font(.system(size: 44, weight: .medium))
                                .foregroundStyle(.tint)
                        }

                        Text("auth.welcome")
                            .font(.title.bold())

                        Text("auth.subtitle")
                            .font(.subheadline)
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
                                SecureField("auth.password", text: $password)
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
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 12))
                        .disabled(signing || email.isEmpty || password.isEmpty)

                        if let error {
                            Text(verbatim: error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer(minLength: 40)

                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("auth.parent_prompt")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Button {
                                showParentSignUp = true
                            } label: {
                                Text("auth.parent_sign_up")
                                    .font(.callout.weight(.medium))
                            }
                        }

                        Button {
                            Task { await session.signInDemoFallback() }
                        } label: {
                            Text("auth.use_demo_session")
                                .font(.caption)
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
            try await session.signInWithEmail(email: email, password: password)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

import SwiftUI

public struct ParentSignUpView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var fullNameAr = ""
    @State private var childMemberNumbers: [String] = [""]
    @State private var error: String?
    @State private var saving = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("auth.parent_info")) {
                    TextField("auth.full_name", text: $fullName)
                    TextField("auth.full_name_ar", text: $fullNameAr)
                    TextField("auth.email", text: $email)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        #endif
                    SecureField("auth.password", text: $password)
                    SecureField("auth.confirm_password", text: $confirmPassword)
                }

                Section(header: Text("auth.child_member_numbers"), footer: Text("auth.child_member_numbers_hint")) {
                    ForEach(childMemberNumbers.indices, id: \.self) { index in
                        HStack {
                            TextField("auth.member_number_placeholder", text: $childMemberNumbers[index])
                                #if os(iOS)
                                .keyboardType(.numberPad)
                                #endif
                            if childMemberNumbers.count > 1 {
                                Button(role: .destructive) {
                                    childMemberNumbers.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                }
                            }
                        }
                    }
                    Button {
                        childMemberNumbers.append("")
                    } label: {
                        Label("auth.add_child", systemImage: "plus.circle")
                    }
                }

                if let error {
                    Section {
                        Text(verbatim: error).foregroundStyle(.red).scaledFont(.caption)
                    }
                }
            }
            .navigationTitle("auth.parent_sign_up")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") { dismiss() }
                    .bareToolbarButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("auth.create_account") {
                        Task { await handleSignUp() }
                    }
                    .disabled(saving || !isValid)
                    .bareToolbarButton()
                }
            }
        }
    }

    private var isValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        !fullName.isEmpty &&
        !childMemberNumbers.filter({ !$0.isEmpty }).isEmpty
    }

    private func handleSignUp() async {
        saving = true
        defer { saving = false }
        error = nil

        let numbers = childMemberNumbers.compactMap { Int($0) }
        guard !numbers.isEmpty else {
            error = String(localized: "auth.error.invalid_member_number")
            return
        }

        for num in numbers where num < 1001 {
            error = String(localized: "auth.error.member_number_range")
            return
        }

        do {
            var athleteIDs: [EntityID] = []
            for num in numbers {
                guard let athlete = try await session.repository.athlete(memberNumber: num) else {
                    error = String(localized: "auth.error.member_not_found") + " \(num)"
                    return
                }
                athleteIDs.append(athlete.id)
            }

            try await session.repository.createAccount(
                email: email,
                password: password,
                fullName: fullName,
                fullNameAr: fullNameAr.isEmpty ? fullName : fullNameAr,
                role: .parent,
                branchID: nil
            )

            if let users = try? await session.repository.users(role: .parent) {
                if let parentUser = users.first(where: { $0.fullName == fullName }) {
                    for athleteID in athleteIDs {
                        try await session.repository.linkChild(userID: parentUser.id, athleteID: athleteID)
                    }
                }
            }

            try await session.signInWithEmail(email: email, password: password)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

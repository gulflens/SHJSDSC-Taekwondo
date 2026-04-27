import SwiftUI

public struct AdminCreateAccountView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var fullNameAr = ""
    @State private var selectedRole: Role = .coach
    @State private var selectedBranchID: EntityID?
    @State private var error: String?
    @State private var success: String?
    @State private var saving = false

    private let creatableRoles: [Role] = [.coach, .branchManager, .technicalDirector, .analyst, .parent]

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("admin.account_details")) {
                    TextField("auth.full_name", text: $fullName)
                    TextField("auth.full_name_ar", text: $fullNameAr)
                    TextField("auth.email", text: $email)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        #endif
                    SecureField("auth.password", text: $password)
                }

                Section(header: Text("admin.role_assignment")) {
                    Picker("admin.role", selection: $selectedRole) {
                        ForEach(creatableRoles, id: \.self) { role in
                            Text(role.label).tag(role)
                        }
                    }

                    if selectedRole == .coach || selectedRole == .branchManager {
                        Picker("admin.branch", selection: $selectedBranchID) {
                            Text("admin.no_branch").tag(nil as EntityID?)
                            ForEach(session.branches) { branch in
                                Text(branch.name).tag(branch.id as EntityID?)
                            }
                        }
                    }
                }

                if let error {
                    Section {
                        Text(verbatim: error).foregroundStyle(.red).font(.caption)
                    }
                }

                if let success {
                    Section {
                        Label(success, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("admin.create_account")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("admin.create") {
                        Task { await handleCreate() }
                    }
                    .disabled(saving || !isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6 && !fullName.isEmpty
    }

    private func handleCreate() async {
        saving = true
        defer { saving = false }
        error = nil
        success = nil

        do {
            try await session.repository.createAccount(
                email: email,
                password: password,
                fullName: fullName,
                fullNameAr: fullNameAr.isEmpty ? fullName : fullNameAr,
                role: selectedRole,
                branchID: selectedBranchID
            )
            success = String(localized: "admin.account_created") + " \(email)"
            email = ""
            password = ""
            fullName = ""
            fullNameAr = ""
        } catch {
            self.error = error.localizedDescription
        }
    }
}

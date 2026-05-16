import SwiftUI

public struct RoleClaimView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var fullNameAr: String = ""
    @State private var role: Role = .athlete
    @State private var branchID: EntityID?
    @State private var branches: [Branch] = []
    @State private var saving: Bool = false
    @State private var error: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("auth.role_claim_intro")) {
                    Text("auth.role_claim_help").scaledFont(.caption).foregroundStyle(.secondary)
                }
                Section(header: Text("auth.full_name")) {
                    TextField("auth.full_name", text: $fullName)
                    TextField("auth.full_name_ar", text: $fullNameAr)
                }
                Section(header: Text("settings.role")) {
                    Picker(selection: $role) {
                        ForEach(Role.allCases, id: \.self) { r in
                            Text(localizedKey: r.label).tag(r)
                        }
                    } label: {
                        Text("settings.role")
                    }
                }
                Section(header: Text("tab.branches")) {
                    Picker(selection: $branchID) {
                        Text("filter.all").tag(EntityID?.none)
                        ForEach(branches) { b in
                            Text(verbatim: b.name).tag(Optional(b.id))
                        }
                    } label: {
                        Text("tab.branches")
                    }
                }
                if let error {
                    Section { Text(verbatim: error).foregroundStyle(.red).scaledFont(.caption) }
                }
                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        if saving {
                            HStack { ProgressView(); Text("action.saving") }
                        } else {
                            Text("auth.submit_for_review")
                        }
                    }
                    .disabled(saving || fullName.isEmpty)
                }
            }
            .navigationTitle(Text("auth.role_claim_title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .task { branches = (try? await session.repository.branches()) ?? [] }
        }
    }

    private func submit() async {
        saving = true
        defer { saving = false }
        do {
            try await session.claimRole(
                fullName: fullName,
                fullNameAr: fullNameAr.isEmpty ? fullName : fullNameAr,
                role: role,
                branchID: branchID
            )
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

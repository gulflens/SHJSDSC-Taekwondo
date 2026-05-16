import SwiftUI

public struct RoleRouter: View {
    @Environment(AppSession.self) private var session

    public init() {}

    public var body: some View {
        Group {
            if !session.isAuthenticated {
                SignInView()
            } else if session.needsRoleClaim {
                RoleClaimView()
            } else {
                // Each role maps to one of the 8 base experiences. Roles in
                // the same group share an experience and are differentiated
                // by capabilities (Phase 2), not by bespoke screens.
                switch session.currentUser?.role {
                case .developer:
                    DeveloperTabView()
                case .admin, .itSupport, .operationsManager, .tournamentAdmin,
                     .competitionCoordinator, .registrar, .frontDesk, .finance, .hrManager:
                    AdminTabView()
                case .technicalDirector, .gradingExaminer:
                    TechnicalDirectorTabView()
                case .branchManager:
                    BranchManagerTabView()
                case .coach, .headCoach, .assistantCoach, .sparringCoach, .poomsaeCoach,
                     .conditioningCoach, .demoTeamCoach, .teamPhysician, .physiotherapist,
                     .sportsPsychologist, .nutritionist, .referee, .scorekeeper:
                    CoachTabView()
                case .analyst:
                    AnalystTabView()
                case .athlete, .alumni, .federationViewer, .sponsor:
                    AthleteTabView()
                case .parent:
                    ParentTabView()
                case nil:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}

public struct DemoRolePickerView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            List(session.availableUsers) { user in
                Button {
                    Task {
                        await session.switchTo(user)
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Avatar(seed: user.avatarSeed, label: initials(user.fullName))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: user.fullName)
                                .font(.body)
                            Text(localizedKey: user.role.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if session.currentUser?.id == user.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(Text("settings.role"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") { dismiss() }
                    .bareToolbarButton()
                }
            }
        }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }
}

public struct DemoRoleSwitcherModifier: ViewModifier {
    @State private var showing = false

    public init() {}

    public func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showing = true
                    } label: {
                        Image(systemName: "person.2.crop.square.stack")
                    }
                    .accessibilityLabel(Text("settings.role"))
                    .buttonStyle(.plain)
                    .bareToolbarButton()
                }
            }
            .sheet(isPresented: $showing) {
                DemoRolePickerView()
            }
    }
}

public extension View {
    func demoRoleSwitcher() -> some View {
        modifier(DemoRoleSwitcherModifier())
    }
}

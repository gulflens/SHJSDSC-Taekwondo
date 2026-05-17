import SwiftUI

/// More tab — Goals, Improvement Plan, Belt Progression, Family / Guardian,
/// Emergency Contacts, Audit log shortcut. Catches everything that doesn't
/// fit the seven primary tabs.
public struct AthleteMoreTab: View {
    @Binding public var athlete: Athlete
    public let parentUsers: [User]
    public let isWide: Bool

    public init(athlete: Binding<Athlete>, parentUsers: [User], isWide: Bool) {
        _athlete = athlete
        self.parentUsers = parentUsers
        self.isWide = isWide
    }

    public var body: some View {
        VStack(spacing: 14) {
            AthleteRoleSection(athlete: athlete)
            familyCard
            emergencyContactsCard
            SectionCard("more.belt_progression", icon: "circle.hexagongrid.fill") {
                BeltProgressionCard(athlete: $athlete)
            }
            SectionCard("more.goals", icon: "target") {
                GoalsCard(athleteID: athlete.id)
            }
            SectionCard("more.improvement_plan", icon: "checklist") {
                ImprovementPlanCard(athlete: athlete)
            }
        }
    }

    // MARK: - Family / Guardian

    private var familyCard: some View {
        SectionCard("more.family", icon: "person.2.fill") {
            if parentUsers.isEmpty {
                EmptyStateCard(
                    icon: "person.2.slash",
                    titleKey: "family.empty.title",
                    messageKey: "family.empty.message"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(parentUsers) { user in
                        familyRow(user)
                        if user.id != parentUsers.last?.id {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
    }

    private func familyRow(_ user: User) -> some View {
        HStack(spacing: 12) {
            Avatar(seed: user.avatarSeed, label: initials(user.fullName), size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: user.fullName)
                    .scaledFont(.subheadline, weight: .semibold)
                Text(verbatim: user.fullNameAr)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .rightToLeft)
            }
            Spacer(minLength: 0)
            CategoryBadge(
                value: NSLocalizedString("role.\(user.role.rawValue)", comment: ""),
                tone: .neutral,
                icon: "person.fill"
            )
        }
        .padding(.vertical, 4)
    }

    private var emergencyContactsCard: some View {
        SectionCard("more.emergency_contacts", icon: "phone.arrow.up.right.fill") {
            if athlete.emergencyContacts.isEmpty {
                EmptyStateCard(
                    icon: "phone.badge.plus",
                    titleKey: "emergency.empty.title",
                    messageKey: "emergency.empty.message"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(athlete.emergencyContacts) { contact in
                        contactRow(contact)
                        if contact.id != athlete.emergencyContacts.last?.id {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
    }

    private func contactRow(_ contact: EmergencyContact) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.red.opacity(0.12))
                Image(systemName: "heart.fill")
                    .scaledFont(.footnote)
                    .foregroundStyle(.red)
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: contact.name)
                    .scaledFont(.subheadline, weight: .semibold)
                Text(verbatim: contact.relationship)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(verbatim: contact.phone)
                .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                .foregroundStyle(.primary)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.vertical, 4)
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
    }
}

import SwiftUI

public struct BeltProgressionCard: View {
    @Environment(AppSession.self) private var session
    @Binding var athlete: Athlete

    @State private var saving = false

    public init(athlete: Binding<Athlete>) {
        self._athlete = athlete
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("athlete.section.belt_progression").scaledFont(.headline)
            currentBeltRow
            statsRow
            readinessRow
            targetDateRow
            curriculumRow
            beltJourney
        }
    }

    // MARK: - Current belt

    private var currentBeltRow: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6)
                .fill(athlete.currentBelt.color.swiftUIColor)
                .frame(width: 36, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(localizedKey: athlete.currentBelt.label)
                    .scaledFont(.subheadline, weight: .bold)
                Text(athlete.currentBelt.awardedAt, style: .date)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Time at rank + next belt preview

    private var statsRow: some View {
        let nextBelt = GradingEngine.nextBelt(after: athlete.currentBelt)
        return HStack(spacing: 8) {
            statPill(
                label: "belt.months_at_rank",
                value: "\(athlete.monthsAtCurrentRank)"
            )
            HStack(spacing: 6) {
                Image(systemName: "arrow.forward.circle")
                    .scaledFont(.caption)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text("belt.next_target")
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                    Text(localizedKey: nextBelt.label)
                        .scaledFont(.caption, weight: .bold)
                }
            }
            .padding(8)
            .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func statPill(label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).scaledFont(.caption2).foregroundStyle(.secondary)
            Text(verbatim: value)
                .scaledFont(.callout, weight: .bold, monospacedDigit: true)
                .foregroundStyle(.primary)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Coach readiness rating

    private var readinessRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "star.fill").foregroundStyle(.tint)
            Text("belt.grading_readiness").scaledFont(.subheadline)
            Spacer()
            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        guard canEdit else { return }
                        let new = (athlete.gradingReadiness == star) ? nil : star
                        Task { await save { $0.gradingReadiness = new } }
                    } label: {
                        Image(systemName: starIcon(for: star))
                            .scaledFont(.callout)
                            .foregroundStyle(starColor(for: star))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canEdit)
                }
            }
        }
        .padding(10)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 8))
    }

    private func starIcon(for star: Int) -> String {
        guard let r = athlete.gradingReadiness else { return "star" }
        return star <= r ? "star.fill" : "star"
    }

    private func starColor(for star: Int) -> Color {
        let dim = Color.secondary.opacity(0.4)
        guard let r = athlete.gradingReadiness else { return dim }
        return star <= r ? readinessColor(r) : dim
    }

    private func readinessColor(_ rating: Int) -> Color {
        switch rating {
        case ..<3: .red
        case 3: .orange
        case 4: .blue
        default: .green
        }
    }

    // MARK: - Target grading date

    @ViewBuilder
    private var targetDateRow: some View {
        if canEdit {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock").foregroundStyle(.tint)
                Text("belt.next_grading_date").scaledFont(.subheadline)
                Spacer()
                DatePicker(
                    "",
                    selection: Binding(
                        get: { athlete.nextGradingTargetDate ?? Date() },
                        set: { newValue in
                            Task { await save { $0.nextGradingTargetDate = newValue } }
                        }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()
                if athlete.nextGradingTargetDate != nil {
                    Button {
                        Task { await save { $0.nextGradingTargetDate = nil } }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 8))
        } else if let date = athlete.nextGradingTargetDate {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock").foregroundStyle(.tint)
                Text("belt.next_grading_date").scaledFont(.subheadline)
                Spacer()
                Text(date, style: .date)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.primary)
            }
            .padding(10)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Curriculum mastery (poomsae forms required for current belt)

    private var curriculumRow: some View {
        let required = PoomsaeForm.allCases.filter { $0.isRequired(for: athlete.currentBelt) }
        let known = required.filter { athlete.poomsaeKnown.contains($0) }
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "book.closed.fill").foregroundStyle(.tint)
                Text("belt.curriculum_mastery").scaledFont(.subheadline)
                Spacer()
                Text(verbatim: "\(known.count) / \(required.count)")
                    .scaledFont(.callout, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(known.count == required.count ? .green : .primary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            if required.isEmpty {
                Text("belt.no_curriculum")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView(
                    value: required.isEmpty ? 0 : Double(known.count) / Double(required.count)
                )
                .tint(known.count == required.count ? .green : .accentColor)
                ForEach(required, id: \.self) { form in
                    HStack(spacing: 6) {
                        Image(systemName: athlete.poomsaeKnown.contains(form)
                              ? "checkmark.circle.fill" : "circle")
                            .scaledFont(.caption2)
                            .foregroundStyle(athlete.poomsaeKnown.contains(form) ? Color.green : Color.secondary.opacity(0.5))
                        Text(localizedKey: form.labelKey)
                            .scaledFont(.caption2)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Belt history timeline

    private var beltJourney: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("heading.belt_journey").scaledFont(.subheadline, weight: .bold)
            ForEach(athlete.beltHistory.indices, id: \.self) { i in
                let b = athlete.beltHistory[i]
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(b.color.swiftUIColor)
                        .frame(width: 24, height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                    Text(localizedKey: b.label)
                        .scaledFont(.caption)
                    Spacer()
                    Text(b.awardedAt, style: .date)
                        .foregroundStyle(.secondary)
                        .scaledFont(.caption2)
                }
            }
        }
    }

    // MARK: - Permissions + persistence

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editAthlete)
    }

    private func save(_ mutate: (inout Athlete) -> Void) async {
        var copy = athlete
        mutate(&copy)
        athlete = copy
        do {
            try await session.repository.upsert(copy)
        } catch {
            print("BeltProgressionCard.save:", error)
        }
    }
}

import SwiftUI

public struct TechnicalSkillsCard: View {
    @Environment(AppSession.self) private var session
    public let athleteID: EntityID

    @State private var skills: [TechnicalSkill] = []
    @State private var loading = true
    @State private var sheetTarget: SheetTarget?

    public init(athleteID: EntityID) {
        self.athleteID = athleteID
    }

    private struct SheetTarget: Identifiable {
        let kind: TechniqueKind
        let initial: TechnicalSkill?
        var id: String { "\(kind.rawValue).\(initial?.id.uuidString ?? "new")" }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("athlete.section.technical_skills").scaledFont(.headline)
            if loading {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                ForEach(TechniqueCategory.allCases, id: \.self) { category in
                    categorySection(category)
                }
            }
        }
        .task { await load() }
        .sheet(item: $sheetTarget) { target in
            NavigationStack {
                TechnicalSkillEntrySheet(
                    athleteID: athleteID,
                    kind: target.kind,
                    initial: target.initial,
                    onSave: { skill in Task { await save(skill) } },
                    onDelete: target.initial.map { entry in
                        { Task { await delete(id: entry.id) } }
                    }
                )
            }
        }
    }

    private static let tileColumns = [GridItem(.adaptive(minimum: 150), spacing: 8)]

    private func categorySection(_ category: TechniqueCategory) -> some View {
        let kinds = TechniqueKind.allCases.filter { $0.category == category }
        let latest = skills.latestPerKind()
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: category.systemIcon)
                    .scaledFont(.caption, weight: .bold)
                    .foregroundStyle(.tint)
                    .frame(width: 20, height: 20)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                Text(localizedKey: category.labelKey)
                    .scaledFont(.subheadline, weight: .bold)
                Spacer()
            }
            LazyVGrid(columns: Self.tileColumns, spacing: 6) {
                ForEach(kinds, id: \.self) { kind in
                    skillTile(kind: kind, entry: latest.first { $0.kind == kind })
                }
            }
        }
    }

    private func skillTile(kind: TechniqueKind, entry: TechnicalSkill?) -> some View {
        let avg: Double = entry.map { $0.averageScore } ?? 0
        let tint: Color = entry == nil ? Color.secondary : tileColor(avg)
        return Button {
            guard canEdit else { return }
            sheetTarget = SheetTarget(kind: kind, initial: entry)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 3) {
                    Text(localizedKey: kind.labelKey)
                        .scaledFont(.caption2, weight: .semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    if entry?.videoURL?.isEmpty == false {
                        Image(systemName: "video.fill")
                            .scaledFont(size: 9)
                            .foregroundStyle(.tint)
                    }
                }
                Spacer(minLength: 0)
                if let entry {
                    HStack(spacing: 4) {
                        scoreBlock(label: "technique.form_short", score: entry.formScore)
                        scoreBlock(label: "technique.app_short", score: entry.applicationScore)
                    }
                } else {
                    Text("technique.not_assessed")
                        .scaledFont(size: 10, weight: .semibold)
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                }
            }
            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
            .padding(8)
            .background(tint.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tint.opacity(0.35), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    private func scoreBlock(label: LocalizedStringKey, score: Int) -> some View {
        let color = scoreColor(score)
        return HStack(spacing: 2) {
            Text(label)
                .scaledFont(size: 9, weight: .bold)
                .foregroundStyle(.secondary)
            Text(verbatim: "\(score)")
                .scaledFont(.subheadline, weight: .bold, monospacedDigit: true)
                .foregroundStyle(color)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 4))
    }

    /// Tile background tint follows the average score so coaches can scan the
    /// grid for weak techniques at a glance.
    private func tileColor(_ avg: Double) -> Color {
        switch avg {
        case ..<5: .red
        case 5..<7: .orange
        case 7..<9: .blue
        default: .green
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case ..<5: .red
        case 5...6: .orange
        case 7...8: .blue
        default: .green
        }
    }

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editAthlete)
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            skills = try await session.repository.technicalSkills(athleteID: athleteID)
        } catch {
            print("TechnicalSkillsCard.load:", error)
        }
    }

    private func save(_ skill: TechnicalSkill) async {
        do {
            try await session.repository.upsert(skill: skill)
            await load()
        } catch {
            print("TechnicalSkillsCard.save:", error)
        }
    }

    private func delete(id: EntityID) async {
        do {
            try await session.repository.deleteTechnicalSkill(id: id)
            await load()
        } catch {
            print("TechnicalSkillsCard.delete:", error)
        }
    }
}

// MARK: - Entry sheet

private struct TechnicalSkillEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var session

    let athleteID: EntityID
    let kind: TechniqueKind
    let initial: TechnicalSkill?
    let onSave: (TechnicalSkill) -> Void
    let onDelete: (() -> Void)?

    @State private var recordedAt: Date
    @State private var formScore: Int
    @State private var applicationScore: Int
    @State private var videoURL: String
    @State private var notes: String

    init(
        athleteID: EntityID,
        kind: TechniqueKind,
        initial: TechnicalSkill?,
        onSave: @escaping (TechnicalSkill) -> Void,
        onDelete: (() -> Void)?
    ) {
        self.athleteID = athleteID
        self.kind = kind
        self.initial = initial
        self.onSave = onSave
        self.onDelete = onDelete
        _recordedAt = State(initialValue: initial?.recordedAt ?? Date())
        _formScore = State(initialValue: initial?.formScore ?? 7)
        _applicationScore = State(initialValue: initial?.applicationScore ?? 6)
        _videoURL = State(initialValue: initial?.videoURL ?? "")
        _notes = State(initialValue: initial?.notes ?? "")
    }

    var body: some View {
        Form {
            Section {
                DatePicker("athlete.weight_recorded_at", selection: $recordedAt, displayedComponents: .date)
            }

            Section {
                scoreRow(title: "technique.form", value: $formScore)
                scoreRow(title: "technique.application", value: $applicationScore)
            } footer: {
                Text("technique.score_help").scaledFont(.caption2).foregroundStyle(.secondary)
            }

            Section {
                TextField("technique.video_url", text: $videoURL)
                    #if os(iOS)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif
            } header: {
                Text("technique.video_url")
            }

            Section {
                TextField("athlete.injury_notes", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            if let onDelete {
                Section {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label("action.delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle(Text(localizedKey: kind.labelKey))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
                .bareToolbarButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("action.save") { commit() }
                    .disabled(session.currentUser == nil)
                .bareToolbarButton()
            }
        }
    }

    private func scoreRow(title: LocalizedStringKey, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).scaledFont(.subheadline)
                Spacer()
                Text(verbatim: "\(value.wrappedValue) / 10")
                    .scaledFont(.callout, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(.tint)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0.rounded()) }
                ),
                in: 1...10,
                step: 1
            )
        }
    }

    private func commit() {
        guard let coachID = session.currentUser?.id else { return }
        let trimmed = videoURL.trimmingCharacters(in: .whitespaces)
        let skill = TechnicalSkill(
            id: initial?.id ?? UUID(),
            athleteID: athleteID,
            recordedAt: recordedAt,
            recordedByCoachID: initial?.recordedByCoachID ?? coachID,
            kind: kind,
            formScore: formScore,
            applicationScore: applicationScore,
            videoURL: trimmed.isEmpty ? nil : trimmed,
            notes: notes.isEmpty ? nil : notes
        )
        onSave(skill)
        dismiss()
    }
}

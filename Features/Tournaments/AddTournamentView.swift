import SwiftUI

public struct AddTournamentView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let editing: Tournament?
    public let onSaved: (Tournament) -> Void

    @State private var name: String
    @State private var nameAr: String
    @State private var hostingFederation: HostingFederation
    @State private var startsAt: Date
    @State private var endsAt: Date
    @State private var location: String
    @State private var locationAr: String
    @State private var isOfficial: Bool
    @State private var weightCategoriesOffered: Set<WeightCategory>
    @State private var hasLevel: Bool
    @State private var level: EventLevel
    @State private var sanctioningBody: String

    @State private var saving = false
    @State private var error: String?
    @State private var showErrorAlert = false

    public init(editing: Tournament? = nil, onSaved: @escaping (Tournament) -> Void) {
        self.editing = editing
        self.onSaved = onSaved
        _name = State(initialValue: editing?.name ?? "")
        _nameAr = State(initialValue: editing?.nameAr ?? "")
        _hostingFederation = State(initialValue: editing?.hostingFederation ?? .uae)
        let defaultStart = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        let defaultEnd = defaultStart.addingTimeInterval(2 * 24 * 3600)
        _startsAt = State(initialValue: editing?.startsAt ?? defaultStart)
        _endsAt = State(initialValue: editing?.endsAt ?? defaultEnd)
        _location = State(initialValue: editing?.location ?? "")
        _locationAr = State(initialValue: editing?.locationAr ?? "")
        _isOfficial = State(initialValue: editing?.isOfficial ?? true)
        _weightCategoriesOffered = State(initialValue: Set<WeightCategory>(editing?.weightCategoriesOffered ?? []))
        _hasLevel = State(initialValue: editing?.level != nil)
        _level = State(initialValue: editing?.level ?? .national)
        _sanctioningBody = State(initialValue: editing?.sanctioningBody ?? "")
    }

    public var body: some View {
        Form {
            Section {
                TextField("tournament.name", text: $name)
                TextField("tournament.name_ar", text: $nameAr)
            } header: {
                Text("tournament.section.identity")
            }

            Section {
                Picker("tournament.federation", selection: $hostingFederation) {
                    ForEach(HostingFederation.allCases, id: \.self) { f in
                        Text(localizedKey: f.labelKey).tag(f)
                    }
                }
                Toggle("tournament.has_level", isOn: $hasLevel)
                if hasLevel {
                    Picker("tournament.level", selection: $level) {
                        ForEach(EventLevel.allCases, id: \.self) { l in
                            Text(localizedKey: l.labelKey).tag(l)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                TextField("tournament.sanctioning_body", text: $sanctioningBody)
                Toggle("tournament.official", isOn: $isOfficial)
            } header: {
                Text("tournament.section.classification")
            }

            Section {
                DatePicker("tournament.starts_at", selection: $startsAt, displayedComponents: .date)
                DatePicker("tournament.ends_at", selection: $endsAt, in: startsAt..., displayedComponents: .date)
                TextField("tournament.location", text: $location)
                TextField("tournament.location_ar", text: $locationAr)
            } header: {
                Text("tournament.section.schedule")
            }

            Section {
                ForEach(WeightCategory.allCases, id: \.self) { cat in
                    Button {
                        if weightCategoriesOffered.contains(cat) {
                            weightCategoriesOffered.remove(cat)
                        } else {
                            weightCategoriesOffered.insert(cat)
                        }
                    } label: {
                        HStack {
                            Image(systemName: weightCategoriesOffered.contains(cat)
                                  ? "checkmark.square.fill" : "square")
                                .foregroundStyle(weightCategoriesOffered.contains(cat) ? Color.accentColor : Color.secondary)
                            Text(localizedKey: cat.ageGroup.labelKey)
                                .scaledFont(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(verbatim: cat.shortLabel)
                                .scaledFont(.callout, monospacedDigit: true)
                                .foregroundStyle(.primary)
                                .environment(\.layoutDirection, .leftToRight)
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("tournament.section.weight_categories")
            } footer: {
                Text(verbatim: String(format: NSLocalizedString("tournament.categories_count", comment: ""), weightCategoriesOffered.count))
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(Text(editing == nil ? "tournament.add" : "tournament.edit"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
                .bareToolbarButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task { await save() }
                } label: {
                    if saving { ProgressView() } else { Text("action.save") }
                }
                .disabled(saving || !isValid)
            }
        }
        .alert("tournament.save_error", isPresented: $showErrorAlert) {
            Button("action.ok", role: .cancel) {}
        } message: {
            Text(verbatim: error ?? "")
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !location.trimmingCharacters(in: .whitespaces).isEmpty
            && endsAt >= startsAt
    }

    private func save() async {
        saving = true
        defer { saving = false }
        let t = Tournament(
            id: editing?.id ?? UUID(),
            name: name,
            nameAr: nameAr.isEmpty ? nil : nameAr,
            hostingFederation: hostingFederation,
            startsAt: startsAt,
            endsAt: endsAt,
            location: location,
            locationAr: locationAr.isEmpty ? nil : locationAr,
            isOfficial: isOfficial,
            weightCategoriesOffered: Array(weightCategoriesOffered).sorted(by: { $0.rawValue < $1.rawValue }),
            level: hasLevel ? level : nil,
            sanctioningBody: sanctioningBody.isEmpty ? nil : sanctioningBody
        )
        do {
            try await session.repository.upsert(tournament: t)
            onSaved(t)
            dismiss()
        } catch {
            print("AddTournamentView.save:", error)
            self.error = error.localizedDescription
            showErrorAlert = true
        }
    }
}

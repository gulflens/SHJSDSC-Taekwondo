import SwiftUI

public struct RegisterAthleteView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let tournamentID: EntityID
    public let onRegistered: (TournamentRegistration) -> Void

    @State private var tournament: Tournament?
    @State private var athletes: [Athlete] = []
    @State private var selectedAthleteID: EntityID?
    @State private var category: WeightCategory?
    @State private var seedRank: Int = 1
    @State private var saving = false

    public init(tournamentID: EntityID, onRegistered: @escaping (TournamentRegistration) -> Void) {
        self.tournamentID = tournamentID
        self.onRegistered = onRegistered
    }

    public var body: some View {
        Form {
            Section(header: Text("tab.athletes")) {
                Picker(selection: $selectedAthleteID) {
                    Text("filter.all").tag(EntityID?.none)
                    ForEach(athletes) { a in
                        Text(verbatim: a.fullName).tag(Optional(a.id))
                    }
                } label: {
                    Text("tab.athletes")
                }
                .onChange(of: selectedAthleteID) { _, newValue in
                    if let id = newValue, let a = athletes.first(where: { $0.id == id }) {
                        category = WeightCategory.suggested(for: a)
                    }
                }
            }
            Section(header: Text("tournament.weight_category")) {
                Picker(selection: $category) {
                    Text("filter.all").tag(WeightCategory?.none)
                    if let offered = tournament?.weightCategoriesOffered {
                        ForEach(offered, id: \.self) { c in
                            Text(verbatim: c.shortLabel).tag(Optional(c))
                        }
                    }
                } label: {
                    Text("tournament.weight_category")
                }
            }
            Section(header: Text("tournament.seed")) {
                Stepper(value: $seedRank, in: 1...32) {
                    HStack {
                        Text("tournament.seed")
                        Spacer()
                        Text(verbatim: "#\(seedRank)")
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
            }
            Section {
                Button {
                    Task { await save() }
                } label: {
                    if saving {
                        HStack { ProgressView(); Text("action.saving") }
                    } else {
                        Text("tournament.register")
                    }
                }
                .disabled(saving || selectedAthleteID == nil || category == nil)
            }
        }
        .navigationTitle(Text("tournament.register"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            tournament = try await session.repository.tournament(id: tournamentID)
            athletes = try await session.repository.athletes()
        } catch {
            print("RegisterAthleteView.load:", error)
        }
    }

    private func save() async {
        guard let athleteID = selectedAthleteID, let category else { return }
        saving = true
        defer { saving = false }
        let reg = TournamentRegistration(
            tournamentID: tournamentID,
            athleteID: athleteID,
            weightCategory: category,
            seedRank: seedRank,
            registeredAt: Date(),
            status: .registered
        )
        do {
            try await session.repository.upsert(registration: reg)
            onRegistered(reg)
            dismiss()
        } catch {
            print("RegisterAthleteView.save:", error)
        }
    }
}

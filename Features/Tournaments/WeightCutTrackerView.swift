import SwiftUI
import Charts

public struct WeightCutTrackerView: View {
    @Environment(AppSession.self) private var session

    public let registrationID: EntityID

    @State private var store: WeightCutStore?
    @State private var registration: TournamentRegistration?
    @State private var tournament: Tournament?
    @State private var newWeight: Double = 50
    @State private var saving = false

    public init(registrationID: EntityID) { self.registrationID = registrationID }

    public var body: some View {
        Group {
            if let store {
                content(store: store)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(Text("tournament.weigh_in"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            if store == nil { store = WeightCutStore(repository: session.repository) }
            await store?.load(registrationID: registrationID)
            await loadContext()
            if let target = store?.targetKg { newWeight = target + 2 }
        }
    }

    @ViewBuilder
    private func content(store: WeightCutStore) -> some View {
        Form {
            Section {
                if let target = store.targetKg {
                    HStack {
                        Text("weightcut.target")
                        Spacer()
                        Text(verbatim: String(format: "%.1f kg", target))
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
                if let latest = store.entries.max(by: { $0.recordedAt < $1.recordedAt }) {
                    HStack {
                        Text("weightcut.current")
                        Spacer()
                        Text(verbatim: String(format: "%.1f kg", latest.currentKg))
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    HStack {
                        Text("weightcut.delta")
                        Spacer()
                        Text(verbatim: String(format: "%+.1f kg", latest.deltaKg))
                            .foregroundStyle(latest.deltaKg > 0 ? .orange : .green)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    if let t = tournament {
                        HStack {
                            Text("weightcut.days_left")
                            Spacer()
                            Text(verbatim: "\(latest.daysToCompetition(t.startsAt))")
                                .foregroundStyle(.secondary)
                                .environment(\.layoutDirection, .leftToRight)
                        }
                    }
                }
            }
            if !store.entries.isEmpty {
                Section {
                    chartView(store: store)
                        .frame(height: 200)
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("weightcut.current")
                        Spacer()
                        Text(verbatim: String(format: "%.1f kg", newWeight))
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    Slider(value: $newWeight, in: 20...120, step: 0.1)
                }
                Button {
                    Task { await log() }
                } label: {
                    if saving {
                        HStack { ProgressView(); Text("action.saving") }
                    } else {
                        Text("action.save")
                    }
                }
                .disabled(saving)
            }
        }
    }

    @ViewBuilder
    private func chartView(store: WeightCutStore) -> some View {
        let target = store.targetKg ?? 0
        Chart {
            ForEach(Array(store.trend.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("date", point.date),
                    y: .value("kg", point.value)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(.tint)
                PointMark(
                    x: .value("date", point.date),
                    y: .value("kg", point.value)
                )
                .foregroundStyle(.tint)
            }
            if target > 0 {
                RuleMark(y: .value("target", target))
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
            }
        }
    }

    private func loadContext() async {
        do {
            let regs = try await session.repository.registrations(athleteID: UUID()) // placeholder
            _ = regs
            // Fetch the registration and tournament directly
            let allTournaments = try await session.repository.tournaments()
            for t in allTournaments {
                let regsForT = try await session.repository.registrations(tournamentID: t.id)
                if let r = regsForT.first(where: { $0.id == registrationID }) {
                    registration = r
                    tournament = t
                    return
                }
            }
        } catch {
            print("WeightCutTrackerView.loadContext:", error)
        }
    }

    private func log() async {
        guard let target = store?.targetKg else { return }
        saving = true
        defer { saving = false }
        await store?.log(registrationID: registrationID, currentKg: newWeight, targetKg: target)
    }
}

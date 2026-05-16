import SwiftUI

public struct WellnessCheckInView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let athlete: Athlete

    @State private var sleepHours: Double = 8
    @State private var mood: Int = 7
    @State private var soreness: Int = 3
    @State private var motivation: Int = 7
    @State private var stress: Int = 4
    @State private var rpe: Int = 6
    @State private var notes: String = ""
    @State private var saving = false
    @State private var streak: Int = 0
    @State private var savedJustNow = false

    public init(athlete: Athlete) { self.athlete = athlete }

    public var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("wellness.sleep_hours")
                        Spacer()
                        Text(verbatim: String(format: "%.1f h", sleepHours))
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    Slider(value: $sleepHours, in: 0...12, step: 0.5)
                }
                stepper("wellness.mood", value: $mood, range: 1...10)
                stepper("wellness.motivation", value: $motivation, range: 1...10)
                stepper("wellness.soreness", value: $soreness, range: 1...10)
                stepper("wellness.stress", value: $stress, range: 1...10)
                stepper("wellness.rpe", value: $rpe, range: 1...10)
            }
            Section(header: Text("physical.notes")) {
                TextField("physical.notes", text: $notes, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
            }
            if savedJustNow {
                Section {
                    HStack {
                        Image(systemName: "flame.fill").foregroundStyle(.orange)
                        Text("wellness.streak")
                        Spacer()
                        Text(verbatim: "\(streak)")
                            .scaledFont(.title3, weight: .bold)
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
                        Text("action.save")
                    }
                }
                .disabled(saving)
            }
        }
        .navigationTitle(Text("wellness.entry"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await refreshStreak() }
    }

    private func stepper(_ title: LocalizedStringKey, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(title)
                Spacer()
                Text(verbatim: "\(value.wrappedValue)")
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        let entry = WellnessEntry(
            athleteID: athlete.id,
            recordedAt: Date(),
            sleepHours: sleepHours,
            mood: mood,
            soreness: soreness,
            motivation: motivation,
            stress: stress,
            rpePreviousSession: rpe,
            notes: notes.isEmpty ? nil : notes
        )
        do {
            try await session.repository.upsert(wellness: entry)
            await refreshStreak()
            savedJustNow = true
        } catch {
            print("WellnessCheckInView.save:", error)
        }
    }

    private func refreshStreak() async {
        let since = Date().addingTimeInterval(-30 * 24 * 3600)
        do {
            let entries = try await session.repository.wellness(athleteID: athlete.id, since: since)
            let cal = Calendar.current
            let dates = Set(entries.map { cal.startOfDay(for: $0.recordedAt) })
            var s = 0
            var cursor = cal.startOfDay(for: Date())
            while dates.contains(cursor) {
                s += 1
                cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            }
            streak = s
        } catch {
            print("WellnessCheckInView.refreshStreak:", error)
        }
    }
}

import SwiftUI

public struct PhysicalTestEntryView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let athlete: Athlete

    @State private var beepStage: Double = 7
    @State private var verticalJumpCm: Double = 35
    @State private var sprint30mSec: Double = 6.0
    @State private var agility4x10Sec: Double = 12.0
    @State private var pushUps: Int = 30
    @State private var notes: String = ""
    @State private var saving = false

    public init(athlete: Athlete) { self.athlete = athlete }

    public var body: some View {
        Form {
            Section {
                metric(title: "physical.beep_test", value: beepStage, range: 0...13, step: 0.5, suffix: nil) { Slider(value: $beepStage, in: 0...13, step: 0.5) }
                metric(title: "physical.vertical_jump", value: verticalJumpCm, range: 0...60, step: 1, suffix: "cm") { Slider(value: $verticalJumpCm, in: 0...60, step: 1) }
                metric(title: "physical.sprint_30m", value: sprint30mSec, range: 3...10, step: 0.1, suffix: "s") { Slider(value: $sprint30mSec, in: 3...10, step: 0.1) }
                metric(title: "physical.agility", value: agility4x10Sec, range: 8...20, step: 0.1, suffix: "s") { Slider(value: $agility4x10Sec, in: 8...20, step: 0.1) }
                Stepper(value: $pushUps, in: 0...100) {
                    HStack {
                        Text("physical.push_ups")
                        Spacer()
                        Text(verbatim: "\(pushUps)")
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
            } footer: {
                Text("physical.help").font(.caption2).foregroundStyle(.secondary)
            }
            Section(header: Text("physical.notes")) {
                TextField("physical.notes", text: $notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
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
        .navigationTitle(Text("physical.entry"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func metric<S: View>(title: LocalizedStringKey, value: Double, range: ClosedRange<Double>, step: Double, suffix: String?, @ViewBuilder slider: () -> S) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(verbatim: suffix == nil ? String(format: "%.1f", value) : "\(String(format: "%.1f", value)) \(suffix ?? "")")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            slider()
        }
    }

    private func save() async {
        guard let coachID = session.currentUser?.id else { return }
        saving = true
        defer { saving = false }
        let test = PhysicalTest(
            athleteID: athlete.id,
            recordedAt: Date(),
            recordedByCoachID: coachID,
            beepTestStage: beepStage,
            verticalJumpCm: verticalJumpCm,
            sprint30mSec: sprint30mSec,
            agility4x10Sec: agility4x10Sec,
            pushUps1Min: pushUps,
            notes: notes.isEmpty ? nil : notes
        )
        do {
            try await session.repository.upsert(physicalTest: test)
            dismiss()
        } catch {
            print("PhysicalTestEntryView.save:", error)
        }
    }
}

import SwiftUI

public struct TechnicalAssessmentEntryView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let athlete: Athlete

    @State private var poomsaeForm: String = "Taegeuk Sa Jang"
    @State private var power: Int = 7
    @State private var accuracy: Int = 7
    @State private var rhythm: Int = 7
    @State private var balance: Int = 7
    @State private var expression: Int = 7
    @State private var notes: String = ""
    @State private var saving = false

    private let forms = [
        "Taegeuk Il Jang", "Taegeuk Ee Jang", "Taegeuk Sam Jang", "Taegeuk Sa Jang",
        "Taegeuk Oh Jang", "Taegeuk Yuk Jang", "Taegeuk Chil Jang", "Taegeuk Pal Jang",
        "Koryo", "Keumgang", "Taebaek"
    ]

    public init(athlete: Athlete) { self.athlete = athlete }

    public var body: some View {
        Form {
            Section(header: Text("assessment.poomsae_form")) {
                Picker(selection: $poomsaeForm) {
                    ForEach(forms, id: \.self) { Text(verbatim: $0).tag($0) }
                } label: {
                    Text("assessment.poomsae_form")
                }
            }
            Section {
                slider("assessment.power", value: $power)
                slider("assessment.accuracy", value: $accuracy)
                slider("assessment.rhythm", value: $rhythm)
                slider("assessment.balance", value: $balance)
                slider("assessment.expression", value: $expression)
            } footer: {
                let avg = Double(power + accuracy + rhythm + balance + expression) / 5.0
                Text(verbatim: String(format: "Avg: %.1f", avg))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
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
        .navigationTitle(Text("assessment.entry"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func slider(_ title: LocalizedStringKey, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(verbatim: "\(value.wrappedValue)")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
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

    private func save() async {
        guard let coachID = session.currentUser?.id else { return }
        saving = true
        defer { saving = false }
        let assessment = TechnicalAssessment(
            athleteID: athlete.id,
            recordedAt: Date(),
            recordedByCoachID: coachID,
            poomsaeForm: poomsaeForm,
            power: power, accuracy: accuracy, rhythm: rhythm, balance: balance, expression: expression,
            notes: notes.isEmpty ? nil : notes
        )
        do {
            try await session.repository.upsert(assessment: assessment)
            dismiss()
        } catch {
            print("TechnicalAssessmentEntryView.save:", error)
        }
    }
}

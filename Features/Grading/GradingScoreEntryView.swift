import SwiftUI

public struct GradingScoreEntryView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let sessionID: EntityID
    public let athlete: Athlete
    public let existing: GradingScore?
    public let onSaved: () -> Void

    @State private var poomsae: Double = 22
    @State private var kyorugi: Double = 22
    @State private var kibon: Double = 14
    @State private var breaking: Double = 14
    @State private var decision: GradingDecision = .pass
    @State private var notes: String = ""
    @State private var saving = false
    @State private var showCertificate = false
    @State private var lastIssuedCert: GradingCertificate?

    public init(
        sessionID: EntityID,
        athlete: Athlete,
        existing: GradingScore?,
        onSaved: @escaping () -> Void
    ) {
        self.sessionID = sessionID
        self.athlete = athlete
        self.existing = existing
        self.onSaved = onSaved
    }

    public var body: some View {
        Form {
            Section {
                HStack {
                    Avatar(seed: athlete.avatarSeed, label: athlete.initials, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: athlete.fullName)
                        HStack(spacing: 4) {
                            Text(localizedKey: athlete.currentBelt.label)
                                .scaledFont(.caption2)
                                .foregroundStyle(.secondary)
                            Text(verbatim: "→")
                            Text(localizedKey: GradingEngine.nextBelt(after: athlete.currentBelt).label)
                                .scaledFont(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section {
                slider("grading.poomsae_score", value: $poomsae, range: 0...30)
                slider("grading.kyorugi_score", value: $kyorugi, range: 0...30)
                slider("grading.kibon_score", value: $kibon, range: 0...20)
                slider("grading.breaking_score", value: $breaking, range: 0...20)
            } footer: {
                HStack {
                    Spacer()
                    Text(verbatim: "Total: \(total)/100")
                        .scaledFont(.callout, weight: .bold, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
            Section(header: Text("grading.decision")) {
                Picker(selection: $decision) {
                    ForEach(GradingDecision.allCases, id: \.self) { d in
                        Text(localizedKey: d.labelKey).tag(d)
                    }
                } label: { EmptyView() }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            Section(header: Text("physical.notes")) {
                TextField("physical.notes", text: $notes, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
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
                if existing != nil && decision == .pass {
                    Button {
                        Task { await issue() }
                    } label: {
                        Label("grading.certificate", systemImage: "rosette")
                    }
                }
            }
        }
        .navigationTitle(Text("grading.score"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear { hydrateFromExisting() }
        .sheet(isPresented: $showCertificate) {
            if let cert = lastIssuedCert {
                NavigationStack {
                    CertificateView(certificate: cert, athlete: athlete)
                }
            }
        }
    }

    private var total: Int {
        Int(poomsae.rounded()) + Int(kyorugi.rounded()) + Int(kibon.rounded()) + Int(breaking.rounded())
    }

    private func slider(_ title: LocalizedStringKey, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(verbatim: "\(Int(value.wrappedValue.rounded()))")
                    .scaledFont(.callout, monospacedDigit: true)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Slider(value: value, in: range, step: 1)
        }
    }

    private func hydrateFromExisting() {
        if let existing {
            poomsae = Double(existing.poomsae)
            kyorugi = Double(existing.kyorugi)
            kibon = Double(existing.kibon)
            breaking = Double(existing.breaking)
            decision = existing.decision
            notes = existing.notes ?? ""
        } else {
            decision = .pass
        }
    }

    private func save() async {
        guard let examinerID = session.currentUser?.id else { return }
        saving = true
        defer { saving = false }
        let computed = GradingScore(
            id: existing?.id ?? UUID(),
            sessionID: sessionID,
            athleteID: athlete.id,
            examinerID: examinerID,
            poomsae: Int(poomsae.rounded()),
            kyorugi: Int(kyorugi.rounded()),
            kibon: Int(kibon.rounded()),
            breaking: Int(breaking.rounded()),
            notes: notes.isEmpty ? nil : notes,
            decision: GradingEngine.decideOutcome(score: GradingScore(
                sessionID: sessionID, athleteID: athlete.id, examinerID: examinerID,
                poomsae: Int(poomsae.rounded()), kyorugi: Int(kyorugi.rounded()),
                kibon: Int(kibon.rounded()), breaking: Int(breaking.rounded()),
                decision: decision
            ))
        )
        do {
            try await session.repository.upsert(computed)
            decision = computed.decision
            onSaved()
            dismiss()
        } catch {
            print("GradingScoreEntryView.save:", error)
        }
    }

    private func issue() async {
        guard let examinerID = session.currentUser?.id else { return }
        let target = GradingEngine.nextBelt(after: athlete.currentBelt)
        let cert = GradingCertificate(
            athleteID: athlete.id,
            fromBelt: athlete.currentBelt,
            toBelt: target,
            awardedAt: Date(),
            sessionID: sessionID,
            signedByCoachIDs: [examinerID]
        )
        do {
            try await session.repository.issueCertificate(cert)
            // promote athlete locally
            var promoted = athlete
            promoted.beltHistory.append(promoted.currentBelt)
            promoted.currentBelt = target
            try await session.repository.upsert(promoted)
            lastIssuedCert = cert
            showCertificate = true
        } catch {
            print("GradingScoreEntryView.issue:", error)
        }
    }
}

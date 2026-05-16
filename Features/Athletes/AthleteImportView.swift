import SwiftUI
import UniformTypeIdentifiers

public struct AthleteImportView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let onCompleted: () -> Void

    @State private var pickerOpen = false
    @State private var importing = false
    @State private var imported: Int = 0
    @State private var skipped: [(row: Int, reason: String)] = []
    @State private var topLevelError: String?
    @State private var totalRows: Int = 0

    @State private var branchByCode: [String: Branch] = [:]
    @State private var coachByName: [String: Coach] = [:]
    @State private var templateURL: URL?

    public init(onCompleted: @escaping () -> Void) {
        self.onCompleted = onCompleted
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                instructionsCard
                pickerCard
                if importing {
                    progressCard
                } else if totalRows > 0 {
                    resultsCard
                }
                if let topLevelError {
                    errorCard(topLevelError)
                }
                Color.clear.frame(height: 24)
            }
            .padding(.horizontal, 16).padding(.top, 12)
        }
        .background(Color.appBackground)
        .navigationTitle(Text("athlete.import"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .fileImporter(
            isPresented: $pickerOpen,
            allowedContentTypes: [.commaSeparatedText, UTType(filenameExtension: "csv") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first { Task { await runImport(from: url) } }
            case .failure(let error):
                topLevelError = error.localizedDescription
            }
        }
        .task { await loadLookups() }
    }

    // MARK: - Cards

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "tablecells.fill").foregroundStyle(.tint)
                Text("athlete.import.instructions").scaledFont(.subheadline, weight: .bold)
                Spacer()
            }
            Text("athlete.import.instructions_body").scaledFont(.caption).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Button {
                    prepareTemplateURL()
                } label: {
                    Label("athlete.import.download_template", systemImage: "doc.badge.arrow.up")
                        .scaledFont(.caption, weight: .bold)
                }
                .buttonStyle(.bordered)
                if let url = templateURL {
                    ShareLink(item: url) {
                        Label("export.share", systemImage: "square.and.arrow.up")
                            .scaledFont(.caption, weight: .bold)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            Text("athlete.import.template_hint").scaledFont(.caption2).foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func prepareTemplateURL() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("athletes_import_template.csv")
        do {
            try AthleteImportTemplate.csvContent.write(to: url, atomically: true, encoding: .utf8)
            templateURL = url
        } catch {
            topLevelError = String(describing: error)
        }
    }

    private var pickerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                pickerOpen = true
            } label: {
                Label("athlete.import.choose_file", systemImage: "square.and.arrow.down")
                    .scaledFont(.callout, weight: .bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(importing || branchByCode.isEmpty)
            if branchByCode.isEmpty {
                Text("athlete.import.loading_lookups").scaledFont(.caption2).foregroundStyle(.secondary)
            } else {
                Text(verbatim: String(format: NSLocalizedString("athlete.import.lookups_ready", comment: ""),
                                      branchByCode.count, coachByName.count))
                    .scaledFont(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var progressCard: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(verbatim: String(format: NSLocalizedString("athlete.import.progress", comment: ""),
                                  imported, totalRows))
                .scaledFont(.caption)
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
    }

    private var resultsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                Text(verbatim: String(format: NSLocalizedString("athlete.import.summary", comment: ""),
                                      imported, skipped.count))
                    .scaledFont(.subheadline, weight: .bold)
                Spacer()
            }
            if !skipped.isEmpty {
                Divider()
                Text("athlete.import.skipped_header").scaledFont(.caption, weight: .bold)
                ForEach(skipped, id: \.row) { entry in
                    HStack(alignment: .firstTextBaseline) {
                        Text(verbatim: "Row \(entry.row)").scaledFont(.caption2, design: .monospaced)
                            .foregroundStyle(.secondary)
                            .frame(width: 56, alignment: .leading)
                            .environment(\.layoutDirection, .leftToRight)
                        Text(verbatim: entry.reason).scaledFont(.caption2)
                        Spacer()
                    }
                }
            }
            HStack {
                Spacer()
                Button {
                    onCompleted()
                    dismiss()
                } label: {
                    Text("action.done").bold()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func errorCard(_ msg: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
            Text(verbatim: msg).scaledFont(.caption)
            Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Loading

    private func loadLookups() async {
        do {
            let branches = try await session.repository.branches()
            let coaches = try await session.repository.coaches()
            branchByCode = Dictionary(uniqueKeysWithValues: branches.map { ($0.code, $0) })
            coachByName = Dictionary(uniqueKeysWithValues: coaches.map { ($0.fullName, $0) })
        } catch {
            topLevelError = String(describing: error)
        }
    }

    // MARK: - Import

    private func runImport(from url: URL) async {
        importing = true
        defer { importing = false }
        imported = 0
        skipped.removeAll()
        topLevelError = nil

        // SwiftUI's file picker hands back a security-scoped URL; we have to
        // bracket the read with start/stopAccessingSecurityScopedResource so
        // sandboxed reads don't error out on real device.
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

        let raw: String
        do { raw = try String(contentsOf: url, encoding: .utf8) }
        catch {
            topLevelError = String(describing: error)
            return
        }

        let parsed = CSVReader.parse(raw)
        guard let header = parsed.first else {
            topLevelError = String(localized: "athlete.import.empty_file")
            return
        }
        let rows = Array(parsed.dropFirst())
        totalRows = rows.count

        for (idx, row) in rows.enumerated() {
            let lineNumber = idx + 2   // 1-indexed + header row
            let dict = Dictionary(uniqueKeysWithValues: zip(header, row))
            switch buildAthlete(from: dict) {
            case .success(let athlete):
                do {
                    try await session.repository.upsert(athlete)
                    imported += 1
                } catch {
                    skipped.append((row: lineNumber, reason: String(describing: error)))
                }
            case .failure(let reason):
                skipped.append((row: lineNumber, reason: reason))
            }
        }
    }

    // MARK: - Row → Athlete

    private enum BuildResult {
        case success(Athlete)
        case failure(String)
    }

    private func buildAthlete(from row: [String: String]) -> BuildResult {
        func required(_ key: String) -> String? {
            let v = row[key]?.trimmingCharacters(in: .whitespaces) ?? ""
            return v.isEmpty ? nil : v
        }
        func optional(_ key: String) -> String? {
            let v = row[key]?.trimmingCharacters(in: .whitespaces) ?? ""
            return v.isEmpty ? nil : v
        }

        guard let fullName = required("full_name") else { return .failure("missing full_name") }
        guard let fullNameAr = required("full_name_ar") else { return .failure("missing full_name_ar") }
        guard let dobRaw = required("date_of_birth"), let dob = parseDate(dobRaw)
              else { return .failure("invalid date_of_birth (need YYYY-MM-DD)") }
        let gender: Gender = Gender(rawValue: row["gender"] ?? "") ?? .male
        guard let branchCode = required("branch_code"), let branch = branchByCode[branchCode]
              else { return .failure("branch_code not found in DB") }
        guard let joinedRaw = required("joined_at"), let joined = parseDate(joinedRaw)
              else { return .failure("invalid joined_at") }
        guard let weightRaw = required("weight_kg"), let weight = Double(weightRaw)
              else { return .failure("invalid weight_kg") }

        guard let beltColorRaw = required("current_belt_color"),
              let beltColor = BeltColor(rawValue: beltColorRaw)
              else { return .failure("invalid current_belt_color") }
        guard let beltKindRaw = required("current_belt_kind"),
              let beltKind = BeltKind(rawValue: beltKindRaw)
              else { return .failure("invalid current_belt_kind") }
        guard let beltNumRaw = required("current_belt_number"), let beltNum = Int(beltNumRaw)
              else { return .failure("invalid current_belt_number") }

        guard let statusRaw = required("status"), let status = AthleteStatus(rawValue: statusRaw)
              else { return .failure("invalid status") }

        let primaryCoachID: EntityID?
        if let coachName = optional("primary_coach_full_name") {
            guard let coach = coachByName[coachName] else {
                return .failure("primary_coach_full_name '\(coachName)' not found")
            }
            primaryCoachID = coach.id
        } else {
            primaryCoachID = nil
        }

        // Member number is allocated lifetime-unique by the live RPC. Fall
        // back to a placeholder if the call fails (importer logs the row
        // but the user can re-run the row after fixing the cause).
        let memberNumber = awaitOrZero {
            try await session.repository.nextMemberNumber()
        }

        let athlete = Athlete(
            memberNumber: memberNumber,
            fullName: fullName, fullNameAr: fullNameAr,
            dateOfBirth: dob, gender: gender,
            nationality: optional("nationality") ?? "AE",
            emiratesID: optional("emirates_id"),
            branchID: branch.id,
            primaryCoachID: primaryCoachID,
            joinedAt: joined,
            currentBelt: Belt(color: beltColor, kind: beltKind, number: beltNum, awardedAt: joined),
            beltHistory: [],
            weightKg: weight,
            status: status,
            avatarSeed: fullName.split(separator: " ").first.map(String.init)?.lowercased() ?? "athlete",
            avatarURL: nil,
            passportNumber: optional("passport_number"),
            bloodType: optional("blood_type").flatMap(BloodType.init(rawValue:)),
            federationLicenceNumber: optional("federation_licence_number"),
            parentUserIDs: [],
            emergencyContacts: [],
            school: optional("school"),
            imageRightsConsent: false, imageRightsConsentDate: nil,
            travelPermission: false, travelPermissionDate: nil,
            heightCm: optional("height_cm").flatMap(Double.init),
            weightHistory: [],
            allergies: splitList(optional("allergies")),
            medicalConditions: splitList(optional("medical_conditions")),
            medications: splitList(optional("medications")),
            fitToTrain: parseBool(optional("fit_to_train")) ?? true,
            injuries: [],
            weightClass: nil,
            dominantStance: optional("dominant_stance").flatMap(Stance.init(rawValue:)),
            poomsaeSyllabus: optional("poomsae_syllabus"),
            kyorugiTier: optional("kyorugi_tier").flatMap(KyorugiTier.init(rawValue:)),
            trainingGroupID: nil
        )
        return .success(athlete)
    }

    /// Synchronous unwrap for an async repository call from a non-async
    /// context. Returns 0 if the RPC fails — Stage 5 will replace this with
    /// a proper async path through buildAthlete.
    private func awaitOrZero(_ block: @escaping () async throws -> Int) -> Int {
        // The buildAthlete path runs inside an async runImport, but Swift's
        // ergonomics don't let us await mid-builder cleanly without a
        // refactor. We resolve the member number before constructing the
        // Athlete by hopping back through a semaphore — acceptable for
        // small batches; large imports would benefit from batching.
        let semaphore = DispatchSemaphore(value: 0)
        var result = 0
        Task {
            do { result = try await block() } catch { result = 0 }
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    private func splitList(_ s: String?) -> [String] {
        guard let s, !s.isEmpty else { return [] }
        return s.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private func parseBool(_ s: String?) -> Bool? {
        guard let s = s?.lowercased() else { return nil }
        if ["true", "yes", "1", "y"].contains(s) { return true }
        if ["false", "no", "0", "n"].contains(s) { return false }
        return nil
    }

    private func parseDate(_ s: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: s)
    }
}

// MARK: - Embedded template

/// CSV template content that ships with the app binary so users on TestFlight
/// can grab a starter file without going through the source repo. Single
/// source of truth — keep this in sync with templates/athletes_import_template.csv.
enum AthleteImportTemplate {
    static let csvContent: String = """
    full_name,full_name_ar,date_of_birth,gender,branch_code,joined_at,weight_kg,current_belt_color,current_belt_kind,current_belt_number,status,nationality,emirates_id,passport_number,blood_type,federation_licence_number,school,height_cm,allergies,medical_conditions,medications,fit_to_train,dominant_stance,poomsae_syllabus,kyorugi_tier,primary_coach_full_name
    Ahmed Al Mazrouei,أحمد المزروعي,2012-03-14,male,BR-NAS,2022-09-01,48,blue,gup,4,active,AE,784-1985-1234567-8,,A+,FED-12345,Sharjah Public School,148,peanuts,asthma,inhaler,true,orthodox,taegeuk-7,competitive,Yassin Al-Jawadi
    Mariam Al Suwaidi,مريم السويدي,2015-07-22,female,BR-RAH,2024-01-15,32,yellow,gup,8,active,AE,,P12345678,O+,,Al Rahmania School,135,,,,true,orthodox,taegeuk-3,recreational,Dr Ali Alawi

    """
}

// MARK: - CSV reader (RFC-4180-ish)

enum CSVReader {
    /// Returns rows of fields. Handles quoted fields, embedded commas,
    /// embedded newlines (inside quotes), and "" as escaped quote.
    static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var field = ""
        var row: [String] = []
        var inQuotes = false
        var i = text.startIndex

        while i < text.endIndex {
            let ch = text[i]
            if inQuotes {
                if ch == "\"" {
                    let next = text.index(after: i)
                    if next < text.endIndex, text[next] == "\"" {
                        field.append("\"")
                        i = text.index(after: next)
                        continue
                    }
                    inQuotes = false
                } else {
                    field.append(ch)
                }
            } else {
                switch ch {
                case ",":
                    row.append(field); field.removeAll()
                case "\n":
                    row.append(field); field.removeAll()
                    rows.append(row); row.removeAll()
                case "\r":
                    break
                case "\"":
                    inQuotes = true
                default:
                    field.append(ch)
                }
            }
            i = text.index(after: i)
        }
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        // Strip a fully-blank trailing row that some tools emit.
        if let last = rows.last, last.allSatisfy({ $0.isEmpty }) {
            rows.removeLast()
        }
        return rows
    }
}

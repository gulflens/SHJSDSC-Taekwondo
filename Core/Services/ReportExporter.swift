import Foundation

public enum ExportFormat: String, CaseIterable, Sendable, Hashable {
    case csv, pdf

    public var labelKey: String { "export.\(rawValue)" }
    public var fileExtension: String { rawValue }
    public var mimeType: String {
        switch self {
        case .csv: "text/csv"
        case .pdf: "application/pdf"
        }
    }
}

public protocol ReportExporter: Sendable {
    func exportAthletes(_ athletes: [Athlete], format: ExportFormat) -> Data
    func exportTournamentResults(
        tournament: Tournament,
        registrations: [TournamentRegistration],
        athletes: [Athlete],
        matches: [Match],
        format: ExportFormat
    ) -> Data
    func exportBranchPerformance(
        branches: [Branch],
        summaries: [BranchSummary],
        format: ExportFormat
    ) -> Data
    func exportMyData(
        user: User,
        athlete: Athlete?,
        registrations: [TournamentRegistration],
        matches: [Match]
    ) -> Data
}

/// CSV-only baseline implementation. PDF returns the same CSV bytes — the
/// platform-native PDF rendering lives in the SwiftUI layer where we can use
/// `ImageRenderer`. Keeping this pure-Foundation lets `Core/` stay UI-free.
public struct CSVReportExporter: ReportExporter {

    public init() {}

    public func exportAthletes(_ athletes: [Athlete], format: ExportFormat) -> Data {
        let header = "id,full_name,full_name_ar,branch_id,coach_id,belt,age,weight_kg,status\n"
        let rows = athletes.map { a in
            [
                a.id.uuidString,
                escape(a.fullName),
                escape(a.fullNameAr),
                a.branchID.uuidString,
                a.primaryCoachID?.uuidString ?? "",
                a.currentBelt.label,
                String(a.age),
                String(a.weightKg),
                a.status.rawValue
            ].joined(separator: ",")
        }.joined(separator: "\n")
        return (header + rows).data(using: .utf8) ?? Data()
    }

    public func exportTournamentResults(
        tournament: Tournament,
        registrations: [TournamentRegistration],
        athletes: [Athlete],
        matches: [Match],
        format: ExportFormat
    ) -> Data {
        let athleteByID = Dictionary(uniqueKeysWithValues: athletes.map { ($0.id, $0) })
        var lines: [String] = []
        lines.append("# tournament: \(escape(tournament.name))")
        lines.append("# starts_at: \(ISO8601DateFormatter().string(from: tournament.startsAt))")
        lines.append("")
        lines.append("athlete,weight_category,seed,status")
        for r in registrations {
            let name = athleteByID[r.athleteID]?.fullName ?? r.athleteID.uuidString
            lines.append([escape(name), r.weightCategory.rawValue, r.seedRank.map { String($0) } ?? "", r.status.rawValue].joined(separator: ","))
        }
        lines.append("")
        lines.append("athlete,opponent,our_score,opp_score,won,medal,date")
        let df = ISO8601DateFormatter()
        for m in matches {
            let athleteName = athleteByID[m.ourAthleteID]?.fullName ?? m.ourAthleteID.uuidString
            lines.append([
                escape(athleteName),
                escape(m.opponentName ?? "—"),
                String(m.ourScore),
                String(m.opponentScore),
                m.won ? "1" : "0",
                m.medal.rawValue,
                df.string(from: m.date)
            ].joined(separator: ","))
        }
        return lines.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    public func exportBranchPerformance(
        branches: [Branch],
        summaries: [BranchSummary],
        format: ExportFormat
    ) -> Data {
        let header = "code,name,name_ar,athletes,utilisation,composite,grade\n"
        let rows = summaries.map { s in
            [
                s.branch.code,
                escape(s.branch.name),
                escape(s.branch.nameAr),
                String(s.athleteCount),
                String(format: "%.2f", s.utilisation),
                String(format: "%.1f", s.composite),
                s.grade.label
            ].joined(separator: ",")
        }.joined(separator: "\n")
        return (header + rows).data(using: .utf8) ?? Data()
    }

    public func exportMyData(
        user: User,
        athlete: Athlete?,
        registrations: [TournamentRegistration],
        matches: [Match]
    ) -> Data {
        struct Bundle: Codable {
            let user: User
            let athlete: Athlete?
            let registrations: [TournamentRegistration]
            let matches: [Match]
            let exportedAt: Date
        }
        let bundle = Bundle(
            user: user,
            athlete: athlete,
            registrations: registrations,
            matches: matches,
            exportedAt: Date()
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(bundle)) ?? Data()
    }

    private func escape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }
}

import SwiftUI

/// Attendance tab — rate KPI strip, 12-week heat grid, and recent-session
/// list. Pulls from the AttendanceRecord array that AthleteDetailView loads.
public struct AthleteAttendanceTab: View {
    public let athlete: Athlete
    public let attendance: [AttendanceRecord]
    public let trainingLoad: [TrainingLoadEntry]
    public let matches: [Match]
    public let isWide: Bool

    public init(
        athlete: Athlete,
        attendance: [AttendanceRecord],
        trainingLoad: [TrainingLoadEntry],
        matches: [Match],
        isWide: Bool
    ) {
        self.athlete = athlete
        self.attendance = attendance
        self.trainingLoad = trainingLoad
        self.matches = matches
        self.isWide = isWide
    }

    public var body: some View {
        VStack(spacing: 14) {
            kpiStrip
            heatMapCard
            recentSessionsCard
        }
    }

    // MARK: - KPI strip

    private var kpiStrip: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 6 : 2),
            spacing: 12
        ) {
            KPITile(title: "attendance.rate", value: String(format: "%.0f%%", attendanceRate * 100), icon: "checkmark.circle.fill")
            KPITile(title: "attendance.sessions_completed", value: "\(sessionsCompleted)", icon: "calendar.badge.checkmark")
            KPITile(title: "attendance.late_arrivals", value: "\(lateArrivals)", icon: "clock.badge.exclamationmark")
            KPITile(title: "attendance.excused", value: "\(excusedAbsences)", icon: "envelope.fill")
            KPITile(title: "attendance.training_hours", value: String(format: "%.0fh", trainingHoursTotal), icon: "clock.fill")
            KPITile(title: "attendance.sparring_rounds", value: "\(sparringRoundsTotal)", icon: "figure.martial.arts")
        }
    }

    // MARK: - Heat map

    private var heatMapCard: some View {
        SectionCard("attendance.heatmap_title", icon: "calendar") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<12, id: \.self) { weekIndex in
                        VStack(spacing: 4) {
                            ForEach(0..<7, id: \.self) { day in
                                cell(weekIndex: 11 - weekIndex, day: day)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                HStack(spacing: 12) {
                    legendDot(.green, "attendance.present")
                    legendDot(.orange, "attendance.late")
                    legendDot(.gray, "attendance.excused")
                    legendDot(.red, "attendance.absent")
                    Spacer(minLength: 0)
                }
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func legendDot(_ color: Color, _ key: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(key)
        }
    }

    private func cell(weekIndex: Int, day: Int) -> some View {
        let cal = Calendar.current
        let now = Date()
        guard let weekStart = cal.date(byAdding: .day, value: -7 * weekIndex - (cal.component(.weekday, from: now) - 1), to: now) else {
            return AnyView(emptyCell)
        }
        guard let date = cal.date(byAdding: .day, value: day, to: weekStart) else {
            return AnyView(emptyCell)
        }
        let record = attendance.first { cal.isDate($0.recordedAt, inSameDayAs: date) }
        let color: Color = if let record {
            switch record.state {
            case .present: .green
            case .late: .orange
            case .excused: .gray
            case .absent: .red
            }
        } else if date > now {
            .clear
        } else {
            Color.secondary.opacity(0.10)
        }
        return AnyView(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 14, height: 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 0.5)
                )
        )
    }

    private var emptyCell: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(Color.secondary.opacity(0.08))
            .frame(width: 14, height: 14)
    }

    // MARK: - Recent sessions

    private var recentSessionsCard: some View {
        SectionCard("attendance.recent_sessions", icon: "list.bullet") {
            if attendance.isEmpty {
                EmptyStateCard(
                    icon: "calendar.badge.exclamationmark",
                    titleKey: "attendance.empty.title",
                    messageKey: "attendance.empty.message"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(attendance.sorted { $0.recordedAt > $1.recordedAt }.prefix(8))) { record in
                        attendanceRow(record)
                            .padding(.vertical, 4)
                        if record.id != attendance.sorted(by: { $0.recordedAt > $1.recordedAt }).prefix(8).last?.id {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
    }

    private func attendanceRow(_ record: AttendanceRecord) -> some View {
        HStack(spacing: 12) {
            Circle().fill(stateColor(record.state)).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.recordedAt, format: .dateTime.weekday(.wide).day().month(.abbreviated))
                    .scaledFont(.footnote)
                    .environment(\.layoutDirection, .leftToRight)
                Text(localizedKey: record.state.labelKey)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if let avg = record.engagementAverage {
                Text(verbatim: String(format: "%.1f / 5", avg))
                    .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
    }

    private func stateColor(_ state: AttendanceState) -> Color {
        switch state {
        case .present: .green
        case .late: .orange
        case .excused: .gray
        case .absent: .red
        }
    }

    // MARK: - Derived counts

    private var attendanceRate: Double {
        let countable = attendance.filter { $0.state != .excused }
        guard !countable.isEmpty else { return 0 }
        let present = countable.filter { $0.state == .present || $0.state == .late }.count
        return Double(present) / Double(countable.count)
    }

    private var sessionsCompleted: Int { attendance.filter { $0.state == .present }.count }
    private var lateArrivals: Int { attendance.filter { $0.state == .late }.count }
    private var excusedAbsences: Int { attendance.filter { $0.state == .excused }.count }

    private var trainingHoursTotal: Double {
        Double(trainingLoad.reduce(0) { $0 + $1.durationMinutes }) / 60.0
    }

    private var sparringRoundsTotal: Int {
        matches.reduce(0) { $0 + $1.rounds }
    }
}

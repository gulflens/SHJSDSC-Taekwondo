import SwiftUI

/// Coach attendance — sessions conducted KPI strip + 12-week heat grid +
/// recent session list. Pulls from the coach's ClassSession assignments.
public struct CoachAttendanceTab: View {
    public let coach: Coach
    public let sessions: [ClassSession]
    public let isWide: Bool

    public init(coach: Coach, sessions: [ClassSession], isWide: Bool) {
        self.coach = coach
        self.sessions = sessions
        self.isWide = isWide
    }

    public var body: some View {
        VStack(spacing: 14) {
            kpiStrip
            heatMapCard
            recentSessionsCard
        }
    }

    private var kpiStrip: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 5 : 2),
            spacing: 12
        ) {
            KPITile(title: "coach.attendance.sessions_conducted", value: "\(conductedCount)", icon: "calendar.badge.checkmark")
            KPITile(title: "coach.attendance.upcoming", value: "\(upcomingCount)", icon: "calendar.badge.clock")
            KPITile(title: "coach.attendance.training_hours", value: String(format: "%.0fh", trainingHours), icon: "clock.fill")
            KPITile(title: "coach.attendance.weekly_target", value: coach.weeklyHoursTarget.map { "\($0)h" } ?? "—", icon: "target")
            KPITile(title: "coach.attendance.cpd", value: String(format: "%.0fh", coach.cpdHoursThisYear), icon: "graduationcap.fill")
        }
    }

    private var heatMapCard: some View {
        SectionCard("coach.attendance.heatmap_title", icon: "calendar") {
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
                .padding(.vertical, 4)
                HStack(spacing: 12) {
                    legendDot(.green, "coach.attendance.taught")
                    legendDot(.orange, "coach.attendance.cover_needed")
                    legendDot(Color.secondary.opacity(0.18), "coach.attendance.off")
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
        let taught = sessions.contains { cal.isDate($0.startsAt, inSameDayAs: date) && $0.startsAt < now }
        let color: Color = if taught {
            .green
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

    private var recentSessionsCard: some View {
        SectionCard("coach.attendance.recent_sessions", icon: "list.bullet") {
            if sessions.isEmpty {
                EmptyStateCard(
                    icon: "calendar.badge.exclamationmark",
                    titleKey: "coach.attendance.empty.title",
                    messageKey: "coach.attendance.empty.message"
                )
            } else {
                let sorted = sessions.sorted { $0.startsAt > $1.startsAt }.prefix(8)
                VStack(spacing: 8) {
                    ForEach(Array(sorted)) { session in
                        sessionRow(session)
                        if session.id != sorted.last?.id {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
    }

    private func sessionRow(_ session: ClassSession) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(disciplineColor(session.discipline).opacity(0.14))
                Image(systemName: "figure.taekwondo")
                    .scaledFont(.footnote)
                    .foregroundStyle(disciplineColor(session.discipline))
            }
            .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: session.title)
                    .scaledFont(.footnote, weight: .semibold)
                HStack(spacing: 4) {
                    Text(session.startsAt, format: .dateTime.day().month(.abbreviated).hour().minute())
                        .environment(\.layoutDirection, .leftToRight)
                    Text(verbatim: "·")
                    Text(localizedKey: session.discipline.labelKey)
                }
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(verbatim: "\(session.enrolledAthleteIDs.count)/\(session.capacity)")
                .scaledFont(.caption, monospacedDigit: true)
                .foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.vertical, 4)
    }

    private func disciplineColor(_ discipline: ClassDiscipline) -> Color {
        switch discipline {
        case .poomsae: .purple
        case .kyorugi: .red
        case .fundamentals: .blue
        case .competition: .orange
        case .fitness: .green
        }
    }

    private var conductedCount: Int {
        let now = Date()
        return sessions.filter { $0.endsAt < now }.count
    }

    private var upcomingCount: Int {
        let now = Date()
        return sessions.filter { $0.startsAt > now }.count
    }

    private var trainingHours: Double {
        sessions.reduce(0.0) { acc, session in
            acc + session.endsAt.timeIntervalSince(session.startsAt) / 3600
        }
    }
}

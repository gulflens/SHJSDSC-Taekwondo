import SwiftUI

// MARK: - Coach dashboard cards
//
// Stage 1.14 — the coach performance card (list), the iPad preview panel,
// the 6-axis coaching radar and the certification row.

// MARK: Performance card

/// Premium coach intelligence card for the dashboard list.
public struct CoachPerformanceCard: View {
    private let intel: CoachIntel
    private let selected: Bool
    @Environment(\.horizontalSizeClass) private var hSize

    public init(intel: CoachIntel, selected: Bool) {
        self.intel = intel
        self.selected = selected
    }

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        Group {
            if isWide {
                HStack(alignment: .center, spacing: 14) {
                    avatar
                    infoColumn.frame(maxWidth: .infinity, alignment: .leading)
                    metricBlocks.frame(width: 232)
                    CoachGradeRing(grade: intel.grade, score: intel.composite,
                                   size: 56, showsCaption: false)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        avatar
                        infoColumn
                        Spacer(minLength: 4)
                        CoachGradeRing(grade: intel.grade, score: intel.composite,
                                       size: 52, showsCaption: false)
                    }
                    metricBlocks
                }
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(selected ? Color.accentColor.opacity(0.07) : Color.secondary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(selected ? Color.accentColor : Color.secondary.opacity(0.08),
                        lineWidth: selected ? 1.5 : 1)
        )
        .shadow(color: selected ? Color.accentColor.opacity(0.16) : .clear, radius: 8, y: 3)
        .contentShape(Rectangle())
    }

    private var avatar: some View {
        Avatar(seed: intel.coach.avatarSeed, label: intel.coach.initials,
               size: 54, urlString: intel.coach.avatarURL)
            .overlay(Circle().stroke(intel.grade.branchTint.opacity(0.6), lineWidth: 2))
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(intel.onLeave ? Color.orange : Color.secondaryAccent)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.cardBackground, lineWidth: 2))
            }
    }

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: intel.coach.fullName)
                .scaledFont(.subheadline, weight: .bold)
                .lineLimit(1)
            HStack(spacing: 5) {
                Text(verbatim: intel.branchName)
                Text(verbatim: "·")
                Text(verbatim: String(format: NSLocalizedString("coach.dan.fmt", comment: ""),
                                       intel.coach.danRank))
                    .environment(\.layoutDirection, .leftToRight)
                Text(verbatim: "·")
                Text(verbatim: String(format: NSLocalizedString("coach.years.fmt", comment: ""),
                                       intel.experienceYears))
                    .environment(\.layoutDirection, .leftToRight)
            }
            .scaledFont(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            statusChips.padding(.top, 1)
        }
    }

    private var statusChips: some View {
        HStack(spacing: 5) {
            if intel.isHeadCoach {
                CoachStatusChip(titleKey: "coach.chip.head", tint: .accentColor,
                                systemIcon: "star.circle.fill")
            } else {
                CoachStatusChip(titleKey: "coach.chip.assistant", tint: .purple,
                                systemIcon: "person.fill")
            }
            if intel.isElite {
                CoachStatusChip(titleKey: "coach.chip.elite", tint: .secondaryAccent,
                                systemIcon: "rosette")
            }
            if intel.onLeave {
                CoachStatusChip(titleKey: "coach.chip.on_leave", tint: .orange,
                                systemIcon: "moon.fill")
            }
        }
    }

    private var metricBlocks: some View {
        HStack(spacing: 8) {
            CoachMetricBlock(value: "\(intel.athleteCount)",
                             labelKey: "coach.metric.athletes")
            CoachMetricBlock(value: "\(intel.sessionsPerWeek)",
                             labelKey: "coach.metric.sessions_week")
            CoachMetricBlock(value: "\(Int(intel.attendancePct.rounded()))%",
                             labelKey: "coach.metric.attendance",
                             tint: intel.attendancePct >= 90 ? .secondaryAccent : .primary)
        }
    }
}

// MARK: - Preview panel

/// iPad right-side coach preview — photo, vitals, coaching radar,
/// certifications, recent activity and a link to the full profile.
public struct CoachPreviewPanel: View {
    private let intel: CoachIntel
    private let onViewProfile: () -> Void

    public init(intel: CoachIntel, onViewProfile: @escaping () -> Void) {
        self.intel = intel
        self.onViewProfile = onViewProfile
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                vitalsRow
                radarSection
                certificationsSection
                activitySection
                Button(action: onViewProfile) {
                    Text("coach.view_profile")
                        .scaledFont(.subheadline, weight: .semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(Color.accentColor)
                        .background(Color.accentColor.opacity(0.10),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.accentColor.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(18)
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(Color.secondary.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
        .id(intel.id)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Avatar(seed: intel.coach.avatarSeed, label: intel.coach.initials,
                   size: 64, urlString: intel.coach.avatarURL)
                .overlay(Circle().stroke(intel.grade.branchTint.opacity(0.6), lineWidth: 2))
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: intel.coach.fullName)
                    .scaledFont(.headline, weight: .bold)
                Text(verbatim: intel.branchName)
                    .scaledFont(.caption).foregroundStyle(.secondary)
                HStack(spacing: 5) {
                    Text(verbatim: String(format: NSLocalizedString("coach.dan.fmt", comment: ""),
                                           intel.coach.danRank))
                    Text(verbatim: "·")
                    Text(verbatim: String(format: NSLocalizedString("coach.years.fmt", comment: ""),
                                           intel.experienceYears))
                }
                .scaledFont(.caption2).foregroundStyle(.tertiary)
                .environment(\.layoutDirection, .leftToRight)
            }
            Spacer(minLength: 0)
            CoachGradeRing(grade: intel.grade, score: intel.composite, size: 60, showsCaption: false)
        }
    }

    private var vitalsRow: some View {
        HStack(spacing: 10) {
            vital("calendar", "coach.vital.age",
                  intel.coach.age.map { "\($0)" } ?? "—")
            vital("person.fill", "coach.vital.gender",
                  intel.coach.gender.map { NSLocalizedString("gender.\($0.rawValue)", comment: "") } ?? "—")
            vital("clock.badge.checkmark", "coach.vital.joined",
                  intel.coach.hiredAt.formatted(.dateTime.year()))
            vital("circle.fill", "coach.vital.status",
                  NSLocalizedString(intel.coach.employmentStatus.labelKey, comment: ""))
        }
    }

    private func vital(_ icon: String, _ labelKey: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon).scaledFont(.caption2).foregroundStyle(.secondary)
                Text(localizedKey: labelKey).scaledFont(.caption2).foregroundStyle(.secondary)
            }
            Text(verbatim: value)
                .scaledFont(.subheadline, weight: .bold)
                .lineLimit(1)
                .environment(\.layoutDirection, .leftToRight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9).padding(.vertical, 8)
        .background(Color.secondary.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var radarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("coach.performance_overview")
                .scaledFont(.subheadline, weight: .semibold)
            CoachRadarChart(scores: intel.radar, tint: intel.grade.branchTint)
        }
    }

    private var certificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("coach.certifications")
                .scaledFont(.subheadline, weight: .semibold)
            VStack(spacing: 8) {
                ForEach(certifications, id: \.0) { titleKey, expiry in
                    CoachCertificationRow(titleKey: titleKey, expiry: expiry)
                }
            }
        }
    }

    private var certifications: [(String, Date?)] {
        var out: [(String, Date?)] = [
            ("coach.cert.wt_licence", intel.coach.wtCoachLicenceExpiry),
            ("coach.cert.first_aid", intel.coach.firstAidExpiry),
            ("coach.cert.safeguarding", intel.coach.safeguardingExpiry),
        ]
        if let anti = intel.coach.antiDopingExpiry {
            out.append(("coach.cert.anti_doping", anti))
        }
        return out
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("coach.recent_activity")
                .scaledFont(.subheadline, weight: .semibold)
            VStack(spacing: 8) {
                ForEach(intel.recentActivity) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.kind.systemIcon)
                            .scaledFont(.subheadline)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(localizedKey: item.kind.labelKey)
                                .scaledFont(.caption, weight: .semibold)
                            Text(verbatim: item.dateText)
                                .scaledFont(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
}

// MARK: - Certification row

/// One certification line — kind icon, name, expiry metadata, severity color.
public struct CoachCertificationRow: View {
    private let titleKey: String
    private let expiry: Date?

    public init(titleKey: String, expiry: Date?) {
        self.titleKey = titleKey
        self.expiry = expiry
    }

    private var daysToExpiry: Int? {
        expiry.map { Calendar.current.dateComponents([.day], from: Date(), to: $0).day ?? 0 }
    }

    private var tint: Color {
        guard let d = daysToExpiry else { return .secondary }
        if d < 0 { return .red }
        if d < 60 { return .orange }
        return .secondaryAccent
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: tint == .secondaryAccent ? "checkmark.seal.fill"
                  : "exclamationmark.triangle.fill")
                .scaledFont(.subheadline)
                .foregroundStyle(tint)
            Text(localizedKey: titleKey)
                .scaledFont(.caption, weight: .semibold)
            Spacer(minLength: 0)
            if let expiry {
                Text(verbatim: String(
                    format: NSLocalizedString("coach.cert.expires.fmt", comment: ""),
                    expiry.formatted(.dateTime.month(.abbreviated).year())))
                    .scaledFont(.caption2)
                    .foregroundStyle(tint)
                    .environment(\.layoutDirection, .leftToRight)
            } else {
                Text("coach.cert.missing")
                    .scaledFont(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 11).padding(.vertical, 9)
        .background(Color.secondary.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Coaching radar chart

/// Hand-drawn 6-axis coaching radar — Teaching / Leadership / Performance /
/// Technical / Discipline / Attendance. Soft gradient fill over a faint grid.
public struct CoachRadarChart: View {
    private let scores: [CoachMetricScore]
    private let tint: Color
    private let rings = 4

    public init(scores: [CoachMetricScore], tint: Color) {
        self.scores = scores
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = side / 2 * 0.66
            ZStack {
                grid(center: center, radius: radius)
                valuePolygon(center: center, radius: radius)
                axisLabels(center: center, radius: radius)
            }
        }
        .aspectRatio(1.25, contentMode: .fit)
        .frame(maxHeight: 210)
        .environment(\.layoutDirection, .leftToRight)
    }

    private var count: Int { max(3, scores.count) }

    private func vertex(_ i: Int, fraction: CGFloat, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = -CGFloat.pi / 2 + CGFloat(i) / CGFloat(count) * 2 * .pi
        return CGPoint(x: center.x + cos(angle) * radius * fraction,
                       y: center.y + sin(angle) * radius * fraction)
    }

    private func grid(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            ForEach(1...rings, id: \.self) { ring in
                ringPath(center: center, radius: radius,
                         fraction: CGFloat(ring) / CGFloat(rings))
                    .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
            }
            ForEach(0..<count, id: \.self) { i in
                Path { p in
                    p.move(to: center)
                    p.addLine(to: vertex(i, fraction: 1, center: center, radius: radius))
                }
                .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
            }
        }
    }

    private func ringPath(center: CGPoint, radius: CGFloat, fraction: CGFloat) -> Path {
        Path { p in
            for i in 0..<count {
                let pt = vertex(i, fraction: fraction, center: center, radius: radius)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
    }

    private func valuePolygon(center: CGPoint, radius: CGFloat) -> some View {
        let path = Path { p in
            for i in 0..<count {
                let frac = CGFloat(min(100, max(0, scores[i].score)) / 100)
                let pt = vertex(i, fraction: frac, center: center, radius: radius)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
        return ZStack {
            path.fill(LinearGradient(colors: [tint.opacity(0.34), tint.opacity(0.12)],
                                     startPoint: .top, endPoint: .bottom))
            path.stroke(tint, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
            ForEach(0..<count, id: \.self) { i in
                let frac = CGFloat(min(100, max(0, scores[i].score)) / 100)
                Circle()
                    .fill(tint)
                    .frame(width: 6, height: 6)
                    .position(vertex(i, fraction: frac, center: center, radius: radius))
            }
        }
    }

    private func axisLabels(center: CGPoint, radius: CGFloat) -> some View {
        ForEach(0..<count, id: \.self) { i in
            let pt = vertex(i, fraction: 1.22, center: center, radius: radius)
            VStack(spacing: 0) {
                Text(localizedKey: scores[i].kind.labelKey)
                    .scaledFont(.caption2, weight: .semibold)
                    .foregroundStyle(.secondary)
                Text(verbatim: "\(Int(scores[i].score.rounded()))")
                    .scaledFont(.caption2, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(scores[i].kind.tint)
            }
            .fixedSize()
            .position(pt)
        }
    }
}

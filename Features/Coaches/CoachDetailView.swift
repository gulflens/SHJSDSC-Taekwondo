import SwiftUI

/// Federation-grade coach profile. Header + 8-tab module, adapts to
/// iPhone (single-column, sticky header) and iPad landscape (multi-column,
/// higher data density). Mirrors `AthleteDetailView` so the two profile
/// modules feel like one ecosystem.
public struct CoachDetailView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var coach: Coach
    @State private var selectedTab: ProfileTab = .overview

    // Loaded by `load()`
    @State private var allBranches: [Branch] = []
    @State private var assignedAthletes: [Athlete] = []
    @State private var coachMatches: [Match] = []
    @State private var certifications: [Certification] = []
    @State private var sessions: [ClassSession] = []
    @State private var tournamentLookup: [EntityID: Tournament] = [:]
    @State private var upcomingTournaments: [Tournament] = []

    @State private var showingEdit = false
    @State private var coachNoteTarget: CoachNoteTarget?

    private struct CoachNoteTarget: Identifiable {
        let editing: CoachNote?
        var id: String { editing?.id.uuidString ?? "new-coach-note" }
    }

    public enum ProfileTab: String, CaseIterable, Identifiable, Hashable {
        case overview, athletes, performance, attendance, competitions, certifications, reports, more

        public var id: String { rawValue }
        public var title: String {
            NSLocalizedString("coach.tab.\(rawValue)", comment: "")
        }
        public var systemIcon: String {
            switch self {
            case .overview: "rectangle.grid.2x2.fill"
            case .athletes: "person.3.fill"
            case .performance: "chart.line.uptrend.xyaxis"
            case .attendance: "calendar.badge.checkmark"
            case .competitions: "trophy.fill"
            case .certifications: "checkmark.seal.fill"
            case .reports: "doc.text.fill"
            case .more: "ellipsis.circle.fill"
            }
        }
    }

    public init(coach: Coach) {
        _coach = State(initialValue: coach)
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                CoachProfileHeader(
                    coach: coach,
                    primaryBranchName: primaryBranchName,
                    isWide: isWide,
                    onEditPhoto: { showingEdit = true }
                )
                if !coach.missingProfileFields.isEmpty {
                    profileCompletenessBanner
                }
                tabBar
                Group {
                    switch selectedTab {
                    case .overview:
                        CoachOverviewTab(
                            coach: coach,
                            primaryBranchName: primaryBranchName,
                            assignedAthletes: assignedAthletes,
                            coachMatches: coachMatches,
                            certifications: certifications,
                            upcomingTournaments: upcomingTournaments,
                            isWide: isWide
                        )
                    case .athletes:
                        VStack(spacing: 14) {
                            CoachAthletesTab(athletes: assignedAthletes, isWide: isWide)
                            CoachSupervisionPanel(coach: coach, isWide: isWide)
                        }
                    case .performance:
                        CoachPerformanceTab(
                            coach: coach,
                            assignedAthletes: assignedAthletes,
                            coachMatches: coachMatches,
                            isWide: isWide
                        )
                    case .attendance:
                        CoachAttendanceTab(coach: coach, sessions: sessions, isWide: isWide)
                    case .competitions:
                        CoachCompetitionsTab(
                            coach: coach,
                            coachMatches: coachMatches,
                            tournaments: tournamentLookup,
                            isWide: isWide
                        )
                    case .certifications:
                        CoachCertificationsTab(
                            coach: coach,
                            certifications: certifications,
                            isWide: isWide
                        )
                    case .reports:
                        CoachReportsTab(coach: coach, isWide: isWide)
                    case .more:
                        CoachMoreTab(
                            coach: coach,
                            primaryBranchName: primaryBranchName,
                            secondaryBranchNames: secondaryBranchNames,
                            isWide: isWide
                        )
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.18), value: selectedTab)
            }
            .padding(.horizontal, isWide ? 20 : 14)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .subviewChrome(Text(verbatim: coach.fullName)) {
            if canEditCoach {
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel(Text("coach.edit"))
            }
        }
        .navigationDestination(isPresented: $showingEdit) {
            AddCoachView(initialBranchID: coach.primaryBranchID, editing: coach) { updated in
                coach = updated
            }
        }
        .sheet(item: $coachNoteTarget) { target in
            CoachNoteEditor(editing: target.editing) { note in
                Task { await saveCoachNote(note) }
            }
        }
        .task { await load() }
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        SegmentedTabBar(
            selection: $selectedTab,
            tabs: ProfileTab.allCases,
            title: { $0.title },
            icon: { $0.systemIcon }
        )
        .padding(.vertical, 4)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 8, y: 3)
    }

    // MARK: - Profile completeness banner

    private var profileCompletenessBanner: some View {
        let missing = coach.missingProfileFields
        let pct = Int((coach.profileCompleteness * 100).rounded())
        return HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("coach.profile_incomplete")
                    .scaledFont(.footnote, weight: .semibold)
                Text(verbatim: String(format: NSLocalizedString("coach.profile_completeness", comment: ""), pct, missing.count))
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if canEditCoach {
                Button {
                    showingEdit = true
                } label: {
                    Text("coach.complete_profile")
                        .scaledFont(.caption, weight: .semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15), in: Capsule())
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.orange.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var isWide: Bool { sizeClass == .regular }

    private var primaryBranchName: String? {
        allBranches.first { $0.id == coach.primaryBranchID }?.name
    }

    private var secondaryBranchNames: [String] {
        coach.secondaryBranchIDs.compactMap { id in
            allBranches.first { $0.id == id }?.name
        }
    }

    private var canEditCoach: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editCoach)
    }

    // MARK: - Data load

    private func load() async {
        do {
            async let branchesTask = session.repository.branches()
            async let athletesTask = session.repository.athletes(coachID: coach.id)
            async let certsTask = session.repository.certifications(coachID: coach.id)
            async let tournamentsTask = session.repository.tournaments()

            allBranches = try await branchesTask
            assignedAthletes = try await athletesTask
            certifications = try await certsTask
            let allTournaments = try await tournamentsTask
            let now = Date()
            upcomingTournaments = allTournaments
                .filter { $0.startsAt > now }
                .sorted { $0.startsAt < $1.startsAt }

            // Sessions for the last 12 weeks across all the coach's branches.
            let cal = Calendar.current
            let startDate = cal.date(byAdding: .day, value: -84, to: now) ?? now
            var collected: [ClassSession] = []
            var day = startDate
            while day <= now {
                if let next = cal.date(byAdding: .day, value: 1, to: day) {
                    let coachSessions = (try? await session.repository.sessions(coachID: coach.id, on: day)) ?? []
                    collected.append(contentsOf: coachSessions)
                    day = next
                } else {
                    break
                }
            }
            // Also collect upcoming sessions for the next 4 weeks
            day = now
            let upcomingEnd = cal.date(byAdding: .day, value: 28, to: now) ?? now
            while day <= upcomingEnd {
                if let next = cal.date(byAdding: .day, value: 1, to: day) {
                    let coachSessions = (try? await session.repository.sessions(coachID: coach.id, on: day)) ?? []
                    collected.append(contentsOf: coachSessions)
                    day = next
                } else {
                    break
                }
            }
            sessions = Array(Set(collected.map { $0.id })).compactMap { id in
                collected.first { $0.id == id }
            }

            // Matches across all assigned athletes.
            var allMatches: [Match] = []
            var tournamentMap: [EntityID: Tournament] = [:]
            for athlete in assignedAthletes {
                if let athleteMatches = try? await session.repository.matches(athleteID: athlete.id) {
                    allMatches.append(contentsOf: athleteMatches)
                    for m in athleteMatches {
                        if let tid = m.tournamentID,
                           tournamentMap[tid] == nil,
                           let t = try? await session.repository.tournament(id: tid) {
                            tournamentMap[tid] = t
                        }
                    }
                }
            }
            coachMatches = allMatches
            tournamentLookup = tournamentMap
        } catch {
            print("CoachDetailView.load:", error)
        }
    }

    private func saveCoachNote(_ note: CoachNote) async {
        var updated = coach
        if let idx = updated.coachNotes.firstIndex(where: { $0.id == note.id }) {
            updated.coachNotes[idx] = note
        } else {
            updated.coachNotes.append(note)
        }
        coach = updated
        do {
            try await session.repository.upsert(updated)
        } catch {
            print("CoachDetailView.saveCoachNote:", error)
        }
    }
}

import SwiftUI

/// Federation-grade athlete profile. Header + 8-tab module, adapts to
/// iPhone (single-column, sticky header) and iPad landscape (multi-column,
/// higher data density).
///
/// State strategy: this container owns the data loads (matches, scores,
/// physical metrics, attendance, training load, registrations, tournaments,
/// branches, coach, parent users) and passes pre-shaped slices down to each
/// tab. Tabs are pure presentation; mutations go through this view's
/// `repository.upsert(_:)` path so the model stays the single source of truth.
public struct AthleteDetailView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var athlete: Athlete
    @State private var selectedTab: ProfileTab = .overview

    // Loaded by `load()`
    @State private var branches: [Branch] = []
    @State private var coachName: String?
    @State private var parentUsers: [User] = []
    @State private var score: PerformanceScore?
    @State private var scoreHistory: [PerformanceScore] = []
    @State private var physicalMetrics: [PhysicalMetric] = []
    @State private var attendance: [AttendanceRecord] = []
    @State private var trainingLoad: [TrainingLoadEntry] = []
    @State private var matches: [Match] = []
    @State private var registrations: [TournamentRegistration] = []
    @State private var tournamentLookup: [EntityID: Tournament] = [:]

    @State private var showingEdit = false
    @State private var sparringTarget: SparringTarget?
    @State private var coachNoteTarget: CoachNoteTarget?
    @State private var documentTarget: DocumentTarget?

    private struct SparringTarget: Identifiable {
        let editing: Match?
        var id: String { editing?.id.uuidString ?? "new" }
    }

    private struct CoachNoteTarget: Identifiable {
        let editing: CoachNote?
        var id: String { editing?.id.uuidString ?? "new-coach-note" }
    }

    private struct DocumentTarget: Identifiable {
        let editing: AthleteDocument?
        var id: String { editing?.id.uuidString ?? "new-document" }
    }

    public enum ProfileTab: String, CaseIterable, Identifiable, Hashable {
        case overview, performance, attendance, competitions, medical, documents, coachNotes, more

        public var id: String { rawValue }
        /// Pre-resolved human title. NSLocalizedString returns the value from
        /// the xcstrings catalogue for keys built from interpolation.
        public var title: String {
            NSLocalizedString("athlete.tab.\(rawValue)", comment: "")
        }
        public var systemIcon: String {
            switch self {
            case .overview: "rectangle.grid.2x2.fill"
            case .performance: "chart.line.uptrend.xyaxis"
            case .attendance: "calendar.badge.checkmark"
            case .competitions: "trophy.fill"
            case .medical: "cross.case.fill"
            case .documents: "doc.text.fill"
            case .coachNotes: "text.bubble.fill"
            case .more: "ellipsis.circle.fill"
            }
        }
    }

    public init(athlete: Athlete) {
        _athlete = State(initialValue: athlete)
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                AthleteProfileHeader(
                    athlete: athlete,
                    branchName: currentBranchName,
                    isWide: isWide,
                    onEditPhoto: { showingEdit = true }
                )
                if !athlete.missingProfileFields.isEmpty {
                    profileCompletenessBanner
                }
                tabBar
                Group {
                    switch selectedTab {
                    case .overview:
                        AthleteOverviewTab(
                            athlete: athlete,
                            branchName: currentBranchName,
                            coachName: coachName,
                            score: score,
                            scoreHistory: scoreHistory,
                            physicalMetrics: physicalMetrics,
                            attendance: attendance,
                            trainingLoad: trainingLoad,
                            matches: matches,
                            registrations: registrations,
                            tournaments: tournamentLookup,
                            isWide: isWide
                        )
                    case .performance:
                        AthletePerformanceTab(athlete: $athlete, isWide: isWide)
                    case .attendance:
                        AthleteAttendanceTab(
                            athlete: athlete,
                            attendance: attendance,
                            trainingLoad: trainingLoad,
                            matches: matches,
                            isWide: isWide
                        )
                    case .competitions:
                        AthleteCompetitionsTab(
                            athlete: athlete,
                            matches: matches,
                            registrations: registrations,
                            tournaments: tournamentLookup,
                            isWide: isWide,
                            onOpenSparring: { match in
                                guard canEditAthlete else { return }
                                sparringTarget = SparringTarget(editing: match)
                            }
                        )
                    case .medical:
                        AthleteMedicalTab(athlete: $athlete, isWide: isWide)
                    case .documents:
                        AthleteDocumentsTab(athlete: athlete, canEdit: canEditAthlete) {
                            documentTarget = DocumentTarget(editing: nil)
                        }
                    case .coachNotes:
                        AthleteCoachNotesTab(athlete: athlete, canEdit: canEditAthlete) {
                            coachNoteTarget = CoachNoteTarget(editing: nil)
                        }
                    case .more:
                        AthleteMoreTab(athlete: $athlete, parentUsers: parentUsers, isWide: isWide)
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
        .navigationTitle(Text(verbatim: athlete.fullName))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if let role = session.currentUser?.role,
               PermissionMatrix.allowed(role: role, permission: .exportReports) {
                ToolbarItem(placement: .primaryAction) {
                    ExportButton(
                        baseFilename: "athlete-\(athlete.fullName.replacingOccurrences(of: " ", with: "_"))",
                        csvProvider: {
                            CSVReportExporter().exportAthletes([athlete], format: .csv)
                        }
                    )
                }
            }
            if canEditAthlete {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEdit = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel(Text("athlete.edit"))
                    .bareToolbarButton()
                }
            }
        }
        .navigationDestination(isPresented: $showingEdit) {
            AddAthleteView(initialBranchID: athlete.branchID, editing: athlete) { updated in
                athlete = updated
            }
        }
        .sheet(item: $sparringTarget) { target in
            NavigationStack {
                SparringLogEditorView(athlete: athlete, editing: target.editing) { _ in
                    Task { await load() }
                }
            }
        }
        .sheet(item: $coachNoteTarget) { target in
            CoachNoteEditor(editing: target.editing) { note in
                Task { await saveCoachNote(note) }
            }
        }
        .sheet(item: $documentTarget) { target in
            DocumentEditor(editing: target.editing) { doc in
                Task { await saveDocument(doc) }
            }
        }
        .task { await load() }
    }

    private func saveCoachNote(_ note: CoachNote) async {
        var updated = athlete
        if let idx = updated.coachNotes.firstIndex(where: { $0.id == note.id }) {
            updated.coachNotes[idx] = note
        } else {
            updated.coachNotes.append(note)
        }
        athlete = updated
        do {
            try await session.repository.upsert(updated)
        } catch {
            print("AthleteDetailView.saveCoachNote:", error)
        }
    }

    private func saveDocument(_ doc: AthleteDocument) async {
        var updated = athlete
        if let idx = updated.documents.firstIndex(where: { $0.id == doc.id }) {
            updated.documents[idx] = doc
        } else {
            updated.documents.append(doc)
        }
        athlete = updated
        do {
            try await session.repository.upsert(updated)
        } catch {
            print("AthleteDetailView.saveDocument:", error)
        }
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

    // MARK: - Completeness banner (compact pill, sits above tab bar)

    private var profileCompletenessBanner: some View {
        let missing = athlete.missingProfileFields
        let pct = Int((athlete.profileCompleteness * 100).rounded())
        return HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("athlete.profile_incomplete")
                    .scaledFont(.footnote, weight: .semibold)
                Text(verbatim: String(format: NSLocalizedString("athlete.profile_completeness", comment: ""), pct, missing.count))
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if canEditAthlete {
                Button {
                    showingEdit = true
                } label: {
                    Text("athlete.complete_profile")
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

    private var currentBranchName: String? {
        branches.first { $0.id == athlete.branchID }?.name
    }

    private var canEditAthlete: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editAthlete)
    }

    // MARK: - Data load

    private func load() async {
        do {
            async let branchesTask = session.repository.branches()
            async let matchesTask = session.repository.matches(athleteID: athlete.id)
            async let scoreTask = session.repository.score(athleteID: athlete.id)
            async let scoreHistoryTask = session.repository.scoreHistory(athleteID: athlete.id)
            async let physicalTask = session.repository.physicalMetrics(athleteID: athlete.id)
            async let registrationsTask = session.repository.registrations(athleteID: athlete.id)
            let monthsBack = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
            async let attendanceTask = session.repository.attendance(athleteID: athlete.id, since: monthsBack)
            async let trainingLoadTask = session.repository.trainingLoad(athleteID: athlete.id, since: monthsBack)

            branches = try await branchesTask
            matches = try await matchesTask
            score = try await scoreTask
            scoreHistory = try await scoreHistoryTask
            physicalMetrics = try await physicalTask
            registrations = try await registrationsTask
            attendance = try await attendanceTask
            trainingLoad = try await trainingLoadTask

            if let coachID = athlete.primaryCoachID,
               let coach = try await session.repository.coach(id: coachID) {
                coachName = coach.fullName
            } else {
                coachName = nil
            }

            var lookup: [EntityID: Tournament] = [:]
            for r in registrations {
                if lookup[r.tournamentID] == nil,
                   let t = try await session.repository.tournament(id: r.tournamentID) {
                    lookup[r.tournamentID] = t
                }
            }
            tournamentLookup = lookup

            var loaded: [User] = []
            for parentID in athlete.parentUserIDs {
                if let u = try await session.repository.user(id: parentID) {
                    loaded.append(u)
                }
            }
            parentUsers = loaded
        } catch {
            print("AthleteDetailView.load:", error)
        }
    }
}

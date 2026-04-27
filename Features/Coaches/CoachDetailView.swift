import SwiftUI

public struct CoachDetailView: View {
    @Environment(AppSession.self) private var session
    @State private var coach: Coach
    @State private var primaryBranch: Branch?
    @State private var secondaryBranches: [Branch] = []
    @State private var assignedAthletes: Int = 0
    @State private var classesThisWeek: Int = 0
    @State private var medalsThisYear: Int = 0
    @State private var promotionsThisYear: Int = 0
    @State private var showingEdit = false

    public init(coach: Coach) {
        _coach = State(initialValue: coach)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                if !coach.missingProfileFields.isEmpty {
                    profileWarningBanner
                }
                kpiGrid
                credentialsSection
                assignmentSection
                performanceSection
                if let bio = coach.bio, !bio.isEmpty {
                    bioSection(bio)
                }
            }
            .padding()
        }
        .navigationDestination(isPresented: $showingEdit) {
            AddCoachView(initialBranchID: coach.primaryBranchID, editing: coach) { updated in
                coach = updated
            }
        }
        .navigationTitle(Text(verbatim: coach.fullName))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if let role = session.currentUser?.role,
               PermissionMatrix.allowed(role: role, permission: .editCoach) {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("coach.edit", systemImage: "pencil")
                    }
                }
            }
        }
        .task { await load() }
    }

    private var hero: some View {
        HStack(spacing: 16) {
            Avatar(seed: coach.avatarSeed, label: coach.initials, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: coach.fullName).font(.title2.bold())
                Text(verbatim: coach.fullNameAr).font(.body).foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Text(verbatim: "\(coach.danRank) Dan")
                        .font(.caption.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                    Text(LocalizedStringKey(coach.contractType.labelKey))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if coach.onCall {
                        Label("coach.on_call", systemImage: "bell.badge.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                }
            }
            Spacer()
        }
    }

    private var profileWarningBanner: some View {
        let missing = coach.missingProfileFields
        let pct = Int((coach.profileCompleteness * 100).rounded())
        let canEdit = (session.currentUser?.role).map {
            PermissionMatrix.allowed(role: $0, permission: .editCoach)
        } ?? false
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("coach.profile_incomplete").font(.subheadline.bold())
                    Text(verbatim: String(format: NSLocalizedString("coach.profile_completeness", comment: ""), pct, missing.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            ProgressView(value: coach.profileCompleteness)
                .tint(.orange)
            VStack(alignment: .leading, spacing: 3) {
                ForEach(missing, id: \.self) { key in
                    HStack(spacing: 6) {
                        Image(systemName: "circle").font(.caption2).foregroundStyle(.secondary)
                        Text(LocalizedStringKey(key)).font(.caption)
                    }
                }
            }
            if canEdit {
                Button {
                    showingEdit = true
                } label: {
                    Label("coach.complete_profile", systemImage: "pencil")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var kpiGrid: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 10) {
            KPITile(title: "coach.athletes_managed", value: "\(assignedAthletes)", icon: "person.3.fill")
            KPITile(title: "coach.classes_this_week", value: "\(classesThisWeek)", icon: "calendar")
            KPITile(title: "coach.athletes_promoted_year", value: "\(promotionsThisYear)", icon: "rosette")
            KPITile(title: "coach.medals_this_year", value: "\(medalsThisYear)", icon: "medal.fill")
        }
    }

    // MARK: - Credentials

    private var credentialsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "checkmark.seal.fill", title: "coach.section.credentials")
            VStack(alignment: .leading, spacing: 6) {
                credentialRow(label: "coach.kukkiwon_cert", value: coach.kukkiwonCertNumber, expiry: nil)
                credentialRow(label: "coach.wt_coach_licence", value: "L\(coach.wtCoachLicenceLevel)", expiry: coach.wtCoachLicenceExpiry)
                credentialRow(label: "coach.poomsae_referee",
                              value: coach.poomsaeRefereeLevel.map { "Class \($0)" },
                              expiry: coach.poomsaeRefereeExpiry)
                credentialRow(label: "coach.kyorugi_referee",
                              value: coach.kyorugiRefereeLevel.map { "Class \($0)" },
                              expiry: coach.kyorugiRefereeExpiry)
                credentialRow(label: "coach.first_aid_expiry", value: nil, expiry: coach.firstAidExpiry)
                credentialRow(label: "coach.safeguarding_expiry", value: nil, expiry: coach.safeguardingExpiry)
                credentialRow(label: "coach.anti_doping_expiry", value: nil, expiry: coach.antiDopingExpiry)
            }
            .padding(12)
            .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func credentialRow(label: LocalizedStringKey, value: String?, expiry: Date?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            if let value, !value.isEmpty {
                Text(verbatim: value)
                    .font(.callout.bold())
                    .environment(\.layoutDirection, .leftToRight)
            }
            if let expiry {
                expiryPill(expiry)
            } else if value == nil {
                Text("coach.not_set").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private func expiryPill(_ expiry: Date) -> some View {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
        let tint: Color = days < 0 ? .red : (days < 60 ? .orange : .green)
        let labelKey: LocalizedStringKey = days < 0 ? "cert.severity.expired" : (days < 60 ? "cert.severity.expiring" : "cert.severity.ok")
        return HStack(spacing: 4) {
            Text(labelKey).font(.caption2.bold())
            Text(expiry, style: .date).font(.caption2.monospacedDigit())
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(tint.opacity(0.15), in: Capsule())
        .foregroundStyle(tint)
    }

    // MARK: - Assignment

    private var assignmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "building.2.fill", title: "coach.section.assignment")
            VStack(alignment: .leading, spacing: 6) {
                assignmentRow(label: "coach.primary_branch", value: primaryBranch?.name ?? "—")
                let secondaries = secondaryBranches.map(\.name).joined(separator: ", ")
                assignmentRow(label: "coach.secondary_branches",
                              value: secondaries.isEmpty ? "—" : secondaries)
                assignmentRow(label: "coach.weekly_hours",
                              value: coach.weeklyHoursTarget.map { "\($0) h" } ?? "—")
                assignmentRow(label: "coach.hired_at", value: dateFormatter.string(from: coach.hiredAt))
            }
            .padding(12)
            .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func assignmentRow(label: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(verbatim: value).font(.callout)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Performance

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "chart.bar.fill", title: "coach.section.performance")
            VStack(alignment: .leading, spacing: 6) {
                performanceRow(label: "coach.cpd_hours",
                               value: "\(Int(coach.cpdHoursThisYear)) h")
                performanceRow(label: "coach.parent_satisfaction",
                               rating: coach.parentSatisfactionAvg)
                performanceRow(label: "coach.peer_review",
                               rating: coach.peerReviewAvg)
                performanceRow(label: "coach.athletes_promoted_year",
                               value: "\(promotionsThisYear)")
                performanceRow(label: "coach.medals_this_year",
                               value: "\(medalsThisYear)")
            }
            .padding(12)
            .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func performanceRow(label: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(verbatim: value)
                .font(.callout.monospacedDigit())
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.vertical, 2)
    }

    private func performanceRow(label: LocalizedStringKey, rating: Double?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            if let rating {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: starName(for: i, rating: rating))
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                    Text(verbatim: String(format: " %.1f", rating))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .environment(\.layoutDirection, .leftToRight)
                }
            } else {
                Text("coach.not_set").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private func starName(for index: Int, rating: Double) -> String {
        let v = rating - Double(index)
        if v >= 1 { return "star.fill" }
        if v >= 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }

    // MARK: - Bio

    private func bioSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "text.alignleft", title: "coach.bio")
            Text(verbatim: text)
                .font(.callout)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func sectionHeader(icon: String, title: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 6))
            Text(title).font(.subheadline.bold())
            Spacer()
        }
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }

    // MARK: - Load

    private func load() async {
        let repo = session.repository
        async let branchesTask = (try? await repo.branches()) ?? []
        async let athletesTask = (try? await repo.athletes(coachID: coach.id)) ?? []
        async let weekSessionsTask = loadWeekSessions(repo: repo)

        let (allBranches, athletes, weekClasses) = await (branchesTask, athletesTask, weekSessionsTask)
        let lookup = Dictionary(uniqueKeysWithValues: allBranches.map { ($0.id, $0) })
        primaryBranch = lookup[coach.primaryBranchID]
        secondaryBranches = coach.secondaryBranchIDs.compactMap { lookup[$0] }
        assignedAthletes = athletes.count
        classesThisWeek = weekClasses

        // Promotions & medals are best-effort, decorative KPIs — silently
        // swallow errors. "Promoted" = grading certificate signed by this
        // coach this calendar year. "Medals" = athletes-managed who earned
        // any medal (gold/silver/bronze) this year.
        let yearStart = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: Date())) ?? Date()
        var promos = 0
        var medals = 0
        for a in athletes {
            if let certs = try? await repo.certificates(athleteID: a.id) {
                promos += certs.filter { $0.signedByCoachIDs.contains(coach.id) && $0.awardedAt >= yearStart }.count
            }
            if let matches = try? await repo.matches(athleteID: a.id) {
                medals += matches.filter { $0.medal != .none && $0.date >= yearStart }.count
            }
        }
        promotionsThisYear = promos
        medalsThisYear = medals
    }

    private func loadWeekSessions(repo: Repository) async -> Int {
        let cal = Calendar.current
        let today = Date()
        let weekStart = cal.date(byAdding: .day, value: -((cal.component(.weekday, from: today)) - 1), to: today) ?? today
        var total = 0
        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            if let sessions = try? await repo.sessions(coachID: coach.id, on: day) {
                total += sessions.count
            }
        }
        return total
    }
}

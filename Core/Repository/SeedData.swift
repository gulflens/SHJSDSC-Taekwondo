import Foundation

public struct SeedBundle: Sendable {
    public let users: [User]
    public let branches: [Branch]
    public let coaches: [Coach]
    public let athletes: [Athlete]
    public let sessions: [ClassSession]
    public let attendance: [AttendanceRecord]
    public let scores: [PerformanceScore]
    public let matches: [Match]
    public let physicalTests: [PhysicalTest]
    public let assessments: [TechnicalAssessment]
    public let wellness: [WellnessEntry]
    public let gradingSessions: [GradingSession]
    public let gradingScores: [GradingScore]
    public let certificates: [GradingCertificate]
    public let defaultCurrentUserID: EntityID
}

public enum SeedData {

    public static func build() -> SeedBundle {
        let now = Date()
        let cal = Calendar.current

        func days(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: now) ?? now }
        func years(_ n: Int) -> Date { cal.date(byAdding: .year, value: n, to: now) ?? now }
        func dob(age: Int) -> Date { cal.date(byAdding: .year, value: -age, to: now) ?? now }
        func monthsAgo(_ n: Int) -> Date { cal.date(byAdding: .month, value: -n, to: now) ?? now }

        // === Non-coach users ===
        let userAdmin = User(fullName: "Hanadi Al Kabouri", fullNameAr: "هنادي الكعبوري", role: .admin, avatarSeed: "hanadi")
        let userTD = User(fullName: "Dr Ali Alawi", fullNameAr: "د. علي العلوي", role: .technicalDirector, avatarSeed: "ali")
        let userManager = User(fullName: "Osama Al-Radini", fullNameAr: "أسامة الرديني", role: .branchManager, avatarSeed: "osama")
        let userParent = User(fullName: "Mohammed Al Marzooqi", fullNameAr: "محمد المرزوقي", role: .parent, avatarSeed: "marzooqi")

        // === Branches ===
        let branchAlRamtha = Branch(code: "BR-A", name: "Al Ramtha", nameAr: "الرمثاء", area: "Sharjah", capacity: 80, managerID: userManager.id, focus: "fundamentals")
        let branchAlJazzat = Branch(code: "BR-B", name: "Al Jazzat", nameAr: "الجزات", area: "Sharjah", capacity: 60, focus: "competition")
        let branchAlKhan = Branch(code: "BR-C", name: "Al Khan", nameAr: "الخان", area: "Sharjah", capacity: 70, focus: "poomsae")
        let branchShaghrafa = Branch(code: "BR-D", name: "Shaghrafa", nameAr: "الشغرفة", area: "Sharjah", capacity: 50, focus: "girls only")
        let branches = [branchAlRamtha, branchAlJazzat, branchAlKhan, branchShaghrafa]

        // === Coaches ===
        let coachYassin = Coach(
            fullName: "Yassin Al-Jawadi", fullNameAr: "ياسين الجوادي",
            primaryBranchID: branchAlRamtha.id, secondaryBranchIDs: [branchAlJazzat.id],
            danRank: 4, wtCoachLicenceLevel: 2,
            firstAidExpiry: days(180), safeguardingExpiry: days(365),
            contractType: .fullTime, hiredAt: years(-5), avatarSeed: "yassin"
        )
        let coachMohammed = Coach(
            fullName: "Mohammed Bukhari", fullNameAr: "محمد بخاري",
            primaryBranchID: branchAlJazzat.id, secondaryBranchIDs: [],
            danRank: 5, wtCoachLicenceLevel: 3,
            firstAidExpiry: days(-15), safeguardingExpiry: days(120),
            contractType: .fullTime, hiredAt: years(-7), avatarSeed: "mohammed"
        )
        let coachAshraf = Coach(
            fullName: "Ashraf Abdul-Jalil", fullNameAr: "أشرف عبد الجليل",
            primaryBranchID: branchAlKhan.id, secondaryBranchIDs: [],
            danRank: 3, wtCoachLicenceLevel: 2,
            firstAidExpiry: days(60), safeguardingExpiry: days(60),
            contractType: .partTime, hiredAt: years(-3), avatarSeed: "ashraf"
        )
        let coachElias = Coach(
            fullName: "Elias Mansri", fullNameAr: "إلياس منصري",
            primaryBranchID: branchAlRamtha.id, secondaryBranchIDs: [branchAlKhan.id],
            danRank: 2, wtCoachLicenceLevel: 1,
            firstAidExpiry: days(300), safeguardingExpiry: days(300),
            contractType: .contractor, hiredAt: years(-2), avatarSeed: "elias"
        )
        let coachLayla = Coach(
            fullName: "Layla Al Suwaidi", fullNameAr: "ليلى السويدي",
            primaryBranchID: branchShaghrafa.id, secondaryBranchIDs: [],
            danRank: 4, wtCoachLicenceLevel: 2,
            firstAidExpiry: days(220), safeguardingExpiry: days(220),
            contractType: .fullTime, hiredAt: years(-4), avatarSeed: "layla"
        )
        let coaches = [coachYassin, coachMohammed, coachAshraf, coachElias, coachLayla]

        let userCoach = User(
            id: coachYassin.id,
            fullName: coachYassin.fullName, fullNameAr: coachYassin.fullNameAr,
            role: .coach, primaryBranchID: coachYassin.primaryBranchID, avatarSeed: coachYassin.avatarSeed
        )

        // === Belt helpers ===
        func belt(_ color: BeltColor, _ kind: BeltKind, _ number: Int, awardedDaysAgo: Int) -> Belt {
            Belt(color: color, kind: kind, number: number, awardedAt: days(-awardedDaysAgo))
        }

        // === Athletes ===
        let a1 = Athlete(
            fullName: "Ahmed Al Mazrouei", fullNameAr: "أحمد المزروعي",
            dateOfBirth: dob(age: 14), gender: .male,
            branchID: branchAlRamtha.id, primaryCoachID: coachYassin.id,
            joinedAt: years(-4), currentBelt: belt(.blue, .gup, 4, awardedDaysAgo: 80),
            beltHistory: [
                belt(.white, .gup, 10, awardedDaysAgo: 1300),
                belt(.yellow, .gup, 8, awardedDaysAgo: 1000),
                belt(.green, .gup, 6, awardedDaysAgo: 600),
                belt(.blue, .gup, 4, awardedDaysAgo: 80),
            ],
            weightKg: 48, status: .active, avatarSeed: "ahmed"
        )
        let a2 = Athlete(
            fullName: "Khalid bin Saif", fullNameAr: "خالد بن سيف",
            dateOfBirth: dob(age: 13), gender: .male,
            branchID: branchAlJazzat.id, primaryCoachID: coachMohammed.id,
            joinedAt: years(-3), currentBelt: belt(.green, .gup, 6, awardedDaysAgo: 200),
            beltHistory: [
                belt(.white, .gup, 10, awardedDaysAgo: 1100),
                belt(.yellow, .gup, 8, awardedDaysAgo: 700),
                belt(.green, .gup, 6, awardedDaysAgo: 200),
            ],
            weightKg: 44, status: .active, avatarSeed: "khalid"
        )
        let a3 = Athlete(
            fullName: "Saif Al Hammadi", fullNameAr: "سيف الحمادي",
            dateOfBirth: dob(age: 12), gender: .male,
            branchID: branchAlKhan.id, primaryCoachID: coachAshraf.id,
            joinedAt: years(-3), currentBelt: belt(.yellow, .gup, 8, awardedDaysAgo: 220),
            beltHistory: [
                belt(.white, .gup, 10, awardedDaysAgo: 1100),
                belt(.yellow, .gup, 8, awardedDaysAgo: 220),
            ],
            weightKg: 40, status: .readyToGrade, avatarSeed: "saif"
        )
        let a4 = Athlete(
            fullName: "Hamad Al Suwaidi", fullNameAr: "حمد السويدي",
            dateOfBirth: dob(age: 15), gender: .male,
            branchID: branchAlRamtha.id, primaryCoachID: coachYassin.id,
            joinedAt: years(-6), currentBelt: belt(.red, .gup, 2, awardedDaysAgo: 110),
            beltHistory: [
                belt(.white, .gup, 10, awardedDaysAgo: 2200),
                belt(.yellow, .gup, 8, awardedDaysAgo: 1800),
                belt(.green, .gup, 6, awardedDaysAgo: 1300),
                belt(.blue, .gup, 4, awardedDaysAgo: 700),
                belt(.red, .gup, 2, awardedDaysAgo: 110),
            ],
            weightKg: 56, status: .competitionTeam, avatarSeed: "hamad"
        )
        let a5 = Athlete(
            fullName: "Salem Al Marzouqi", fullNameAr: "سالم المرزوقي",
            dateOfBirth: dob(age: 11), gender: .male,
            branchID: branchAlJazzat.id, primaryCoachID: coachMohammed.id,
            joinedAt: years(-2), currentBelt: belt(.green, .gup, 6, awardedDaysAgo: 60),
            beltHistory: [
                belt(.white, .gup, 10, awardedDaysAgo: 720),
                belt(.yellow, .gup, 8, awardedDaysAgo: 400),
                belt(.green, .gup, 6, awardedDaysAgo: 60),
            ],
            weightKg: 36, status: .watch, avatarSeed: "salem"
        )
        let a6 = Athlete(
            fullName: "Rashid Al Falahi", fullNameAr: "راشد الفلاسي",
            dateOfBirth: dob(age: 16), gender: .male,
            branchID: branchAlKhan.id, primaryCoachID: coachAshraf.id,
            joinedAt: years(-7), currentBelt: belt(.black, .poom, 1, awardedDaysAgo: 90),
            beltHistory: [
                belt(.red, .gup, 2, awardedDaysAgo: 500),
                belt(.black, .poom, 1, awardedDaysAgo: 90),
            ],
            weightKg: 62, status: .competitionTeam, avatarSeed: "rashid"
        )
        let a7 = Athlete(
            fullName: "Mansour Al Ketbi", fullNameAr: "منصور الكتبي",
            dateOfBirth: dob(age: 10), gender: .male,
            branchID: branchAlRamtha.id, primaryCoachID: coachElias.id,
            joinedAt: years(-1), currentBelt: belt(.white, .gup, 10, awardedDaysAgo: 30),
            weightKg: 30, status: .active, avatarSeed: "mansour"
        )
        let a8 = Athlete(
            fullName: "Tariq Al Nuaimi", fullNameAr: "طارق النعيمي",
            dateOfBirth: dob(age: 13), gender: .male,
            branchID: branchAlJazzat.id, primaryCoachID: coachMohammed.id,
            joinedAt: years(-4), currentBelt: belt(.blue, .gup, 4, awardedDaysAgo: 200),
            beltHistory: [
                belt(.white, .gup, 10, awardedDaysAgo: 1500),
                belt(.yellow, .gup, 8, awardedDaysAgo: 1100),
                belt(.green, .gup, 6, awardedDaysAgo: 700),
                belt(.blue, .gup, 4, awardedDaysAgo: 200),
            ],
            weightKg: 46, status: .readyToGrade, avatarSeed: "tariq"
        )
        let a9 = Athlete(
            fullName: "Omar Al Shamsi", fullNameAr: "عمر الشامسي",
            dateOfBirth: dob(age: 14), gender: .male,
            branchID: branchAlKhan.id, primaryCoachID: coachAshraf.id,
            joinedAt: years(-5), currentBelt: belt(.red, .gup, 2, awardedDaysAgo: 130),
            beltHistory: [
                belt(.white, .gup, 10, awardedDaysAgo: 1800),
                belt(.yellow, .gup, 8, awardedDaysAgo: 1400),
                belt(.green, .gup, 6, awardedDaysAgo: 900),
                belt(.blue, .gup, 4, awardedDaysAgo: 500),
                belt(.red, .gup, 2, awardedDaysAgo: 130),
            ],
            weightKg: 50, status: .competitionTeam, avatarSeed: "omar"
        )
        let a10 = Athlete(
            fullName: "Yousef Al Tunaiji", fullNameAr: "يوسف التنيجي",
            dateOfBirth: dob(age: 12), gender: .male,
            branchID: branchAlRamtha.id, primaryCoachID: coachElias.id,
            joinedAt: years(-3), currentBelt: belt(.green, .gup, 6, awardedDaysAgo: 250),
            beltHistory: [
                belt(.white, .gup, 10, awardedDaysAgo: 1100),
                belt(.yellow, .gup, 8, awardedDaysAgo: 750),
                belt(.green, .gup, 6, awardedDaysAgo: 250),
            ],
            weightKg: 38, status: .active, avatarSeed: "yousef"
        )
        let a11 = Athlete(
            fullName: "Faisal Al Awani", fullNameAr: "فيصل العواني",
            dateOfBirth: dob(age: 9), gender: .male,
            branchID: branchAlJazzat.id, primaryCoachID: coachMohammed.id,
            joinedAt: years(-1), currentBelt: belt(.white, .gup, 10, awardedDaysAgo: 60),
            weightKg: 26, status: .active, avatarSeed: "faisal"
        )
        let a12 = Athlete(
            fullName: "Abdullah Al Mehairi", fullNameAr: "عبدالله المهيري",
            dateOfBirth: dob(age: 15), gender: .male,
            branchID: branchAlKhan.id, primaryCoachID: coachAshraf.id,
            joinedAt: years(-6), currentBelt: belt(.black, .poom, 1, awardedDaysAgo: 50),
            beltHistory: [
                belt(.red, .gup, 2, awardedDaysAgo: 400),
                belt(.black, .poom, 1, awardedDaysAgo: 50),
            ],
            weightKg: 58, status: .rest, avatarSeed: "abdullah"
        )

        let g1 = Athlete(
            fullName: "Maryam Al Suwaidi", fullNameAr: "مريم السويدي",
            dateOfBirth: dob(age: 13), gender: .female,
            branchID: branchShaghrafa.id, primaryCoachID: coachLayla.id,
            joinedAt: years(-4), currentBelt: belt(.blue, .gup, 4, awardedDaysAgo: 150),
            beltHistory: [
                belt(.white, .gup, 10, awardedDaysAgo: 1500),
                belt(.yellow, .gup, 8, awardedDaysAgo: 1100),
                belt(.green, .gup, 6, awardedDaysAgo: 700),
                belt(.blue, .gup, 4, awardedDaysAgo: 150),
            ],
            weightKg: 44, status: .active, avatarSeed: "maryam"
        )
        let g2 = Athlete(
            fullName: "Fatima Al Zaabi", fullNameAr: "فاطمة الزعابي",
            dateOfBirth: dob(age: 14), gender: .female,
            branchID: branchShaghrafa.id, primaryCoachID: coachLayla.id,
            joinedAt: years(-5), currentBelt: belt(.red, .gup, 2, awardedDaysAgo: 100),
            beltHistory: [
                belt(.white, .gup, 10, awardedDaysAgo: 1800),
                belt(.yellow, .gup, 8, awardedDaysAgo: 1400),
                belt(.green, .gup, 6, awardedDaysAgo: 900),
                belt(.blue, .gup, 4, awardedDaysAgo: 500),
                belt(.red, .gup, 2, awardedDaysAgo: 100),
            ],
            weightKg: 48, status: .competitionTeam, avatarSeed: "fatima"
        )
        let g3 = Athlete(
            fullName: "Aisha Al Dhaheri", fullNameAr: "عائشة الظاهري",
            dateOfBirth: dob(age: 11), gender: .female,
            branchID: branchShaghrafa.id, primaryCoachID: coachLayla.id,
            joinedAt: years(-2), currentBelt: belt(.yellow, .gup, 8, awardedDaysAgo: 90),
            beltHistory: [
                belt(.white, .gup, 10, awardedDaysAgo: 700),
                belt(.yellow, .gup, 8, awardedDaysAgo: 90),
            ],
            weightKg: 34, status: .active, avatarSeed: "aisha"
        )
        let g4 = Athlete(
            fullName: "Noura Al Mansoori", fullNameAr: "نورا المنصوري",
            dateOfBirth: dob(age: 12), gender: .female,
            branchID: branchShaghrafa.id, primaryCoachID: coachLayla.id,
            joinedAt: years(-3), currentBelt: belt(.green, .gup, 6, awardedDaysAgo: 200),
            beltHistory: [
                belt(.white, .gup, 10, awardedDaysAgo: 1100),
                belt(.yellow, .gup, 8, awardedDaysAgo: 700),
                belt(.green, .gup, 6, awardedDaysAgo: 200),
            ],
            weightKg: 38, status: .readyToGrade, avatarSeed: "noura"
        )
        let g5 = Athlete(
            fullName: "Hessa Al Rumaithi", fullNameAr: "حصة الرميثي",
            dateOfBirth: dob(age: 15), gender: .female,
            branchID: branchShaghrafa.id, primaryCoachID: coachLayla.id,
            joinedAt: years(-7), currentBelt: belt(.black, .poom, 1, awardedDaysAgo: 70),
            beltHistory: [
                belt(.red, .gup, 2, awardedDaysAgo: 450),
                belt(.black, .poom, 1, awardedDaysAgo: 70),
            ],
            weightKg: 52, status: .competitionTeam, avatarSeed: "hessa"
        )
        let g6 = Athlete(
            fullName: "Shamma Al Falasi", fullNameAr: "شما الفلاسي",
            dateOfBirth: dob(age: 10), gender: .female,
            branchID: branchShaghrafa.id, primaryCoachID: coachLayla.id,
            joinedAt: years(-1), currentBelt: belt(.white, .gup, 10, awardedDaysAgo: 40),
            weightKg: 28, status: .watch, avatarSeed: "shamma"
        )

        let athletes: [Athlete] = [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, g1, g2, g3, g4, g5, g6]

        let userAthlete = User(
            id: a1.id, fullName: a1.fullName, fullNameAr: a1.fullNameAr,
            role: .athlete, primaryBranchID: a1.branchID, avatarSeed: a1.avatarSeed
        )

        let users = [userAdmin, userTD, userManager, userCoach, userAthlete, userParent]

        // === Sessions: 3 per branch per day for today + 1 + 2 ===
        func session(branch: Branch, coach: Coach, dayOffset: Int, hour: Int, durationMin: Int, discipline: ClassDiscipline, ageGroup: AgeGroup, athletes enrolled: [Athlete]) -> ClassSession {
            let startBase = cal.date(byAdding: .day, value: dayOffset, to: cal.startOfDay(for: now)) ?? now
            let starts = cal.date(byAdding: .hour, value: hour, to: startBase) ?? now
            let ends = cal.date(byAdding: .minute, value: durationMin, to: starts) ?? now
            let title = "\(branch.name) — \(discipline.rawValue.capitalized)"
            return ClassSession(
                title: title, discipline: discipline,
                branchID: branch.id, coachID: coach.id,
                startsAt: starts, endsAt: ends,
                capacity: 20,
                enrolledAthleteIDs: enrolled.map { $0.id },
                ageGroup: ageGroup
            )
        }

        func roster(branch: Branch, group: AgeGroup) -> [Athlete] {
            athletes.filter { $0.branchID == branch.id && $0.ageGroup == group }
        }

        var sessions: [ClassSession] = []
        let coachByBranch: [(Branch, Coach, Coach)] = [
            (branchAlRamtha, coachYassin, coachElias),
            (branchAlJazzat, coachMohammed, coachYassin),
            (branchAlKhan, coachAshraf, coachElias),
            (branchShaghrafa, coachLayla, coachLayla),
        ]
        for dayOffset in 0...2 {
            for (branch, primary, alt) in coachByBranch {
                let kidsRoster = roster(branch: branch, group: .kids) + roster(branch: branch, group: .cubs)
                let cadetsRoster = roster(branch: branch, group: .cadets)
                let juniorsRoster = roster(branch: branch, group: .juniors) + roster(branch: branch, group: .seniors)
                sessions.append(session(branch: branch, coach: primary, dayOffset: dayOffset, hour: 10, durationMin: 60, discipline: .fundamentals, ageGroup: .kids, athletes: kidsRoster))
                sessions.append(session(branch: branch, coach: primary, dayOffset: dayOffset, hour: 16, durationMin: 75, discipline: dayOffset.isMultiple(of: 2) ? .poomsae : .kyorugi, ageGroup: .cadets, athletes: cadetsRoster))
                sessions.append(session(branch: branch, coach: alt, dayOffset: dayOffset, hour: 18, durationMin: 90, discipline: branch.code == "BR-B" ? .competition : .fitness, ageGroup: .juniors, athletes: juniorsRoster))
            }
        }

        // === Attendance ===
        // Today's first session: prefill 10 .present
        let todayStart = cal.startOfDay(for: now)
        let firstToday = sessions
            .filter { cal.isDate($0.startsAt, inSameDayAs: todayStart) }
            .min(by: { $0.startsAt < $1.startsAt })
        var attendance: [AttendanceRecord] = []
        if let s = firstToday {
            for athleteID in s.enrolledAthleteIDs.prefix(10) {
                attendance.append(AttendanceRecord(sessionID: s.id, athleteID: athleteID, state: .present, recordedAt: now))
            }
        }
        // Per-athlete synthetic history over last 90 days so eligibility engine has signal.
        for athlete in athletes {
            // 12 records, one every ~7 days. Attendance ratio depends on status.
            let presentRatio: Double
            switch athlete.status {
            case .readyToGrade: presentRatio = 0.92
            case .competitionTeam: presentRatio = 0.88
            case .active: presentRatio = 0.78
            case .watch: presentRatio = 0.50
            case .rest: presentRatio = 0.25
            }
            for k in 0..<12 {
                let dayOffset = -7 * (k + 1)
                let pseudo = ((athlete.id.hashValue &+ k * 31) & 0xFFFF) % 100
                let state: AttendanceState
                if Double(pseudo) / 100.0 < presentRatio {
                    state = pseudo < 5 ? .late : .present
                } else {
                    state = pseudo < 60 ? .absent : .excused
                }
                attendance.append(AttendanceRecord(
                    sessionID: UUID(), // synthetic — not tied to a real session
                    athleteID: athlete.id,
                    state: state,
                    recordedAt: days(dayOffset)
                ))
            }
        }

        // === Performance scores: 3 per athlete (current, 1 month ago, 2 months ago) ===
        var scores: [PerformanceScore] = []
        for (idx, athlete) in athletes.enumerated() {
            let base = 60.0 + Double((idx * 7) % 30)
            let statusBoost: Double = {
                switch athlete.status {
                case .competitionTeam: return 8
                case .readyToGrade: return 5
                case .watch: return -8
                case .rest: return -5
                case .active: return 0
                }
            }()
            for monthBack in 0...2 {
                // Watch athletes have a clear MoM drop in latest score.
                // CompetitionTeam athletes show steady improvement (latest highest).
                let trend: Double = {
                    switch athlete.status {
                    case .watch: return monthBack == 0 ? -10 : 0
                    case .competitionTeam: return Double(2 - monthBack) * 2
                    case .readyToGrade: return Double(2 - monthBack) * 1.5
                    default: return 0
                    }
                }()
                func clamp(_ v: Double) -> Double { min(100, max(0, v)) }
                let comp = clamp(base + statusBoost + trend + Double((idx * 3) % 10))
                let tech = clamp(base + statusBoost + trend - 4 + Double((idx * 5) % 12))
                let phys = clamp(base + statusBoost + trend - 2 + Double((idx * 11) % 14))
                let adher = clamp(base + statusBoost + trend + 4 - Double((idx * 2) % 8))
                let prog = clamp(base + statusBoost + trend + 2 + Double((idx * 4) % 8))
                let well = clamp(base + statusBoost + trend + 6 - Double((idx * 6) % 10))
                let char = clamp(85 + Double((idx * 13) % 12))
                scores.append(PerformanceScore(
                    athleteID: athlete.id,
                    competition: comp, technical: tech, physical: phys,
                    adherence: adher, beltProgression: prog, wellness: well, character: char,
                    calculatedAt: monthsAgo(monthBack)
                ))
            }
        }

        // === Matches ===
        var matches: [Match] = []
        let competitionAthletes = athletes.filter { $0.status == .competitionTeam }
        let medalCycle: [MedalType] = [.gold, .silver, .bronze, .none, .gold]
        for (idx, athlete) in competitionAthletes.enumerated() {
            let medal = medalCycle[idx % medalCycle.count]
            let won = medal == .gold || medal == .silver
            let ourScore = won ? 18 + (idx * 2) % 10 : 10 + (idx * 3) % 5
            let oppScore = won ? 12 + (idx * 2) % 6 : 16 + (idx * 4) % 8
            let weightClass = (athlete.weightKg / 4).rounded() * 4
            matches.append(Match(
                tournamentName: "UAE Junior Open",
                date: days(-30 - idx * 10),
                ourAthleteID: athlete.id,
                weightClassKg: weightClass,
                ourScore: ourScore, opponentScore: oppScore,
                won: won, medal: medal
            ))
        }

        // === Physical tests: 3 per athlete (monthly back), with status-based quality ===
        var physicalTests: [PhysicalTest] = []
        for athlete in athletes {
            let coachID = athlete.primaryCoachID ?? coachYassin.id
            // Quality tiers chosen so readyToGrade passes the eligibility engine
            // (composite >=60), and watch trends downward.
            let baseQuality: Int = {
                switch athlete.status {
                case .readyToGrade: return 7
                case .competitionTeam: return 8
                case .active: return 5
                case .watch: return 3
                case .rest: return 4
                }
            }()
            for monthBack in 0...2 {
                let q = max(0, baseQuality - (athlete.status == .watch && monthBack == 0 ? 2 : 0)
                                     + (athlete.status == .competitionTeam ? (2 - monthBack) : 0))
                physicalTests.append(PhysicalTest(
                    athleteID: athlete.id,
                    recordedAt: monthsAgo(monthBack),
                    recordedByCoachID: coachID,
                    beepTestStage: 6.0 + Double(q) * 0.5,
                    verticalJumpCm: 30 + Double(q) * 3.5,
                    sprint30mSec: max(4.5, 7.5 - Double(q) * 0.18),
                    agility4x10Sec: max(9.0, 13.5 - Double(q) * 0.25),
                    pushUps1Min: 25 + q * 3,
                    notes: nil
                ))
            }
        }

        // === Technical assessments: 3 per athlete ===
        var assessments: [TechnicalAssessment] = []
        for athlete in athletes {
            let coachID = athlete.primaryCoachID ?? coachYassin.id
            let form = athlete.currentBelt.kind == .gup ? "Taegeuk Sa Jang" : "Koryo"
            for monthBack in 0...2 {
                let v: Int = {
                    switch (athlete.status, monthBack) {
                    case (.watch, 0): return 5
                    case (.watch, 1): return 6
                    case (.watch, 2): return 7
                    case (.competitionTeam, 0): return 9
                    case (.competitionTeam, 1): return 8
                    case (.competitionTeam, 2): return 7
                    case (.readyToGrade, _): return 8
                    case (.rest, 0): return 5
                    case (.rest, _): return 6
                    default: return 7
                    }
                }()
                assessments.append(TechnicalAssessment(
                    athleteID: athlete.id,
                    recordedAt: monthsAgo(monthBack),
                    recordedByCoachID: coachID,
                    poomsaeForm: form,
                    power: v, accuracy: v, rhythm: v, balance: v, expression: v,
                    notes: nil
                ))
            }
        }

        // === Wellness entries: 7 per athlete (last 7 days) ===
        var wellness: [WellnessEntry] = []
        for (idx, athlete) in athletes.enumerated() {
            for dayBack in 0..<7 {
                wellness.append(WellnessEntry(
                    athleteID: athlete.id,
                    recordedAt: days(-dayBack),
                    sleepHours: 7.5 + Double((dayBack + idx) % 3) * 0.4,
                    mood: 3 + ((dayBack + idx) % 3),
                    soreness: 1 + (idx % 3),
                    rpePreviousSession: 5 + ((dayBack + idx) % 4),
                    notes: nil
                ))
            }
        }

        // === Grading sessions: one per branch that has readyToGrade athletes ===
        var gradingSessions: [GradingSession] = []
        let readyByBranch = Dictionary(grouping: athletes.filter { $0.status == .readyToGrade }, by: { $0.branchID })
        for (branchID, ready) in readyByBranch {
            guard let branch = branches.first(where: { $0.id == branchID }) else { continue }
            // Use the branch's primary coach (and Layla if Shaghrafa) as examiner.
            let examiners: [EntityID] = coaches
                .filter { $0.primaryBranchID == branch.id }
                .map { $0.id }
            gradingSessions.append(GradingSession(
                scheduledAt: days(14),
                branchID: branch.id,
                examinerCoachIDs: examiners.isEmpty ? [coachYassin.id] : examiners,
                candidateAthleteIDs: ready.map { $0.id },
                status: .scheduled
            ))
        }

        return SeedBundle(
            users: users,
            branches: branches,
            coaches: coaches,
            athletes: athletes,
            sessions: sessions,
            attendance: attendance,
            scores: scores,
            matches: matches,
            physicalTests: physicalTests,
            assessments: assessments,
            wellness: wellness,
            gradingSessions: gradingSessions,
            gradingScores: [],
            certificates: [],
            defaultCurrentUserID: userTD.id
        )
    }
}

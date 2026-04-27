import Foundation

public struct SeedCredential: Sendable {
    public let email: String
    public let passwordHash: String
    public let userID: EntityID
}

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
    public let tournaments: [Tournament]
    public let registrations: [TournamentRegistration]
    public let weightCuts: [WeightCutEntry]
    public let brackets: [Bracket]
    public let bracketMatches: [BracketMatch]
    public let announcements: [Announcement]
    public let rsvps: [AnnouncementRSVP]
    public let certifications: [Certification]
    public let auditLog: [AuditEntry]
    public let credentials: [SeedCredential]
    public let facilities: [BranchFacility]
    public let branchHours: [BranchHours]
    public let branchPrograms: [BranchProgram]
    public let branchInventories: [BranchInventory]
    public let branchCompliances: [BranchCompliance]
    public let branchPricings: [BranchPricing]
    public let branchFinancials: [BranchFinancials]
    public let branchMedias: [BranchMedia]
    public let branchSocialLinks: [BranchSocialLinks]
    public let branchSafeguardings: [BranchSafeguarding]
    public let branchMilestones: [BranchMilestone]
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
        let userDev = User(fullName: "Ayman Maklad", fullNameAr: "أيمن مقلد", role: .developer, avatarSeed: "ayman")
        let userAdmin = User(fullName: "Hanadi Al Kabouri", fullNameAr: "هنادي الكعبوري", role: .admin, avatarSeed: "hanadi")
        let userTD = User(fullName: "Dr Ali Alawi", fullNameAr: "د. علي العلوي", role: .technicalDirector, avatarSeed: "ali")
        let userManager = User(fullName: "Osama Al-Radini", fullNameAr: "أسامة الرديني", role: .branchManager, avatarSeed: "osama")
        let userParent = User(fullName: "Mohammed Al Marzooqi", fullNameAr: "محمد المرزوقي", role: .parent, avatarSeed: "marzooqi")

        // === Branches ===
        let branchAlRamtha = Branch(
            code: "BR-A", name: "Al Ramtha", nameAr: "الرمثاء",
            area: "Sharjah", capacity: 80, managerID: userManager.id, focus: "fundamentals",
            streetAddress: "Al Ramtha — Wasit Suburb, near Sharjah Cultural Square",
            streetAddressAr: "الرمثاء — ضاحية وسيط، بالقرب من ساحة الشارقة الثقافية",
            poBox: "12345",
            latitude: 25.3463, longitude: 55.4209,
            phone: "+971 6 555 1001", whatsappBusiness: "+971 50 555 1001",
            email: "ramtha@ssdsc.ae",
            foundedAt: cal.date(from: DateComponents(year: 2015, month: 4, day: 29)) ?? years(-11),
            brandHexColor: "#E24B4A",
            taglineEn: "Where champions train", taglineAr: "حيث يتدرب الأبطال"
        )
        let branchAlJazzat = Branch(
            code: "BR-B", name: "Al Jazzat", nameAr: "الجزات",
            area: "Sharjah", capacity: 60, focus: "competition",
            streetAddress: "Al Jazzat District, Sharjah",
            streetAddressAr: "منطقة الجزات، الشارقة",
            latitude: 25.3306, longitude: 55.4063,
            phone: "+971 6 555 1002", whatsappBusiness: "+971 50 555 1002",
            email: "jazzat@ssdsc.ae",
            foundedAt: cal.date(from: DateComponents(year: 2018, month: 9, day: 1)) ?? years(-8),
            brandHexColor: "#1F8FFF",
            taglineEn: "Junior & cadet powerhouse", taglineAr: "قوة الناشئين والكاديت"
        )
        let branchAlKhan = Branch(
            code: "BR-C", name: "Al Khan", nameAr: "الخان",
            area: "Sharjah", capacity: 70, focus: "poomsae",
            streetAddress: "Al Khan Community Centre, Sharjah Corniche",
            streetAddressAr: "مركز الخان المجتمعي، كورنيش الشارقة",
            latitude: 25.3252, longitude: 55.3793,
            phone: "+971 6 555 1003",
            email: "khan@ssdsc.ae",
            foundedAt: cal.date(from: DateComponents(year: 2020, month: 1, day: 15)) ?? years(-6),
            brandHexColor: "#3FB950",
            taglineEn: "Poomsae for everyone", taglineAr: "بومساي للجميع"
        )
        let branchShaghrafa = Branch(
            code: "BR-D", name: "Shaghrafa", nameAr: "الشغرفة",
            area: "Sharjah", capacity: 50, focus: "girls only",
            streetAddress: "Shaghrafa District — Women's Sports Centre",
            streetAddressAr: "منطقة الشغرفة — مركز رياضة المرأة",
            latitude: 25.3601, longitude: 55.4322,
            phone: "+971 6 555 1004", whatsappBusiness: "+971 50 555 1004",
            email: "shaghrafa@ssdsc.ae",
            foundedAt: cal.date(from: DateComponents(year: 2022, month: 3, day: 8)) ?? years(-4),
            brandHexColor: "#A855F7",
            taglineEn: "Strong women, sharper minds", taglineAr: "نساء قويات، عقول حادة"
        )
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
            memberNumber: 1001,
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
            memberNumber: 1002,
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
            memberNumber: 1003,
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
            memberNumber: 1004,
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
            memberNumber: 1005,
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
            memberNumber: 1006,
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
            memberNumber: 1007,
            fullName: "Mansour Al Ketbi", fullNameAr: "منصور الكتبي",
            dateOfBirth: dob(age: 10), gender: .male,
            branchID: branchAlRamtha.id, primaryCoachID: coachElias.id,
            joinedAt: years(-1), currentBelt: belt(.white, .gup, 10, awardedDaysAgo: 30),
            weightKg: 30, status: .active, avatarSeed: "mansour"
        )
        let a8 = Athlete(
            memberNumber: 1008,
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
            memberNumber: 1009,
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
            memberNumber: 1010,
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
            memberNumber: 1011,
            fullName: "Faisal Al Awani", fullNameAr: "فيصل العواني",
            dateOfBirth: dob(age: 9), gender: .male,
            branchID: branchAlJazzat.id, primaryCoachID: coachMohammed.id,
            joinedAt: years(-1), currentBelt: belt(.white, .gup, 10, awardedDaysAgo: 60),
            weightKg: 26, status: .active, avatarSeed: "faisal"
        )
        let a12 = Athlete(
            memberNumber: 1012,
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
            memberNumber: 1013,
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
            memberNumber: 1014,
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
            memberNumber: 1015,
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
            memberNumber: 1016,
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
            memberNumber: 1017,
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
            memberNumber: 1018,
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

        // Re-create parent with linked children now that athlete IDs are available
        let userParentLinked = User(
            id: userParent.id,
            fullName: userParent.fullName, fullNameAr: userParent.fullNameAr,
            role: userParent.role, primaryBranchID: userParent.primaryBranchID,
            avatarSeed: userParent.avatarSeed,
            linkedAthleteIDs: [a5.id, a7.id]
        )

        let users = [userDev, userAdmin, userTD, userManager, userCoach, userAthlete, userParentLinked]

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

        // === Tournaments ===
        let pastTournament = Tournament(
            name: "UAE Junior Open",
            nameAr: "بطولة الإمارات للناشئين",
            hostingFederation: .uae,
            startsAt: days(-45),
            endsAt: days(-43),
            location: "Abu Dhabi",
            locationAr: "أبوظبي",
            isOfficial: true,
            weightCategoriesOffered: [.cadetsUnder45, .cadetsUnder53, .juniorsUnder55, .juniorsUnder63, .juniorsUnder73]
        )
        let upcomingTournament = Tournament(
            name: "UAE Junior Open Q2",
            nameAr: "بطولة الإمارات للناشئين — الربع الثاني",
            hostingFederation: .uae,
            startsAt: days(30),
            endsAt: days(32),
            location: "Sharjah",
            locationAr: "الشارقة",
            isOfficial: true,
            weightCategoriesOffered: [.cadetsUnder45, .cadetsUnder53, .juniorsUnder55, .juniorsUnder63, .juniorsUnder73]
        )
        let tournaments = [pastTournament, upcomingTournament]

        // === Matches (linked to past tournament) ===
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
                tournamentName: pastTournament.name,
                tournamentID: pastTournament.id,
                date: days(-30 - idx * 10),
                ourAthleteID: athlete.id,
                weightClassKg: weightClass,
                ourScore: ourScore, opponentScore: oppScore,
                won: won, medal: medal
            ))
        }

        // === Tournament registrations: pre-register competition team for the upcoming Q2 ===
        var registrations: [TournamentRegistration] = []
        for (idx, athlete) in competitionAthletes.enumerated() {
            guard let cat = WeightCategory.suggested(for: athlete) else { continue }
            registrations.append(TournamentRegistration(
                tournamentID: upcomingTournament.id,
                athleteID: athlete.id,
                weightCategory: cat,
                seedRank: idx + 1,
                registeredAt: days(-7),
                status: .registered
            ))
        }

        // === Announcements (1 club-wide, 1 branch-specific, 1 with RSVP) ===
        var announcements: [Announcement] = []
        announcements.append(Announcement(
            title: "Q2 schedule update",
            titleAr: "تحديث جدول الربع الثاني",
            body: "Updated training times for all branches starting next week. See your branch coach for the new slots.",
            bodyAr: "تم تحديث أوقات التدريب لجميع الفروع بدءاً من الأسبوع القادم. راجع مدرب فرعك للحصول على المواعيد الجديدة.",
            audience: .all,
            publishedAt: days(-2),
            publishedByUserID: userAdmin.id
        ))
        announcements.append(Announcement(
            branchID: branchAlRamtha.id,
            title: "Mat cleaning Saturday",
            titleAr: "تنظيف البساط يوم السبت",
            body: "Al Ramtha mats will be deep-cleaned this Saturday. No classes after 12:00.",
            bodyAr: "سيتم تنظيف بساط الرمثاء يوم السبت. لا توجد حصص بعد الساعة 12:00.",
            audience: .coaches,
            publishedAt: days(-5),
            publishedByUserID: userManager.id
        ))
        announcements.append(Announcement(
            title: "Parent meeting — Q2 Open",
            titleAr: "اجتماع أولياء الأمور — بطولة الربع الثاني",
            body: "Mandatory briefing for all parents of competition-team athletes registering for the UAE Junior Open Q2. Please RSVP.",
            bodyAr: "اجتماع إلزامي لجميع أولياء أمور رياضيي فريق المنافسة المسجلين في بطولة الإمارات للربع الثاني. الرجاء تأكيد الحضور.",
            audience: .parents,
            publishedAt: days(-1),
            publishedByUserID: userTD.id,
            requiresRSVP: true,
            rsvpDeadline: days(7)
        ))

        // === Certifications: mirror existing coach cert dates + add a few extras ===
        var certifications: [Certification] = []
        for c in coaches {
            certifications.append(Certification(
                coachID: c.id, kind: .firstAid, issuer: "UAE Red Crescent",
                issuedAt: cal.date(byAdding: .year, value: -1, to: c.firstAidExpiry) ?? c.firstAidExpiry,
                expiresAt: c.firstAidExpiry
            ))
            certifications.append(Certification(
                coachID: c.id, kind: .safeguarding, issuer: "WT",
                issuedAt: cal.date(byAdding: .year, value: -2, to: c.safeguardingExpiry) ?? c.safeguardingExpiry,
                expiresAt: c.safeguardingExpiry
            ))
            certifications.append(Certification(
                coachID: c.id, kind: .wtCoaching, issuer: "World Taekwondo",
                issuedAt: c.hiredAt,
                expiresAt: cal.date(byAdding: .year, value: 4, to: c.hiredAt) ?? days(365)
            ))
        }

        // === Initial audit log: a few synthesized entries ===
        var auditLog: [AuditEntry] = []
        auditLog.append(AuditEntry(at: days(-7), actorUserID: userTD.id, action: "viewDashboard", targetEntity: "Dashboard", targetID: userTD.id))
        auditLog.append(AuditEntry(at: days(-5), actorUserID: userManager.id, action: "publishAnnouncement", targetEntity: "Announcement", targetID: announcements[1].id))
        auditLog.append(AuditEntry(at: days(-2), actorUserID: userAdmin.id, action: "publishAnnouncement", targetEntity: "Announcement", targetID: announcements[0].id))
        auditLog.append(AuditEntry(at: days(-1), actorUserID: userTD.id, action: "publishAnnouncement", targetEntity: "Announcement", targetID: announcements[2].id))

        // === Weight cut history for the first registration ===
        var weightCuts: [WeightCutEntry] = []
        if let firstReg = registrations.first,
           let athlete = athletes.first(where: { $0.id == firstReg.athleteID }) {
            let target = firstReg.weightCategory.range.upper ?? athlete.weightKg
            for dayBack in 0..<14 {
                let trend = athlete.weightKg + Double(dayBack) * 0.3 // older = heavier
                weightCuts.append(WeightCutEntry(
                    registrationID: firstReg.id,
                    recordedAt: days(-dayBack),
                    currentKg: trend,
                    targetKg: target,
                    notes: nil
                ))
            }
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

        let credentials = [
            SeedCredential(email: "gulflens.studio@gmail.com", passwordHash: "d19f3c3cde74772f7d534e92d9cc63955694fe9083f63ca10f8aaad00802140c", userID: userDev.id),
            SeedCredential(email: "admin@shjsdsc.ae", passwordHash: "ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f", userID: userAdmin.id),
            SeedCredential(email: "td@shjsdsc.ae", passwordHash: "ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f", userID: userTD.id),
            SeedCredential(email: "coach@shjsdsc.ae", passwordHash: "ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f", userID: userCoach.id),
        ]

        // === Stage 1.5: branch profile seed data ===

        func standardWeek(closedFri: Bool = false) -> [DayHours] {
            let weekday: [(DayOfWeek, String, String)] = [
                (.sun, "14:00", "22:00"),
                (.mon, "14:00", "22:00"),
                (.tue, "14:00", "22:00"),
                (.wed, "14:00", "22:00"),
                (.thu, "14:00", "22:00"),
            ]
            var rows = weekday.map { DayHours(day: $0.0, isOpen: true, opensAt: $0.1, closesAt: $0.2) }
            rows.append(DayHours(day: .fri, isOpen: !closedFri,
                                 opensAt: closedFri ? nil : "16:00",
                                 closesAt: closedFri ? nil : "21:00"))
            rows.append(DayHours(day: .sat, isOpen: true, opensAt: "09:00", closesAt: "21:00"))
            return rows
        }

        func ramadanWeek() -> [DayHours] {
            DayOfWeek.allCases.map { d in
                if d == .fri { return DayHours(day: d, isOpen: false) }
                return DayHours(day: d, isOpen: true, opensAt: "21:00", closesAt: "01:00")
            }
        }

        let ramadanStart = cal.date(from: DateComponents(year: 2026, month: 2, day: 17)) ?? days(60)
        let ramadanEnd = cal.date(from: DateComponents(year: 2026, month: 3, day: 18)) ?? days(90)

        let hoursRamtha = BranchHours(
            branchID: branchAlRamtha.id, regular: standardWeek(),
            ramadan: ramadanWeek(), ramadanStart: ramadanStart, ramadanEnd: ramadanEnd,
            holidayClosures: [days(20), days(45)]
        )
        let hoursJazzat = BranchHours(branchID: branchAlJazzat.id, regular: standardWeek())
        let hoursKhan = BranchHours(branchID: branchAlKhan.id, regular: standardWeek())
        let hoursShaghrafa = BranchHours(branchID: branchShaghrafa.id, regular: standardWeek(closedFri: true))
        let allBranchHours = [hoursRamtha, hoursJazzat, hoursKhan, hoursShaghrafa]

        // Facilities: Al Ramtha is the flagship (1200 sqm, 2 halls, PSS).
        let facilityRamtha = BranchFacility(
            branchID: branchAlRamtha.id,
            floorAreaSqm: 1200, hallCount: 2,
            hallDimensions: [
                HallSpec(name: "Main Hall", lengthM: 14, widthM: 12,
                         matSpec: "WT 12x12 puzzle, 30mm", isCompetitionGrade: true),
                HallSpec(name: "Studio 2", lengthM: 10, widthM: 8,
                         matSpec: "Training mats 25mm")
            ],
            hasMirrorWalls: true, hasSoundSystem: true, hasAC: true,
            hasInstalledScoreboard: true, hasPSS: true,
            pssBrand: "Daedo", pssLastCalibrationAt: days(-90),
            changingRoomsM: 2, changingRoomsF: 2,
            spectatorSeats: 80, parkingSpots: 30,
            hasPrayerRoom: true, hasWudu: true,
            photoURLs: [
                "https://placehold.co/1200x800/png?text=Al+Ramtha+Main",
                "https://placehold.co/1200x800/png?text=Al+Ramtha+Hall",
                "https://placehold.co/1200x800/png?text=Al+Ramtha+Lobby",
                "https://placehold.co/1200x800/png?text=Al+Ramtha+Spectators"
            ]
        )
        let facilityJazzat = BranchFacility(
            branchID: branchAlJazzat.id,
            floorAreaSqm: 600, hallCount: 1,
            hallDimensions: [HallSpec(name: "Main Hall", lengthM: 12, widthM: 10,
                                      matSpec: "WT puzzle 25mm", isCompetitionGrade: true)],
            hasMirrorWalls: true, hasSoundSystem: true, hasAC: true,
            hasInstalledScoreboard: true,
            changingRoomsM: 1, changingRoomsF: 1,
            spectatorSeats: 40, parkingSpots: 12,
            hasPrayerRoom: true, hasWudu: true
        )
        let facilityKhan = BranchFacility(
            branchID: branchAlKhan.id,
            floorAreaSqm: 500, hallCount: 1,
            hallDimensions: [HallSpec(name: "Community Hall", lengthM: 10, widthM: 9,
                                      matSpec: "Foam tatami 20mm")],
            hasMirrorWalls: false, hasSoundSystem: true, hasAC: true,
            changingRoomsM: 1, changingRoomsF: 1,
            spectatorSeats: 20, parkingSpots: 8,
            hasPrayerRoom: false, hasWudu: false
        )
        let facilityShaghrafa = BranchFacility(
            branchID: branchShaghrafa.id,
            floorAreaSqm: 700, hallCount: 1,
            hallDimensions: [HallSpec(name: "Women's Hall", lengthM: 12, widthM: 10,
                                      matSpec: "WT puzzle 25mm", isCompetitionGrade: true)],
            hasMirrorWalls: true, hasSoundSystem: true, hasAC: true,
            changingRoomsM: 0, changingRoomsF: 3,
            spectatorSeats: 30, parkingSpots: 16,
            hasPrayerRoom: true, hasWudu: true
        )
        let allFacilities = [facilityRamtha, facilityJazzat, facilityKhan, facilityShaghrafa]

        // Programs (5–6 per branch)
        func program(_ branch: Branch, name: String, nameAr: String,
                     age: AgeGroup, disciplines: [ClassDiscipline],
                     pattern: [DayOfWeek], start: String, end: String,
                     capacity: Int, fee: Double,
                     womenOnly: Bool = false) -> BranchProgram {
            BranchProgram(
                branchID: branch.id,
                customName: name, customNameAr: nameAr,
                descriptionEn: name, descriptionAr: nameAr,
                ageGroup: age, disciplines: disciplines,
                schedulePattern: pattern,
                startTime: start, endTime: end,
                capacity: capacity, currentEnrolment: Int.random(in: capacity / 4 ... capacity),
                monthlyFeeAED: fee,
                trialClassFeeAED: 50,
                registrationFeeAED: 200,
                equipmentPackageFeeAED: 350,
                siblingDiscountPct: 0.10,
                annualPrepayDiscountPct: 0.05,
                isWomenOnly: womenOnly
            )
        }

        let programsRamtha = [
            program(branchAlRamtha, name: "Cubs after-school", nameAr: "أشبال بعد المدرسة",
                    age: .cubs, disciplines: [.fundamentals],
                    pattern: [.sun, .tue, .thu], start: "16:00", end: "17:00",
                    capacity: 16, fee: 350),
            program(branchAlRamtha, name: "Junior fundamentals", nameAr: "أساسيات الناشئين",
                    age: .kids, disciplines: [.fundamentals, .poomsae],
                    pattern: [.sun, .tue, .thu], start: "17:15", end: "18:30",
                    capacity: 20, fee: 450),
            program(branchAlRamtha, name: "Cadet kyorugi", nameAr: "كيوروجي كاديت",
                    age: .cadets, disciplines: [.kyorugi],
                    pattern: [.mon, .wed, .sat], start: "18:30", end: "20:00",
                    capacity: 18, fee: 500),
            program(branchAlRamtha, name: "Junior comp team", nameAr: "فريق منافسات الناشئين",
                    age: .juniors, disciplines: [.kyorugi, .competition],
                    pattern: [.mon, .wed, .fri], start: "19:00", end: "21:00",
                    capacity: 12, fee: 650),
            program(branchAlRamtha, name: "Senior fitness", nameAr: "لياقة الكبار",
                    age: .seniors, disciplines: [.fitness],
                    pattern: [.tue, .thu], start: "20:00", end: "21:00",
                    capacity: 20, fee: 400),
            program(branchAlRamtha, name: "Adult beginners", nameAr: "مبتدئين بالغين",
                    age: .seniors, disciplines: [.fundamentals],
                    pattern: [.mon, .wed], start: "20:30", end: "21:30",
                    capacity: 16, fee: 400),
        ]
        let programsJazzat = [
            program(branchAlJazzat, name: "Junior fundamentals", nameAr: "أساسيات الناشئين",
                    age: .kids, disciplines: [.fundamentals],
                    pattern: [.sun, .tue, .thu], start: "16:30", end: "18:00",
                    capacity: 18, fee: 350),
            program(branchAlJazzat, name: "Cadet kyorugi", nameAr: "كيوروجي كاديت",
                    age: .cadets, disciplines: [.kyorugi],
                    pattern: [.mon, .wed, .sat], start: "18:00", end: "19:30",
                    capacity: 16, fee: 450),
            program(branchAlJazzat, name: "Cadet poomsae", nameAr: "بومساي كاديت",
                    age: .cadets, disciplines: [.poomsae],
                    pattern: [.tue, .thu], start: "16:30", end: "18:00",
                    capacity: 14, fee: 400),
            program(branchAlJazzat, name: "Junior comp", nameAr: "منافسات الناشئين",
                    age: .juniors, disciplines: [.competition, .kyorugi],
                    pattern: [.sun, .tue, .thu], start: "19:00", end: "20:30",
                    capacity: 12, fee: 550),
        ]
        let programsKhan = [
            program(branchAlKhan, name: "Cubs club", nameAr: "نادي الأشبال",
                    age: .cubs, disciplines: [.fundamentals],
                    pattern: [.mon, .wed], start: "16:30", end: "17:30",
                    capacity: 14, fee: 250),
            program(branchAlKhan, name: "Kids poomsae", nameAr: "بومساي الأطفال",
                    age: .kids, disciplines: [.poomsae],
                    pattern: [.sun, .tue, .thu], start: "17:30", end: "18:45",
                    capacity: 16, fee: 350),
            program(branchAlKhan, name: "Open class", nameAr: "حصة مفتوحة",
                    age: .seniors, disciplines: [.fundamentals, .fitness],
                    pattern: [.tue, .thu, .sat], start: "19:00", end: "20:30",
                    capacity: 20, fee: 400),
        ]
        let programsShaghrafa = [
            program(branchShaghrafa, name: "Girls cubs", nameAr: "بنات الأشبال",
                    age: .cubs, disciplines: [.fundamentals],
                    pattern: [.sun, .tue, .thu], start: "16:00", end: "17:00",
                    capacity: 14, fee: 350, womenOnly: true),
            program(branchShaghrafa, name: "Junior girls", nameAr: "ناشئات",
                    age: .kids, disciplines: [.fundamentals, .poomsae],
                    pattern: [.sun, .tue, .thu], start: "17:15", end: "18:30",
                    capacity: 16, fee: 450, womenOnly: true),
            program(branchShaghrafa, name: "Women's kyorugi", nameAr: "كيوروجي للنساء",
                    age: .seniors, disciplines: [.kyorugi],
                    pattern: [.mon, .wed], start: "19:00", end: "20:30",
                    capacity: 14, fee: 500, womenOnly: true),
            program(branchShaghrafa, name: "Women's fitness", nameAr: "لياقة النساء",
                    age: .seniors, disciplines: [.fitness],
                    pattern: [.tue, .thu, .sat], start: "10:00", end: "11:00",
                    capacity: 18, fee: 400, womenOnly: true),
        ]
        let allBranchPrograms = programsRamtha + programsJazzat + programsKhan + programsShaghrafa

        // Inventories
        func inventory(branch: Branch, scale: Double) -> BranchInventory {
            func qty(_ n: Int) -> Int { Int((Double(n) * scale).rounded()) }
            let items = [
                InventoryItem(category: .hogu, labelKey: "inventory.hogu", size: "S",
                              quantity: qty(10), conditionGood: qty(7), conditionFair: qty(2), conditionPoor: qty(1)),
                InventoryItem(category: .hogu, labelKey: "inventory.hogu", size: "M",
                              quantity: qty(12), conditionGood: qty(8), conditionFair: qty(3), conditionPoor: qty(1)),
                InventoryItem(category: .hogu, labelKey: "inventory.hogu", size: "L",
                              quantity: qty(8), conditionGood: qty(5), conditionFair: qty(2), conditionPoor: qty(1)),
                InventoryItem(category: .helmet, labelKey: "inventory.helmet",
                              quantity: qty(25), conditionGood: qty(18), conditionFair: qty(5), conditionPoor: qty(2)),
                InventoryItem(category: .shinGuard, labelKey: "inventory.shinGuard",
                              quantity: qty(30), conditionGood: qty(22), conditionFair: qty(6), conditionPoor: qty(2)),
                InventoryItem(category: .kickingPad, labelKey: "inventory.kickingPad",
                              quantity: qty(20), conditionGood: qty(15), conditionFair: qty(4), conditionPoor: qty(1)),
                InventoryItem(category: .breakingBoard, labelKey: "inventory.breakingBoard",
                              quantity: qty(60), conditionGood: qty(60), conditionFair: 0, conditionPoor: 0),
                InventoryItem(category: .scoreboard, labelKey: "inventory.scoreboard",
                              quantity: 1, conditionGood: 1),
                InventoryItem(category: .medkit, labelKey: "inventory.medkit",
                              quantity: 2, conditionGood: 2),
            ]
            return BranchInventory(branchID: branch.id, items: items,
                                   lastAuditAt: days(-21), lastAuditByUserID: userManager.id)
        }
        let allInventories = [
            inventory(branch: branchAlRamtha, scale: 1.0),
            inventory(branch: branchAlJazzat, scale: 0.7),
            inventory(branch: branchAlKhan, scale: 0.5),
            inventory(branch: branchShaghrafa, scale: 0.6),
        ]

        // Compliance
        let complianceRamtha = BranchCompliance(
            branchID: branchAlRamtha.id,
            civilDefenceCertNumber: "CD-2024-A-1057", civilDefenceExpiry: days(220),
            sharjahSportsCouncilRegNumber: "SSC-2024-AR-19", sharjahSportsCouncilExpiry: days(180),
            insurancePolicyNumber: "DAMAN-PRT-77194", insuranceProvider: "Daman", insuranceExpiry: days(190),
            lastHealthSafetyInspectionAt: days(-45), lastEmergencyPlanReviewAt: days(-30),
            hasAED: true, aedLastServiceAt: days(-60), firstAidKitLastCheckedAt: days(-7)
        )
        let complianceJazzat = BranchCompliance(
            branchID: branchAlJazzat.id,
            civilDefenceCertNumber: "CD-2024-J-4022", civilDefenceExpiry: days(150),
            sharjahSportsCouncilRegNumber: "SSC-2024-JZ-22", sharjahSportsCouncilExpiry: days(160),
            insurancePolicyNumber: "ADNIC-44990", insuranceProvider: "ADNIC", insuranceExpiry: days(170),
            lastHealthSafetyInspectionAt: days(-30), hasAED: true, aedLastServiceAt: days(-90),
            firstAidKitLastCheckedAt: days(-14)
        )
        // Al Khan has a cert expiring next month → drives a TD alert.
        let complianceKhan = BranchCompliance(
            branchID: branchAlKhan.id,
            civilDefenceCertNumber: "CD-2024-K-7715", civilDefenceExpiry: days(20),
            sharjahSportsCouncilRegNumber: "SSC-2024-KH-08", sharjahSportsCouncilExpiry: days(140),
            insurancePolicyNumber: "ORIENT-12054", insuranceProvider: "Orient", insuranceExpiry: days(120),
            lastHealthSafetyInspectionAt: days(-90), hasAED: false,
            firstAidKitLastCheckedAt: days(-21)
        )
        let complianceShaghrafa = BranchCompliance(
            branchID: branchShaghrafa.id,
            civilDefenceCertNumber: "CD-2024-S-3019", civilDefenceExpiry: days(280),
            sharjahSportsCouncilRegNumber: "SSC-2024-SH-31", sharjahSportsCouncilExpiry: days(260),
            insurancePolicyNumber: "DAMAN-PRT-88210", insuranceProvider: "Daman", insuranceExpiry: days(250),
            lastHealthSafetyInspectionAt: days(-20), lastEmergencyPlanReviewAt: days(-20),
            hasAED: true, aedLastServiceAt: days(-30), firstAidKitLastCheckedAt: days(-3)
        )
        let allCompliances = [complianceRamtha, complianceJazzat, complianceKhan, complianceShaghrafa]

        // Pricing
        func pricing(branch: Branch, base: Double, trial: Double = 50, reg: Double = 200, equip: Double = 350) -> BranchPricing {
            BranchPricing(
                branchID: branch.id,
                baseMonthlyFeeAED: base, trialClassFeeAED: trial,
                registrationFeeAED: reg, equipmentPackageFeeAED: equip,
                siblingDiscountPct: 0.10, annualPrepayDiscountPct: 0.10,
                promotions: [
                    Promotion(
                        titleEn: "Back to school", titleAr: "العودة للمدارس",
                        descriptionEn: "Free registration for new athletes joining in September",
                        descriptionAr: "تسجيل مجاني للملتحقين الجدد في سبتمبر",
                        discountAED: reg, validFrom: days(-30), validUntil: days(60),
                        promoCode: "BACK2SCHOOL"
                    )
                ], effectiveFrom: days(-90)
            )
        }
        let allPricings = [
            pricing(branch: branchAlRamtha, base: 450),
            pricing(branch: branchAlJazzat, base: 400),
            pricing(branch: branchAlKhan, base: 300, trial: 30, reg: 150, equip: 250),
            pricing(branch: branchShaghrafa, base: 425),
        ]

        // Financials — last 6 months × 4 branches
        func financialsSeries(branch: Branch, baseRevenue: Double, baseRent: Double) -> [BranchFinancials] {
            (0..<6).map { offset in
                let month = cal.date(byAdding: .month, value: -offset, to: now) ?? now
                let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: month)) ?? month
                let drift = Double.random(in: -0.08 ... 0.08)
                let revenue = baseRevenue * (1 + drift)
                return BranchFinancials(
                    branchID: branch.id, month: monthStart,
                    revenueAED: revenue,
                    rentAED: baseRent,
                    utilitiesAED: baseRent * 0.18,
                    staffCostAED: revenue * 0.42,
                    equipmentAED: revenue * 0.05,
                    marketingAED: revenue * 0.04,
                    otherExpensesAED: revenue * 0.06,
                    outstandingFeesAED: revenue * 0.07,
                    activePaymentPlans: Int(Double.random(in: 4...12))
                )
            }
        }
        let allFinancials =
            financialsSeries(branch: branchAlRamtha, baseRevenue: 85_000, baseRent: 22_000)
            + financialsSeries(branch: branchAlJazzat, baseRevenue: 50_000, baseRent: 14_000)
            + financialsSeries(branch: branchAlKhan, baseRevenue: 32_000, baseRent: 9_000)
            + financialsSeries(branch: branchShaghrafa, baseRevenue: 45_000, baseRent: 13_000)

        // Media
        func media(branch: Branch) -> BranchMedia {
            BranchMedia(
                branchID: branch.id,
                logoURL: "https://placehold.co/200x200/png?text=\(branch.code)",
                heroPhotoURL: "https://placehold.co/1600x900/png?text=\(branch.name.replacingOccurrences(of: " ", with: "+"))",
                galleryURLs: (1...4).map { "https://placehold.co/1200x800/png?text=\(branch.code)-\($0)" }
            )
        }
        let allMedia = branches.map(media)

        // Social
        let allSocial = [
            BranchSocialLinks(
                branchID: branchAlRamtha.id,
                whatsappParentsLink: "https://chat.whatsapp.com/ramtha-parents",
                whatsappAthletesLink: "https://chat.whatsapp.com/ramtha-athletes",
                instagramHandle: "@ssdsc_taekwondo",
                tiktokHandle: "@ssdsc_taekwondo",
                websiteURL: "https://ssdsc.ae"
            ),
            BranchSocialLinks(
                branchID: branchAlJazzat.id,
                whatsappParentsLink: "https://chat.whatsapp.com/jazzat-parents",
                instagramHandle: "@ssdsc_jazzat"
            ),
            BranchSocialLinks(
                branchID: branchAlKhan.id,
                whatsappParentsLink: "https://chat.whatsapp.com/khan-parents",
                instagramHandle: "@ssdsc_khan"
            ),
            BranchSocialLinks(
                branchID: branchShaghrafa.id,
                whatsappParentsLink: "https://chat.whatsapp.com/shaghrafa-parents",
                instagramHandle: "@ssdsc_shaghrafa_girls"
            ),
        ]

        // Safeguarding
        let allSafeguarding = [
            BranchSafeguarding(
                branchID: branchAlRamtha.id,
                safeguardingOfficerCoachID: coachYassin.id,
                lastTeamTrainingAt: days(-90),
                staffCheckCurrentPct: 0.95,
                openIncidentCount: 0,
                lastIncidentAt: days(-200)
            ),
            BranchSafeguarding(
                branchID: branchAlJazzat.id,
                safeguardingOfficerCoachID: coachMohammed.id,
                lastTeamTrainingAt: days(-150),
                staffCheckCurrentPct: 0.80,
                openIncidentCount: 1,
                lastIncidentAt: days(-30)
            ),
            BranchSafeguarding(
                branchID: branchAlKhan.id,
                safeguardingOfficerCoachID: coachAshraf.id,
                lastTeamTrainingAt: days(-200),
                staffCheckCurrentPct: 0.66
            ),
            BranchSafeguarding(
                branchID: branchShaghrafa.id,
                safeguardingOfficerCoachID: coachLayla.id,
                lastTeamTrainingAt: days(-60),
                staffCheckCurrentPct: 1.0
            ),
        ]

        // Milestones
        let allMilestones = [
            BranchMilestone(branchID: branchAlRamtha.id, occurredAt: branchAlRamtha.foundedAt,
                            titleEn: "Branch founded", titleAr: "تأسيس الفرع",
                            descriptionEn: "Al Ramtha opens as the founding SSDSC dojang.",
                            descriptionAr: "افتتاح فرع الرمثاء كأول دوجانغ تابع لـ SSDSC.",
                            category: .founded),
            BranchMilestone(branchID: branchAlRamtha.id, occurredAt: monthsAgo(11),
                            titleEn: "UAE Junior League champions",
                            titleAr: "أبطال دوري الناشئين الإماراتي",
                            descriptionEn: "Al Ramtha team wins the 2025 UAE Junior League.",
                            descriptionAr: "فاز فريق الرمثاء ببطولة دوري الناشئين الإماراتي 2025.",
                            category: .championshipWon),
            BranchMilestone(branchID: branchAlRamtha.id, occurredAt: monthsAgo(4),
                            titleEn: "PSS calibration", titleAr: "معايرة نظام النقاط",
                            descriptionEn: "Daedo PSS recalibrated for the new season.",
                            descriptionAr: "إعادة معايرة نظام Daedo للموسم الجديد.",
                            category: .recordSet),
            BranchMilestone(branchID: branchAlJazzat.id, occurredAt: branchAlJazzat.foundedAt,
                            titleEn: "Branch founded", titleAr: "تأسيس الفرع",
                            category: .founded),
            BranchMilestone(branchID: branchAlJazzat.id, occurredAt: monthsAgo(20),
                            titleEn: "Hall renovation", titleAr: "تجديد القاعة",
                            descriptionEn: "Mat replacement and AC upgrade.",
                            descriptionAr: "استبدال السجاد وتطوير التكييف.",
                            category: .renovation),
            BranchMilestone(branchID: branchAlKhan.id, occurredAt: branchAlKhan.foundedAt,
                            titleEn: "Branch founded", titleAr: "تأسيس الفرع",
                            category: .founded),
            BranchMilestone(branchID: branchAlKhan.id, occurredAt: monthsAgo(6),
                            titleEn: "Community partnership",
                            titleAr: "شراكة مجتمعية",
                            descriptionEn: "Sharjah Community Centre partnership renewed.",
                            descriptionAr: "تجديد شراكة مركز الشارقة المجتمعي.",
                            category: .partnership),
            BranchMilestone(branchID: branchShaghrafa.id, occurredAt: branchShaghrafa.foundedAt,
                            titleEn: "Girls-only branch opens", titleAr: "افتتاح الفرع النسائي",
                            descriptionEn: "Sharjah's first dedicated women's taekwondo dojang.",
                            descriptionAr: "أول دوجانغ تايكوندو مخصص للنساء في الشارقة.",
                            category: .founded),
            BranchMilestone(branchID: branchShaghrafa.id, occurredAt: monthsAgo(3),
                            titleEn: "First female national medal",
                            titleAr: "أول ميدالية وطنية للناشئات",
                            descriptionEn: "First female athlete from Shaghrafa wins UAE bronze.",
                            descriptionAr: "أول رياضية من الشغرفة تحصد برونزية الإمارات.",
                            category: .alumniAchievement),
        ]

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
            tournaments: tournaments,
            registrations: registrations,
            weightCuts: weightCuts,
            brackets: [],
            bracketMatches: [],
            announcements: announcements,
            rsvps: [],
            certifications: certifications,
            auditLog: auditLog,
            credentials: credentials,
            facilities: allFacilities,
            branchHours: allBranchHours,
            branchPrograms: allBranchPrograms,
            branchInventories: allInventories,
            branchCompliances: allCompliances,
            branchPricings: allPricings,
            branchFinancials: allFinancials,
            branchMedias: allMedia,
            branchSocialLinks: allSocial,
            branchSafeguardings: allSafeguarding,
            branchMilestones: allMilestones,
            defaultCurrentUserID: userDev.id
        )
    }
}

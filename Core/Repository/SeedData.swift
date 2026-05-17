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
    public let physicalMetrics: [PhysicalMetric]
    public let technicalSkills: [TechnicalSkill]
    public let poomsaeAssessments: [PoomsaeAssessment]
    public let trainingLoad: [TrainingLoadEntry]
    public let drills: [DrillLibraryEntry]
    public let improvementPlans: [ImprovementPlan]
    public let peerBenchmarks: [PeerBenchmark]
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
    public let athleteGroups: [AthleteGroup]
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

        // Map a quality tier (1...10, higher = better athlete) onto a metric's
        // input range, respecting whether higher or lower is better. The bias
        // arg lets us nudge specific cases (e.g. unilateral L/R asymmetry).
        func seedValue(for kind: PhysicalMetricKind, quality: Double, leg: BodySide?) -> Double {
            let q = max(0.5, min(10.0, quality)) / 10.0
            let r = kind.inputRange
            if kind.isPassFail {
                return q >= 0.6 ? 1 : 0
            }
            // Map q into the range; if lower-is-better, flip.
            let target = r.lower + (r.upper - r.lower) * (kind.higherIsBetter ? q : (1 - q))
            // Round to step.
            let step = r.step
            let snapped = (target / step).rounded() * step
            return max(r.lower, min(r.upper, snapped))
        }

        // === Non-coach users ===
        // The project owner. Carries `AppOwner.email` on the User record so
        // `isAppOwner` resolves and the owner-protection invariant engages.
        let userDev = User(fullName: "Ayman Maklad", fullNameAr: "أيمن مقلد", role: .developer, avatarSeed: "ayman", email: AppOwner.email)
        let userAdmin = User(fullName: "Hanadi Al Kabouri", fullNameAr: "هنادي الكعبوري", role: .admin, avatarSeed: "hanadi")
        let userTD = User(fullName: "Dr Ali Alawi", fullNameAr: "د. علي العلوي", role: .technicalDirector, avatarSeed: "ali")
        let userManager = User(fullName: "Osama Al-Radini", fullNameAr: "أسامة الرديني", role: .branchManager, avatarSeed: "osama")
        let userParent = User(fullName: "Mohammed Al Marzooqi", fullNameAr: "محمد المرزوقي", role: .parent, avatarSeed: "marzooqi")

        // === Branches ===
        // Al Rahmania (formerly Shaghrafa) is the main / headquarters branch.
        let branchAlRahmania = Branch(
            code: "BR-A", name: "Al Rahmania", nameAr: "الرحمانية",
            area: "Sharjah", capacity: 100, managerID: userManager.id, focus: "main",
            streetAddress: "Al Rahmania, near Sharjah Mosque & University City Rd",
            streetAddressAr: "الرحمانية، بالقرب من مسجد الشارقة وطريق المدينة الجامعية",
            poBox: "12345",
            latitude: 25.3376875, longitude: 55.5680625,
            phone: "+971 6 556 6017", whatsappBusiness: "+971 50 555 1001",
            email: "rahmania@ssdsc.ae",
            foundedAt: cal.date(from: DateComponents(year: 2015, month: 4, day: 29)) ?? years(-11),
            brandHexColor: "#E24B4A",
            taglineEn: "Headquarters · where the club began", taglineAr: "المقر الرئيسي — هنا بدأ النادي"
        )
        let branchAlNasserya = Branch(
            code: "BR-B", name: "Al Nasserya", nameAr: "الناصرية",
            area: "Sharjah", capacity: 60, focus: "competition",
            streetAddress: "Al Nasserya, north-central Sharjah",
            streetAddressAr: "الناصرية، شمال وسط الشارقة",
            latitude: 25.3650, longitude: 55.4044,
            phone: "+971 6 555 1002", whatsappBusiness: "+971 50 555 1002",
            email: "nasserya@ssdsc.ae",
            foundedAt: cal.date(from: DateComponents(year: 2018, month: 9, day: 1)) ?? years(-8),
            brandHexColor: "#1F8FFF",
            taglineEn: "Junior & cadet powerhouse", taglineAr: "قوة الناشئين والكاديت"
        )
        let branchIndustrial18 = Branch(
            code: "BR-C", name: "Industrial 18", nameAr: "المنطقة الصناعية 18",
            area: "Sharjah", capacity: 70, focus: "poomsae",
            streetAddress: "Industrial Area 18, off Sheikh Mohammed Bin Zayed Rd",
            streetAddressAr: "المنطقة الصناعية 18، قرب شارع الشيخ محمد بن زايد",
            latitude: 25.3196, longitude: 55.4129,
            phone: "+971 6 555 1003",
            email: "industrial18@ssdsc.ae",
            foundedAt: cal.date(from: DateComponents(year: 2020, month: 1, day: 15)) ?? years(-6),
            brandHexColor: "#3FB950",
            taglineEn: "Warehouse-converted training hub", taglineAr: "مستودع مُعاد تأهيله للتدريب"
        )
        let branchAlNouf = Branch(
            code: "BR-D", name: "Al Nouf", nameAr: "النوف",
            area: "Sharjah", capacity: 80, focus: "fundamentals",
            streetAddress: "Al Nouf, central Sharjah near Wasit Suburb",
            streetAddressAr: "النوف، وسط الشارقة بالقرب من ضاحية وسيط",
            latitude: 25.3500, longitude: 55.4250,
            phone: "+971 6 555 1004", whatsappBusiness: "+971 50 555 1004",
            email: "nouf@ssdsc.ae",
            foundedAt: cal.date(from: DateComponents(year: 2022, month: 3, day: 8)) ?? years(-4),
            brandHexColor: "#A855F7",
            taglineEn: "Where champions train", taglineAr: "حيث يتدرب الأبطال"
        )
        var branches = [branchAlRahmania, branchAlNasserya, branchIndustrial18, branchAlNouf]

        // === Stage 1.6 branch-redesign hierarchy seed ===
        //
        // Mark Al Rahmania as the federation's main branch. Set varied
        // operational states across the secondaries so the Branches Overview
        // status badges are visibly distinct.
        if branches.indices.contains(0) {
            branches[0].isMain = true
            branches[0].operationalStatus = .active
        }
        if branches.indices.contains(1) {
            branches[1].operationalStatus = .tournamentMode
        }
        if branches.indices.contains(2) {
            branches[2].operationalStatus = .maintenance
        }
        if branches.indices.contains(3) {
            branches[3].operationalStatus = .active
        }

        // === Coaches ===
        let coachYassin = Coach(
            fullName: "Yassin Al-Jawadi", fullNameAr: "ياسين الجوادي",
            primaryBranchID: branchAlNouf.id,
            secondaryBranchIDs: [branchAlNasserya.id],
            danRank: 4, wtCoachLicenceLevel: 2,
            firstAidExpiry: days(180), safeguardingExpiry: days(365),
            contractType: .fullTime, hiredAt: years(-5), avatarSeed: "yassin"
        )
        let coachAshraf = Coach(
            fullName: "Ashraf Abdul-Jalil", fullNameAr: "أشرف عبد الجليل",
            primaryBranchID: branchIndustrial18.id, secondaryBranchIDs: [],
            danRank: 3, wtCoachLicenceLevel: 2,
            firstAidExpiry: days(60), safeguardingExpiry: days(60),
            contractType: .partTime, hiredAt: years(-3), avatarSeed: "ashraf"
        )
        let coachElias = Coach(
            fullName: "Elias Mansri", fullNameAr: "إلياس منصري",
            primaryBranchID: branchAlNouf.id, secondaryBranchIDs: [branchIndustrial18.id],
            danRank: 2, wtCoachLicenceLevel: 1,
            firstAidExpiry: days(300), safeguardingExpiry: days(300),
            contractType: .contractor, hiredAt: years(-2), avatarSeed: "elias"
        )
        // Dr Ali Alawi wears two hats: Technical Director (his User role) and
        // a hands-on coach. Sharing `userTD.id` keeps the two records linked
        // so his profile resolves to the same person across both surfaces.
        let coachAli = Coach(
            id: userTD.id,
            fullName: userTD.fullName, fullNameAr: userTD.fullNameAr,
            primaryBranchID: branchAlRahmania.id,
            secondaryBranchIDs: [branchAlNouf.id, branchAlNasserya.id, branchIndustrial18.id],
            danRank: 6, wtCoachLicenceLevel: 3,
            firstAidExpiry: days(300), safeguardingExpiry: days(330),
            contractType: .fullTime, hiredAt: years(-11), avatarSeed: userTD.avatarSeed
        )
        var coaches = [coachAli, coachYassin, coachAshraf, coachElias]

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
            branchID: branchAlNouf.id, primaryCoachID: coachYassin.id,
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
            branchID: branchAlNasserya.id, primaryCoachID: coachYassin.id,
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
            branchID: branchIndustrial18.id, primaryCoachID: coachAshraf.id,
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
            branchID: branchAlNouf.id, primaryCoachID: coachYassin.id,
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
            branchID: branchAlNasserya.id, primaryCoachID: coachYassin.id,
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
            branchID: branchIndustrial18.id, primaryCoachID: coachAshraf.id,
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
            branchID: branchAlNouf.id, primaryCoachID: coachElias.id,
            joinedAt: years(-1), currentBelt: belt(.white, .gup, 10, awardedDaysAgo: 30),
            weightKg: 30, status: .active, avatarSeed: "mansour"
        )
        let a8 = Athlete(
            memberNumber: 1008,
            fullName: "Tariq Al Nuaimi", fullNameAr: "طارق النعيمي",
            dateOfBirth: dob(age: 13), gender: .male,
            branchID: branchAlNasserya.id, primaryCoachID: coachYassin.id,
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
            branchID: branchIndustrial18.id, primaryCoachID: coachAshraf.id,
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
            branchID: branchAlNouf.id, primaryCoachID: coachElias.id,
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
            branchID: branchAlNasserya.id, primaryCoachID: coachYassin.id,
            joinedAt: years(-1), currentBelt: belt(.white, .gup, 10, awardedDaysAgo: 60),
            weightKg: 26, status: .active, avatarSeed: "faisal"
        )
        let a12 = Athlete(
            memberNumber: 1012,
            fullName: "Abdullah Al Mehairi", fullNameAr: "عبدالله المهيري",
            dateOfBirth: dob(age: 15), gender: .male,
            branchID: branchIndustrial18.id, primaryCoachID: coachAshraf.id,
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
            dateOfBirth: dob(age: 13), gender: .male,
            branchID: branchAlRahmania.id, primaryCoachID: coachAli.id,
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
            dateOfBirth: dob(age: 14), gender: .male,
            branchID: branchAlRahmania.id, primaryCoachID: coachAli.id,
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
            dateOfBirth: dob(age: 11), gender: .male,
            branchID: branchAlRahmania.id, primaryCoachID: coachAli.id,
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
            dateOfBirth: dob(age: 12), gender: .male,
            branchID: branchAlRahmania.id, primaryCoachID: coachAli.id,
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
            dateOfBirth: dob(age: 15), gender: .male,
            branchID: branchAlRahmania.id, primaryCoachID: coachAli.id,
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
            dateOfBirth: dob(age: 10), gender: .male,
            branchID: branchAlRahmania.id, primaryCoachID: coachAli.id,
            joinedAt: years(-1), currentBelt: belt(.white, .gup, 10, awardedDaysAgo: 40),
            weightKg: 28, status: .watch, avatarSeed: "shamma"
        )

        var athletes: [Athlete] = [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, g1, g2, g3, g4, g5, g6]

        // Seed weekly weight history for each athlete around their seeded
        // weightKg. Drift trends slightly upward (older entries lower) so the
        // chart shows a realistic curve.
        for i in athletes.indices {
            let base = athletes[i].weightKg
            var history: [WeightEntry] = []
            for daysBack in [56, 28, 14, 7, 0] {
                let drift = Double(daysBack) * 0.015
                let jitter = Double(i % 4) * 0.2 - 0.3
                let kg = max(15, base - drift + jitter)
                history.append(WeightEntry(recordedAt: days(-daysBack), weightKg: (kg * 10).rounded() / 10))
            }
            athletes[i].weightHistory = history
        }

        // === Coaching pathway: assistant coaches (Stage 1.15) ===
        // Assistant coaches are promoted athletes who keep competing while
        // learning to coach. They are Athletes carrying an embedded coaching
        // dossier — never a standalone entity. Yassin mentors two (Ahmed +
        // Rashid); Elias and Dr Ali mentor one each.
        let assistantCoachDossiers: [EntityID: AssistantCoachProfile] = [
            a1.id: AssistantCoachProfile(
                supervisingCoachID: coachYassin.id,
                primaryBranchID: branchAlNouf.id,
                supportBranchIDs: [branchAlNasserya.id],
                permissions: [.takeAttendance, .assistWarmUp, .assistDrills,
                              .monitorKidsGroups, .assistDuringClasses],
                developmentLevel: .assistantCoach,
                startedCoachingAt: days(-280),
                assistedSessionCount: 34,
                evaluations: [
                    CoachingEvaluation(
                        date: days(-30), evaluatorCoachID: coachYassin.id,
                        evaluatorName: coachYassin.fullName,
                        overallScore: 4, reliability: 4, leadership: 3,
                        notes: "Dependable with the cubs group. Build confidence leading warm-ups solo."
                    ),
                    CoachingEvaluation(
                        date: days(-160), evaluatorCoachID: coachYassin.id,
                        evaluatorName: coachYassin.fullName,
                        overallScore: 3, reliability: 4, leadership: 3,
                        notes: "Strong start. Encourage clearer instruction during drills."
                    ),
                ]
            ),
            a6.id: AssistantCoachProfile(
                supervisingCoachID: coachYassin.id,
                primaryBranchID: branchIndustrial18.id,
                supportBranchIDs: [branchAlNouf.id],
                permissions: Set(CoachingPermission.assistantCoachGrantable),
                developmentLevel: .juniorCoach,
                startedCoachingAt: days(-620),
                assistedSessionCount: 88,
                evaluations: [
                    CoachingEvaluation(
                        date: days(-21), evaluatorCoachID: coachYassin.id,
                        evaluatorName: coachYassin.fullName,
                        overallScore: 5, reliability: 5, leadership: 5,
                        notes: "Ready to run kids sessions independently. Strong candidate for Junior Coach promotion."
                    ),
                    CoachingEvaluation(
                        date: days(-120), evaluatorCoachID: coachYassin.id,
                        evaluatorName: coachYassin.fullName,
                        overallScore: 4, reliability: 5, leadership: 4,
                        notes: "Excellent rapport with athletes. Keep developing competition-corner experience."
                    ),
                    CoachingEvaluation(
                        date: days(-260), evaluatorCoachID: coachYassin.id,
                        evaluatorName: coachYassin.fullName,
                        overallScore: 4, reliability: 4, leadership: 4,
                        notes: "Reliable across both branches. Leadership growing fast."
                    ),
                ]
            ),
            a4.id: AssistantCoachProfile(
                supervisingCoachID: coachElias.id,
                primaryBranchID: branchAlNouf.id,
                supportBranchIDs: [],
                permissions: [.takeAttendance, .assistWarmUp, .assistDrills],
                developmentLevel: .assistantCoach,
                startedCoachingAt: days(-150),
                assistedSessionCount: 18,
                evaluations: [
                    CoachingEvaluation(
                        date: days(-40), evaluatorCoachID: coachElias.id,
                        evaluatorName: coachElias.fullName,
                        overallScore: 3, reliability: 3, leadership: 3,
                        notes: "Early days — pair with a senior assistant for the first months."
                    ),
                ]
            ),
            g5.id: AssistantCoachProfile(
                supervisingCoachID: coachAli.id,
                primaryBranchID: branchAlRahmania.id,
                supportBranchIDs: [branchAlNasserya.id],
                permissions: Set(CoachingPermission.assistantCoachGrantable),
                developmentLevel: .juniorCoach,
                startedCoachingAt: days(-500),
                assistedSessionCount: 71,
                evaluations: [
                    CoachingEvaluation(
                        date: days(-18), evaluatorCoachID: coachAli.id,
                        evaluatorName: coachAli.fullName,
                        overallScore: 5, reliability: 5, leadership: 4,
                        notes: "Outstanding with the juniors. Federation-grade coaching instincts."
                    ),
                    CoachingEvaluation(
                        date: days(-140), evaluatorCoachID: coachAli.id,
                        evaluatorName: coachAli.fullName,
                        overallScore: 4, reliability: 5, leadership: 4,
                        notes: "Consistent and trusted. Ready for more competition responsibility."
                    ),
                    CoachingEvaluation(
                        date: days(-300), evaluatorCoachID: coachAli.id,
                        evaluatorName: coachAli.fullName,
                        overallScore: 4, reliability: 4, leadership: 3,
                        notes: "Promising. Focus on projecting voice and presence in larger groups."
                    ),
                ]
            ),
        ]
        // Extra program-role memberships beyond the auto-derived ones.
        let extraProgramRoles: [EntityID: Set<ProgramRole>] = [
            g5.id: [.eliteSquad],
            g2.id: [.eliteSquad],
            a9.id: [.demoTeam],
        ]
        for i in athletes.indices {
            let id = athletes[i].id
            if athletes[i].status == .competitionTeam {
                athletes[i].programRoles.insert(.competitionTeam)
            }
            if let extra = extraProgramRoles[id] {
                athletes[i].programRoles.formUnion(extra)
            }
            if let dossier = assistantCoachDossiers[id] {
                athletes[i].assistantCoach = dossier
                athletes[i].programRoles.insert(.assistantCoach)
            }
        }

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
            (branchAlNouf, coachYassin, coachElias),
            (branchAlNasserya, coachYassin, coachAli),
            (branchIndustrial18, coachAshraf, coachElias),
            (branchAlRahmania, coachAli, coachYassin),
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
            weightCategoriesOffered: [.cadetsUnder45, .cadetsUnder53, .juniorsUnder55, .juniorsUnder63, .juniorsUnder73],
            level: .national,
            sanctioningBody: "UAE TKD Federation"
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
            weightCategoriesOffered: [.cadetsUnder45, .cadetsUnder53, .juniorsUnder55, .juniorsUnder63, .juniorsUnder73],
            level: .national,
            sanctioningBody: "UAE TKD Federation"
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

        // === Tournament registrations ===
        // 1) Past event — historical results so the Competition History card
        //    has rows. Final positions match the medal cycle in matches above.
        var registrations: [TournamentRegistration] = []
        for (idx, athlete) in competitionAthletes.enumerated() {
            guard let cat = WeightCategory.suggested(for: athlete) else { continue }
            let medal = [MedalType.gold, .silver, .bronze, .none, .gold][idx % 5]
            let position: Int = {
                switch medal {
                case .gold: return 1
                case .silver: return 2
                case .bronze: return 3
                case .none: return 4 + (idx % 4)
                }
            }()
            registrations.append(TournamentRegistration(
                tournamentID: pastTournament.id,
                athleteID: athlete.id,
                weightCategory: cat,
                seedRank: idx + 1,
                registeredAt: days(-50),
                status: .registered,
                ageDivisionEntered: athlete.ageGroup,
                bracketSize: 8 + (idx % 3) * 4,
                finalPosition: position,
                medal: medal == .none ? nil : medal
            ))
        }
        // 2) Upcoming event — pre-registration only.
        for (idx, athlete) in competitionAthletes.enumerated() {
            guard let cat = WeightCategory.suggested(for: athlete) else { continue }
            registrations.append(TournamentRegistration(
                tournamentID: upcomingTournament.id,
                athleteID: athlete.id,
                weightCategory: cat,
                seedRank: idx + 1,
                registeredAt: days(-7),
                status: .registered,
                ageDivisionEntered: athlete.ageGroup
            ))
        }

        // === Announcements — 14-item federation-grade feed.
        // NOTE: the first three appends are referenced by index in the audit
        // log below — keep publishers in the order userAdmin, userManager,
        // userTD so announcements[0/1/2] stay valid. ===
        var announcements: [Announcement] = []

        // [0] — publisher: userAdmin
        announcements.append(Announcement(
            title: "Q2 Training Schedule Update",
            titleAr: "تحديث جدول تدريبات الربع الثاني",
            body: "Updated training times take effect across all four branches starting next week. Junior and cadet groups move 30 minutes earlier on weekdays to ease evening congestion; competition-team sessions are unchanged. Speak to your branch coach for your new slot and confirm with the front desk if a clash arises.",
            bodyAr: "تدخل أوقات التدريب المحدّثة حيّز التنفيذ في الفروع الأربعة بدءاً من الأسبوع القادم. تنتقل مجموعات الناشئين والأشبال 30 دقيقة أبكر في أيام الأسبوع لتخفيف الازدحام المسائي؛ وتبقى حصص فريق المنافسة دون تغيير. راجع مدرب فرعك لمعرفة موعدك الجديد وأبلغ الاستقبال عند أي تعارض.",
            audience: .all,
            publishedAt: days(-2),
            publishedByUserID: userAdmin.id,
            status: .published,
            category: .general,
            imageAssetName: "announcement_q2_schedule",
            audiences: [.all],
            delivery: [
                AnnouncementDelivery(channel: .inApp, state: .delivered),
                AnnouncementDelivery(channel: .email, state: .sent)
            ],
            engagement: AnnouncementEngagement(recipients: 612, opened: 458, read: 401, clicks: 96),
            authorName: "Hanadi Al Kabouri"
        ))

        // [1] — publisher: userManager
        announcements.append(Announcement(
            branchID: branchAlNouf.id,
            title: "Al Nouf Mat Maintenance — Saturday",
            titleAr: "صيانة بساط النوف — يوم السبت",
            body: "The Al Nouf training hall mats will be deep-cleaned and re-taped this Saturday. All classes after 12:00 are cancelled for that day only. Affected groups will be offered a make-up session at Al Rahmania the following Tuesday — coaches will share the timing directly.",
            bodyAr: "سيتم تنظيف بساط قاعة تدريب النوف بعمق وإعادة تثبيت الأشرطة يوم السبت. تُلغى جميع الحصص بعد الساعة 12:00 لذلك اليوم فقط. ستُتاح للمجموعات المتأثرة حصة تعويضية في الرحمانية يوم الثلاثاء التالي — سيشارك المدربون التوقيت مباشرة.",
            audience: .coaches,
            publishedAt: days(-5),
            publishedByUserID: userManager.id,
            status: .published,
            category: .general,
            imageAssetName: "announcement_mat_maintenance",
            audiences: [.coaches, .branchManagers],
            delivery: [
                AnnouncementDelivery(channel: .inApp, state: .delivered),
                AnnouncementDelivery(channel: .sms, state: .sent)
            ],
            engagement: AnnouncementEngagement(recipients: 38, opened: 35, read: 33, clicks: 11),
            authorName: "Osama Al-Radini"
        ))

        // [2] — publisher: userTD — FEATURED summer camp item
        announcements.append(Announcement(
            title: "Summer Training Camp 2026",
            titleAr: "معسكر التدريب الصيفي 2026",
            body: "Registration is now open for our annual Summer Training Camp — eight intensive days of poomsae refinement, kyorugi sparring blocks, strength and conditioning, and recovery education led by the full coaching staff. Open to all athletes from green belt and above, plus assistant coaches seeking professional development. Places are limited and allocated on a first-confirmed basis. Review the attached schedule and packing list, then complete your registration before the deadline.",
            bodyAr: "التسجيل مفتوح الآن لمعسكرنا التدريبي الصيفي السنوي — ثمانية أيام مكثفة من صقل البومساي ووحدات قتال الكيوروغي والقوة واللياقة وتثقيف الاستشفاء بقيادة طاقم التدريب بالكامل. مفتوح لجميع الرياضيين من الحزام الأخضر فما فوق، إضافة إلى المدربين المساعدين الراغبين في التطوير المهني. الأماكن محدودة وتُخصّص على أساس أسبقية التأكيد. راجع الجدول وقائمة التجهيزات المرفقين ثم أكمل تسجيلك قبل الموعد النهائي.",
            audience: .athletes,
            publishedAt: days(-3),
            publishedByUserID: userTD.id,
            status: .published,
            category: .event,
            imageAssetName: "announcement_summer_camp",
            audiences: [.athletes, .coaches, .branchManagers],
            location: "Fujairah Training Center",
            eventStart: days(35),
            eventEnd: days(42),
            registrationDeadline: days(25),
            delivery: [
                AnnouncementDelivery(channel: .email, state: .sent),
                AnnouncementDelivery(channel: .inApp, state: .delivered),
                AnnouncementDelivery(channel: .sms, state: .sent)
            ],
            engagement: AnnouncementEngagement(recipients: 624, opened: 482, read: 412, clicks: 128),
            attachments: [
                AnnouncementAttachment(name: "Camp_Schedule_2026.pdf", detail: "PDF · 1.2 MB"),
                AnnouncementAttachment(name: "Packing_List.pdf", detail: "PDF · 856 KB")
            ],
            authorName: "Dr Ali Alawi"
        ))

        // [3] — Kyorugi championship registration (scheduled)
        announcements.append(Announcement(
            title: "Kyorugi Championship Registration",
            titleAr: "تسجيل بطولة الكيوروغي",
            body: "Registration for the Emirates Kyorugi Championship will open next week. Eligible athletes are those on the competition team with a current medical clearance and a verified weight category. Coaches will confirm divisions before submission — do not register independently. A briefing on rule changes for the new season will follow.",
            bodyAr: "سيُفتح التسجيل لبطولة الإمارات للكيوروغي الأسبوع القادم. الرياضيون المؤهلون هم أعضاء فريق المنافسة الحاصلون على تصريح طبي ساري وفئة وزن موثّقة. سيؤكد المدربون الفئات قبل التقديم — لا تسجّل بشكل مستقل. سيتبع ذلك إيجاز حول تغييرات القواعد للموسم الجديد.",
            audience: .athletes,
            publishedAt: days(-1),
            publishedByUserID: userTD.id,
            status: .scheduled,
            category: .registration,
            imageAssetName: "announcement_kyorugi_registration",
            scheduledAt: days(7),
            audiences: [.athletes],
            registrationDeadline: days(28),
            authorName: "Dr Ali Alawi"
        ))

        // [4] — New grading system update (published, coaches)
        announcements.append(Announcement(
            title: "New Grading System Update",
            titleAr: "تحديث نظام الترقيات",
            body: "The promotion criteria have been revised for the 2026 season. Poomsae now carries a dedicated technical-precision band, kyorugi assessment moves to a three-round format, and a minimum attendance threshold applies to every belt level. All coaches must review the updated rubric in the Grading module before conducting their next test.",
            bodyAr: "تمت مراجعة معايير الترقية لموسم 2026. أصبح للبومساي نطاق دقّة تقنية مخصّص، وانتقل تقييم الكيوروغي إلى صيغة من ثلاث جولات، ويُطبَّق حد أدنى للحضور على كل مستوى حزام. على جميع المدربين مراجعة الدليل المحدّث في وحدة الترقيات قبل إجراء الاختبار القادم.",
            audience: .coaches,
            publishedAt: days(-6),
            publishedByUserID: userTD.id,
            status: .published,
            category: .grading,
            imageAssetName: "announcement_grading_update",
            audiences: [.coaches],
            delivery: [
                AnnouncementDelivery(channel: .inApp, state: .delivered),
                AnnouncementDelivery(channel: .email, state: .sent)
            ],
            engagement: AnnouncementEngagement(recipients: 42, opened: 40, read: 38, clicks: 22),
            attachments: [
                AnnouncementAttachment(name: "Grading_Rubric_2026.pdf", detail: "PDF · 640 KB")
            ],
            authorName: "Dr Ali Alawi"
        ))

        // [5] — SSDC in-house tournament (draft)
        announcements.append(Announcement(
            title: "SSDC In-House Tournament",
            titleAr: "بطولة النادي الداخلية",
            body: "Planning is underway for an inter-branch in-house tournament to give every athlete competitive mat time in a friendly setting. The format will mix poomsae and light-contact kyorugi divisions by age and belt. Details, venue, and the registration window will be confirmed once the calendar is finalised.",
            bodyAr: "يجري التخطيط لبطولة داخلية بين الفروع لمنح كل رياضي وقتاً تنافسياً على البساط في أجواء ودّية. ستجمع الصيغة بين فئات البومساي والكيوروغي خفيف التلامس حسب العمر والحزام. ستُؤكَّد التفاصيل والمكان ونافذة التسجيل عند اعتماد الجدول.",
            audience: .all,
            publishedAt: days(-1),
            publishedByUserID: userTD.id,
            status: .draft,
            category: .tournament,
            imageAssetName: "announcement_inhouse_tournament",
            audiences: [.all],
            authorName: "Dr Ali Alawi"
        ))

        // [6] — Dojo rules & code of conduct (published)
        announcements.append(Announcement(
            title: "Dojo Rules & Code of Conduct",
            titleAr: "قواعد الدوجو ومدونة السلوك",
            body: "Our updated code of conduct is now in effect at every branch. It covers punctuality and uniform standards, respect for instructors and training partners, hygiene requirements, and the safeguarding policy. Athletes and parents are asked to read it together and acknowledge it at the front desk before the next training block.",
            bodyAr: "مدونة السلوك المحدّثة الخاصة بنا سارية الآن في كل فرع. تغطي الالتزام بالمواعيد ومعايير الزي، واحترام المدربين وزملاء التدريب، ومتطلبات النظافة، وسياسة حماية النشء. يُرجى من الرياضيين وأولياء الأمور قراءتها معاً والإقرار بها في الاستقبال قبل الفترة التدريبية القادمة.",
            audience: .all,
            publishedAt: days(-12),
            publishedByUserID: userAdmin.id,
            status: .published,
            category: .policy,
            imageAssetName: "announcement_code_of_conduct",
            audiences: [.all],
            delivery: [
                AnnouncementDelivery(channel: .inApp, state: .delivered),
                AnnouncementDelivery(channel: .email, state: .sent)
            ],
            engagement: AnnouncementEngagement(recipients: 598, opened: 503, read: 461, clicks: 174),
            attachments: [
                AnnouncementAttachment(name: "Code_of_Conduct.pdf", detail: "PDF · 410 KB")
            ],
            authorName: "Hanadi Al Kabouri"
        ))

        // [7] — Outstanding athlete recognition (published)
        announcements.append(Announcement(
            title: "Outstanding Athlete Recognition",
            titleAr: "تكريم الرياضي المتميز",
            body: "Congratulations to the athletes named in this quarter's Outstanding Recognition list for their results at the UAE Junior Open and their consistency in training. Their dedication sets the standard for the whole club. Certificates will be presented at the next family open evening — full names appear on the branch noticeboards.",
            bodyAr: "تهانينا للرياضيين المدرجين في قائمة التكريم المتميز لهذا الربع على نتائجهم في بطولة الإمارات للناشئين وثباتهم في التدريب. يضع تفانيهم المعيار للنادي بأكمله. ستُسلَّم الشهادات في الأمسية العائلية المفتوحة القادمة — تظهر الأسماء الكاملة على لوحات الإعلانات في الفروع.",
            audience: .all,
            publishedAt: days(-8),
            publishedByUserID: userAdmin.id,
            status: .published,
            category: .recognition,
            imageAssetName: "announcement_athlete_recognition",
            audiences: [.all],
            delivery: [
                AnnouncementDelivery(channel: .inApp, state: .delivered),
                AnnouncementDelivery(channel: .email, state: .sent)
            ],
            engagement: AnnouncementEngagement(recipients: 605, opened: 521, read: 478, clicks: 209),
            authorName: "Hanadi Al Kabouri"
        ))

        // [8] — Belt grading results (published)
        announcements.append(Announcement(
            title: "May Belt Grading Results",
            titleAr: "نتائج اختبار الأحزمة لشهر مايو",
            body: "Results from the May belt grading are now published. Athletes who passed will receive their new belts at their next session; those advised to re-test should arrange a follow-up with their coach. Individual feedback notes have been added to each athlete's profile in the app.",
            bodyAr: "نتائج اختبار الأحزمة لشهر مايو منشورة الآن. سيستلم الرياضيون الناجحون أحزمتهم الجديدة في حصتهم القادمة؛ وعلى من نُصحوا بإعادة الاختبار ترتيب جلسة متابعة مع مدربهم. أُضيفت ملاحظات تقييم فردية إلى ملف كل رياضي في التطبيق.",
            audience: .parents,
            publishedAt: days(-4),
            publishedByUserID: userTD.id,
            status: .published,
            category: .grading,
            imageAssetName: "announcement_grading_results",
            audiences: [.parents, .athletes],
            delivery: [
                AnnouncementDelivery(channel: .inApp, state: .delivered),
                AnnouncementDelivery(channel: .email, state: .sent),
                AnnouncementDelivery(channel: .sms, state: .delivered)
            ],
            engagement: AnnouncementEngagement(recipients: 286, opened: 252, read: 231, clicks: 88),
            authorName: "Dr Ali Alawi"
        ))

        // [9] — Industrial 18 branch maintenance closure (scheduled)
        announcements.append(Announcement(
            branchID: branchIndustrial18.id,
            title: "Industrial 18 — Air-Conditioning Upgrade",
            titleAr: "الصناعية 18 — ترقية نظام التكييف",
            body: "The Industrial 18 branch will close for two days while the air-conditioning system is upgraded ahead of the summer season. Classes during the closure move to Al Nasserya at the same times. Normal operations resume immediately afterwards.",
            bodyAr: "سيُغلق فرع الصناعية 18 لمدة يومين أثناء ترقية نظام التكييف استعداداً لموسم الصيف. تُنقل الحصص خلال فترة الإغلاق إلى الناصرية في نفس الأوقات. تستأنف العمليات الاعتيادية مباشرة بعد ذلك.",
            audience: .all,
            publishedAt: days(-1),
            publishedByUserID: userManager.id,
            status: .scheduled,
            category: .general,
            imageAssetName: "announcement_branch_maintenance",
            scheduledAt: days(5),
            audiences: [.all],
            authorName: "Osama Al-Radini"
        ))

        // [10] — Parent meeting (published, RSVP)
        announcements.append(Announcement(
            title: "Parent Information Evening",
            titleAr: "أمسية إعلامية لأولياء الأمور",
            body: "All parents are invited to a Parent Information Evening covering the new grading system, the competition calendar, and the summer camp programme. There will be time for questions with the technical director and branch managers. Light refreshments will be served — please RSVP so we can plan seating.",
            bodyAr: "جميع أولياء الأمور مدعوون إلى أمسية إعلامية تتناول نظام الترقيات الجديد وجدول المنافسات وبرنامج المعسكر الصيفي. سيتوفر وقت للأسئلة مع المدير الفني ومديري الفروع. ستُقدَّم مرطبات خفيفة — يُرجى تأكيد الحضور لنتمكن من ترتيب المقاعد.",
            audience: .parents,
            publishedAt: days(-3),
            publishedByUserID: userManager.id,
            requiresRSVP: true,
            rsvpDeadline: days(6),
            status: .published,
            category: .event,
            imageAssetName: "announcement_parent_meeting",
            audiences: [.parents],
            location: "Al Rahmania Main Hall",
            eventStart: days(9),
            eventEnd: days(9),
            delivery: [
                AnnouncementDelivery(channel: .inApp, state: .delivered),
                AnnouncementDelivery(channel: .email, state: .sent),
                AnnouncementDelivery(channel: .sms, state: .sent)
            ],
            engagement: AnnouncementEngagement(recipients: 286, opened: 241, read: 218, clicks: 134),
            authorName: "Osama Al-Radini"
        ))

        // [11] — Referee & coaching clinic (published, coaches)
        announcements.append(Announcement(
            title: "Referee & Officiating Clinic",
            titleAr: "ورشة التحكيم وإدارة المباريات",
            body: "A one-day referee and officiating clinic will be hosted at Al Rahmania for coaches and senior assistant coaches. The clinic covers the updated electronic scoring protocol, video-review procedure, and mat management. Attendance counts toward annual professional-development hours — confirm your place with your branch manager.",
            bodyAr: "ستُقام ورشة تحكيم وإدارة مباريات لمدة يوم واحد في الرحمانية للمدربين والمدربين المساعدين الكبار. تغطي الورشة بروتوكول التسجيل الإلكتروني المحدّث وإجراء المراجعة بالفيديو وإدارة البساط. يُحتسب الحضور ضمن ساعات التطوير المهني السنوية — أكّد مكانك مع مدير فرعك.",
            audience: .coaches,
            publishedAt: days(-7),
            publishedByUserID: userTD.id,
            status: .published,
            category: .event,
            imageAssetName: "announcement_referee_clinic",
            audiences: [.coaches, .branchManagers],
            location: "Al Rahmania Main Hall",
            eventStart: days(14),
            eventEnd: days(14),
            registrationDeadline: days(11),
            delivery: [
                AnnouncementDelivery(channel: .inApp, state: .delivered),
                AnnouncementDelivery(channel: .email, state: .sent)
            ],
            engagement: AnnouncementEngagement(recipients: 42, opened: 39, read: 36, clicks: 24),
            authorName: "Dr Ali Alawi"
        ))

        // [12] — Eid holiday closure (scheduled)
        announcements.append(Announcement(
            title: "Eid Al Adha Holiday Closure",
            titleAr: "إغلاق عطلة عيد الأضحى",
            body: "All branches will be closed for the Eid Al Adha holiday. No classes or grading sessions will run during the closure period. Training resumes on the regular schedule the morning after the holiday — competition-team athletes will receive an individual conditioning plan to follow at home.",
            bodyAr: "ستُغلق جميع الفروع بمناسبة عطلة عيد الأضحى. لن تُقام أي حصص أو اختبارات ترقية خلال فترة الإغلاق. يستأنف التدريب وفق الجدول المعتاد صباح اليوم التالي للعطلة — سيتلقى رياضيو فريق المنافسة خطة لياقة فردية لاتباعها في المنزل.",
            audience: .all,
            publishedAt: days(-2),
            publishedByUserID: userAdmin.id,
            status: .scheduled,
            category: .policy,
            imageAssetName: "announcement_eid_closure",
            scheduledAt: days(20),
            audiences: [.all],
            authorName: "Hanadi Al Kabouri"
        ))

        // [13] — New uniform supplier (archived)
        announcements.append(Announcement(
            title: "New Approved Uniform Supplier",
            titleAr: "مورّد الزي المعتمد الجديد",
            body: "The club has appointed a new approved supplier for doboks, belts, and protective gear at improved member pricing. Orders placed through the front desk are delivered to your branch within one week. This notice has been archived now that the transition is complete and stock is fully available.",
            bodyAr: "عيّن النادي مورّداً معتمداً جديداً للزي والأحزمة وأدوات الحماية بأسعار محسّنة للأعضاء. تُسلَّم الطلبات المقدّمة عبر الاستقبال إلى فرعك خلال أسبوع واحد. تمت أرشفة هذا الإشعار بعد اكتمال الانتقال وتوفر المخزون بالكامل.",
            audience: .parents,
            publishedAt: days(-45),
            publishedByUserID: userManager.id,
            status: .archived,
            category: .general,
            imageAssetName: "announcement_uniform_supplier",
            audiences: [.parents, .athletes],
            delivery: [
                AnnouncementDelivery(channel: .inApp, state: .delivered),
                AnnouncementDelivery(channel: .email, state: .sent)
            ],
            engagement: AnnouncementEngagement(recipients: 564, opened: 388, read: 312, clicks: 141),
            authorName: "Osama Al-Radini"
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

        // === Physical metrics: spread across kinds, sampled at each kind's
        // natural cadence (weekly/monthly/quarterly), status-tier scaled. ===
        var physicalMetrics: [PhysicalMetric] = []
        for athlete in athletes {
            let coachID = athlete.primaryCoachID ?? coachYassin.id
            // Quality tier 0..10 — drives where in each metric's range the
            // athlete sits. readyToGrade lands in the upper half so it passes
            // the eligibility composite (>=60).
            let q: Double = {
                switch athlete.status {
                case .competitionTeam: return 8
                case .readyToGrade: return 7
                case .active: return 5
                case .rest: return 4
                case .watch: return 3
                }
            }()
            // For each kind, generate samples at its frequency over a 90-day
            // window. Body weight is captured under `weightHistory` (single
            // source of truth wired into the metrics card), so it's excluded
            // here.
            for kind in PhysicalMetricKind.allCases where kind != .bodyWeightKg {
                let samplesBack: [Int] = switch kind.frequency {
                case .weekly: [0, 7, 14, 28, 56]
                case .monthly: [0, 30, 60]
                case .quarterly: [0, 90]
                }
                for daysBack in samplesBack {
                    let drift = Double(daysBack) / 180.0  // older = slightly worse
                    let effective = max(1.0, q - drift)
                    let v = seedValue(for: kind, quality: effective, leg: nil)
                    if kind.isUnilateral {
                        for side in BodySide.allCases {
                            let bias = side == .left ? -0.4 : 0.4
                            let leftRight = seedValue(for: kind, quality: max(1.0, effective + bias), leg: side)
                            physicalMetrics.append(PhysicalMetric(
                                athleteID: athlete.id,
                                recordedAt: days(-daysBack),
                                recordedByCoachID: coachID,
                                kind: kind,
                                value: leftRight,
                                leg: side
                            ))
                        }
                    } else {
                        physicalMetrics.append(PhysicalMetric(
                            athleteID: athlete.id,
                            recordedAt: days(-daysBack),
                            recordedByCoachID: coachID,
                            kind: kind,
                            value: v
                        ))
                    }
                }
            }
        }

        // === Technical skills: each athlete gets latest captures across a
        // representative subset of techniques per category, status-tier
        // scaled. Application typically lags form by 1 point. ===
        var technicalSkills: [TechnicalSkill] = []
        for athlete in athletes {
            let coachID = athlete.primaryCoachID ?? coachYassin.id
            let baseForm: Int = {
                switch athlete.status {
                case .competitionTeam: return 8
                case .readyToGrade: return 7
                case .active: return 6
                case .rest: return 5
                case .watch: return 4
                }
            }()
            // Pick a stable subset per category so the dashboard shows partial
            // coverage (matching real coach workflow: not every technique is
            // assessed on every athlete).
            let kinds: [TechniqueKind] = [
                .frontKick, .roundhouseBack, .roundhouseFront, .sideKick, .axeKick,
                .spinningHookKick, .tornadoKick,
                .jabPunch, .crossPunch,
                .switchStep, .pushStep, .pivot,
                .blockHigh, .blockMiddle, .parry
            ]
            for (offset, kind) in kinds.enumerated() {
                let monthBack = offset % 3
                let bias = (offset % 5) - 2  // small per-technique variation
                let form = max(1, min(10, baseForm + bias))
                let app = max(1, min(10, form - 1))
                technicalSkills.append(TechnicalSkill(
                    athleteID: athlete.id,
                    recordedAt: monthsAgo(monthBack),
                    recordedByCoachID: coachID,
                    kind: kind,
                    formScore: form,
                    applicationScore: app
                ))
            }
        }

        // === Poomsae specialists: tag every 4th athlete as poomsae-track and
        // populate their repertoire + a baseline assessment for the form
        // matching their current belt. Coaches can extend through the UI. ===
        var poomsaeAssessments: [PoomsaeAssessment] = []
        for i in athletes.indices where i % 4 == 0 {
            athletes[i].specialty = i % 8 == 0 ? .both : .poomsae
            let belt = athletes[i].currentBelt
            let allForms = PoomsaeForm.allCases
            athletes[i].poomsaeKnown = Set(allForms.filter { $0.isRequired(for: belt) })
            // Latest assessment for the highest-tier required form (last in
            // the canonical CaseIterable order).
            if let topForm = allForms.last(where: { $0.isRequired(for: belt) }) {
                let coachID = athletes[i].primaryCoachID ?? coachYassin.id
                let baseline: Int = {
                    switch athletes[i].status {
                    case .competitionTeam: return 8
                    case .readyToGrade: return 7
                    case .active: return 6
                    case .rest: return 5
                    case .watch: return 4
                    }
                }()
                poomsaeAssessments.append(PoomsaeAssessment(
                    athleteID: athletes[i].id,
                    recordedAt: monthsAgo(0),
                    recordedByCoachID: coachID,
                    form: topForm,
                    accuracy: baseline,
                    presentation: max(1, baseline - 1),
                    balance: baseline,
                    expression: max(1, baseline - 1),
                    timeSeconds: 60 + (i % 4) * 8
                ))
            }
        }

        // === Training load: 4–5 sessions per athlete over the last 28 days,
        // status-tier scaled. Lets the demo show a non-zero ACWR. ===
        var trainingLoad: [TrainingLoadEntry] = []
        let typeCycle: [SessionType] = [.technique, .sparring, .fitness, .poomsae, .mixed]
        for (idx, athlete) in athletes.enumerated() {
            let baseRPE: Int = {
                switch athlete.status {
                case .competitionTeam: return 7
                case .readyToGrade, .active: return 6
                case .rest, .watch: return 4
                }
            }()
            let baseDuration: Int = athlete.status == .competitionTeam ? 90 : 60
            for session in 0..<6 {
                let daysBack = session * 4 + (idx % 3)
                trainingLoad.append(TrainingLoadEntry(
                    athleteID: athlete.id,
                    recordedAt: days(-daysBack),
                    sessionType: typeCycle[(idx + session) % typeCycle.count],
                    durationMinutes: max(20, baseDuration + ((session * 5) % 30) - 10),
                    rpe: max(1, min(10, baseRPE + ((session + idx) % 3) - 1))
                ))
            }
        }

        // === Drill library: starter catalog covering each category, with
        // Pillar 11 metadata (weakness tags matching enum raw values, belt
        // ranges, equipment, difficulty). ===
        // Explicit IDs for the handful of drills that cross-reference each other.
        let sprintRepeatsId = UUID()
        let boxJumpsId = UUID()
        let frontSplitId = UUID()
        let counterAttackId = UUID()
        let tornadoKickId = UUID()
        let slipPadLadderId = UUID()
        let pushStepComboId = UUID()
        let openStanceId = UUID()

        let drills: [DrillLibraryEntry] = [
            // 1 — technique
            DrillLibraryEntry(id: slipPadLadderId,
                              name: "Slip-pad roundhouse ladder",
                              nameAr: "سلم ركلات على المخدة",
                              category: .technique,
                              summary: "Athlete chains 4 roundhouse kicks on the pad with a partner moving forward each rep.",
                              durationMinutes: 8,
                              addressesWeaknessTags: ["roundhouseBack", "roundhouseFront", "roundhouseKicks10s"],
                              minBelt: BeltRank(kind: .gup, number: 8),
                              equipmentRequired: ["kick pad"],
                              difficulty: .beginner,
                              tags: ["Technique", "Combinations", "Pad Work"],
                              intensity: 3,
                              instructions: [
                                  "Pair athletes — one holds the kick pad at chest height, the other kicks.",
                                  "The kicker throws a lead-leg roundhouse, resets stance, and immediately fires again.",
                                  "After each rep the pad holder steps one pace forward, forcing the kicker to adjust distance.",
                                  "Chain four clean roundhouse kicks before switching legs.",
                                  "Complete three rounds per leg, swapping holder and kicker between rounds."
                              ],
                              coachingTip: "Watch the chambering knee — it should lift fully before the hip rotates, not after.",
                              equipment: [
                                  DrillEquipmentItem(name: "Kick pad", quantityNote: "1 per pair", systemIcon: "shield.fill")
                              ],
                              muscleFocus: ["Hip flexors", "Quads", "Glutes", "Core", "Calves"],
                              metrics: DrillMetrics(sets: 3, rest: "30 sec", totalTime: "8 min", spaceRequired: "3 m lane", athleteLevelNote: "Beginner+"),
                              variations: [
                                  DrillVariation(title: "Retreating holder",
                                                 detail: "Holder steps back instead of forward, forcing the kicker to close distance with a push-step before each kick."),
                                  DrillVariation(title: "Count-down ladder",
                                                 detail: "Start at five kicks per chain and drop one each round down to a single explosive kick.")
                              ],
                              notes: "A staple warm-up technique drill. Keep the tempo brisk so it doubles as light conditioning.",
                              relatedDrillIDs: [tornadoKickId, pushStepComboId],
                              imageAssetName: "drill_slip_pad_ladder",
                              videoDurationSeconds: 52),
            // 2 — sparring
            DrillLibraryEntry(id: counterAttackId,
                              name: "Counter-attack cycle",
                              nameAr: "دورة الهجوم المضاد",
                              category: .sparring,
                              summary: "Coach feeds an opening attack; athlete retreats, parries, and counters within 1 second.",
                              durationMinutes: 10,
                              addressesWeaknessTags: ["reactionMs", "parry"],
                              minBelt: BeltRank(kind: .gup, number: 4),
                              equipmentRequired: ["headgear", "chest protector"],
                              difficulty: .intermediate,
                              tags: ["Sparring", "Reaction", "Counters"],
                              intensity: 4,
                              instructions: [
                                  "Set athletes in fighting stance at sparring distance with full protective gear on.",
                                  "The coach or partner initiates a single committed attack with no warning.",
                                  "The athlete reads the attack, retreats half a step, and parries or blocks it.",
                                  "Within one second of the parry, the athlete fires a counter to the open target.",
                                  "Reset to neutral and repeat for 60 seconds, then rotate the feeding role.",
                                  "Run three rounds per athlete, increasing feed speed each round."
                              ],
                              coachingTip: "Reward the counter that lands fastest after the parry, not the hardest one.",
                              equipment: [
                                  DrillEquipmentItem(name: "Headgear", quantityNote: "1 per athlete", systemIcon: "brain.head.profile"),
                                  DrillEquipmentItem(name: "Chest protector", quantityNote: "1 per athlete", systemIcon: "shield.lefthalf.filled"),
                                  DrillEquipmentItem(name: "Stopwatch", systemIcon: "stopwatch.fill")
                              ],
                              muscleFocus: ["Shoulders", "Core", "Hip flexors", "Calves"],
                              metrics: DrillMetrics(sets: 3, rest: "60 sec", totalTime: "10 min", spaceRequired: "Sparring ring", athleteLevelNote: "Green belt and above"),
                              variations: [
                                  DrillVariation(title: "Double feed",
                                                 detail: "The feeder throws two attacks in sequence; the athlete must defend both before countering.")
                              ],
                              notes: "Cornerstone of competition prep. Pair athletes of similar reach so distance reads stay realistic.",
                              relatedDrillIDs: [openStanceId, slipPadLadderId],
                              imageAssetName: "drill_counter_attack_cycle",
                              videoDurationSeconds: 68),
            // 3 — flexibility
            DrillLibraryEntry(id: frontSplitId,
                              name: "Front-split progression",
                              nameAr: "تدرج الانقسام الأمامي",
                              category: .flexibility,
                              summary: "PNF stretching for hip flexors + hamstrings, 3 × 30 s hold per side.",
                              durationMinutes: 6,
                              addressesWeaknessTags: ["frontSplitCm", "legRaiseAngle"],
                              equipmentRequired: ["yoga block"],
                              difficulty: .beginner,
                              tags: ["Flexibility", "Mobility", "Recovery"],
                              intensity: 2,
                              instructions: [
                                  "Warm up the hips with two minutes of leg swings before stretching.",
                                  "Slide into a front-split position, front heel down and back knee tracking the floor.",
                                  "Rest the hands on yoga blocks to control depth and protect the lower back.",
                                  "Hold the deepest pain-free position for 30 seconds while breathing slowly.",
                                  "Contract the hamstrings against the floor for six seconds, then relax and sink deeper.",
                                  "Repeat for three holds per side."
                              ],
                              coachingTip: "Keep the back hip square to the front — a rotated pelvis hides a false split.",
                              equipment: [
                                  DrillEquipmentItem(name: "Yoga block", quantityNote: "2 per athlete", systemIcon: "rectangle.fill"),
                                  DrillEquipmentItem(name: "Mat", quantityNote: "1 per athlete", systemIcon: "square.fill")
                              ],
                              muscleFocus: ["Hamstrings", "Hip flexors", "Adductors", "Glutes"],
                              metrics: DrillMetrics(sets: 3, rest: "20 sec", totalTime: "6 min", spaceRequired: "2 m mat", athleteLevelNote: "All levels"),
                              variations: [
                                  DrillVariation(title: "Elevated front foot",
                                                 detail: "Raise the front heel on a low box to bias the stretch toward the hamstring."),
                                  DrillVariation(title: "Partner-assisted",
                                                 detail: "A partner applies gentle downward pressure on the hips during the relaxation phase only.")
                              ],
                              notes: "Best done at the end of a session when muscles are warm. Never bounce into the stretch.",
                              relatedDrillIDs: [],
                              imageAssetName: "drill_front_split_progression",
                              videoDurationSeconds: 40),
            // 4 — conditioning (locked spec)
            DrillLibraryEntry(id: sprintRepeatsId,
                              name: "20 m sprint repeats",
                              nameAr: "تكرار العدو 20 متر",
                              category: .conditioning,
                              summary: "Improve speed, endurance, and explosive power.",
                              durationMinutes: 12,
                              addressesWeaknessTags: ["sprint20mSec"],
                              equipmentRequired: ["cones", "stopwatch"],
                              difficulty: .intermediate,
                              tags: ["Conditioning", "Cardio", "Speed"],
                              intensity: 4,
                              instructions: [
                                  "Set up a 20 meter distance with cones at start and finish.",
                                  "Sprint at maximum intensity to the finish line.",
                                  "Walk back to the start line for recovery.",
                                  "Rest for 45 seconds.",
                                  "Repeat for a total of 6 sets."
                              ],
                              coachingTip: "Encourage athletes to maintain good posture and arm drive throughout the sprint.",
                              equipment: [
                                  DrillEquipmentItem(name: "Cones", quantityNote: "2+", systemIcon: "cone.fill"),
                                  DrillEquipmentItem(name: "Stopwatch", systemIcon: "stopwatch.fill")
                              ],
                              muscleFocus: ["Quads", "Hamstrings", "Calves", "Glutes", "Core"],
                              metrics: DrillMetrics(sets: 6, distance: "20 m", rest: "45 sec", totalTime: "12 min", spaceRequired: "20 m+", athleteLevelNote: "All levels"),
                              variations: [
                                  DrillVariation(title: "Flying start",
                                                 detail: "Begin with a 5 m rolling approach so the timed segment is at full speed."),
                                  DrillVariation(title: "Resisted sprints",
                                                 detail: "Attach a light resistance band or sled for the first three sets, then sprint free for the last three.")
                              ],
                              notes: "Track each athlete's fastest set to monitor speed progression over the training block.",
                              relatedDrillIDs: [boxJumpsId],
                              imageAssetName: "drill_sprint_repeats",
                              videoDurationSeconds: 45),
            // 5 — conditioning
            DrillLibraryEntry(id: boxJumpsId,
                              name: "Plyometric box jumps",
                              nameAr: "قفز الصندوق",
                              category: .conditioning,
                              summary: "5 × 6 box jumps targeting peak power output, full recovery between sets.",
                              durationMinutes: 8,
                              addressesWeaknessTags: ["verticalJumpCm", "broadJumpCm"],
                              minBelt: BeltRank(kind: .gup, number: 6),
                              equipmentRequired: ["plyo box (24 in)"],
                              difficulty: .intermediate,
                              tags: ["Conditioning", "Power", "Explosive"],
                              intensity: 4,
                              instructions: [
                                  "Place a 24-inch plyo box on a flat, non-slip surface.",
                                  "Stand a half-step back from the box in an athletic quarter-squat.",
                                  "Swing the arms and drive explosively up onto the box, landing soft with bent knees.",
                                  "Stand fully tall on the box, then step — never jump — back down.",
                                  "Perform six maximal jumps, then rest fully before the next set.",
                                  "Complete five sets, stopping if landing height visibly drops."
                              ],
                              coachingTip: "Quality over quantity — cut the set short the moment landings stop being quiet and controlled.",
                              equipment: [
                                  DrillEquipmentItem(name: "Plyo box (24 in)", quantityNote: "1 per athlete", systemIcon: "cube.fill")
                              ],
                              muscleFocus: ["Quads", "Glutes", "Calves", "Hamstrings"],
                              metrics: DrillMetrics(sets: 5, rest: "90 sec", totalTime: "8 min", spaceRequired: "2 m clear", athleteLevelNote: "Blue belt and above"),
                              variations: [
                                  DrillVariation(title: "Lateral box jump",
                                                 detail: "Approach and land sideways onto the box to train frontal-plane power."),
                                  DrillVariation(title: "Depth jump",
                                                 detail: "Step off the box and rebound immediately into a vertical jump for advanced athletes only.")
                              ],
                              notes: "Always step down to protect the knees and Achilles. Schedule early in the session while fresh.",
                              relatedDrillIDs: [sprintRepeatsId],
                              imageAssetName: "drill_box_jumps",
                              videoDurationSeconds: 50),
            // 6 — footwork
            DrillLibraryEntry(name: "Single-leg balance circuit",
                              nameAr: "دائرة التوازن على ساق واحدة",
                              category: .footwork,
                              summary: "30 s eyes-open + 30 s eyes-closed per leg, 3 rounds.",
                              durationMinutes: 6,
                              addressesWeaknessTags: ["singleLegSquatReps"],
                              equipmentRequired: [],
                              difficulty: .beginner,
                              tags: ["Footwork", "Balance", "Stability"],
                              intensity: 2,
                              instructions: [
                                  "Stand tall and lift one foot a few inches off the floor.",
                                  "Hold a stable single-leg stance with eyes open for 30 seconds.",
                                  "Close the eyes and hold the same stance for a further 30 seconds.",
                                  "Switch legs and repeat the eyes-open then eyes-closed sequence.",
                                  "Complete three full rounds, adding small arm movements to challenge balance."
                              ],
                              coachingTip: "Cue athletes to grip the floor with the toes and fix the gaze before closing the eyes.",
                              equipment: [
                                  DrillEquipmentItem(name: "Balance pad", quantityNote: "Optional", systemIcon: "square.stack.3d.up.fill")
                              ],
                              muscleFocus: ["Calves", "Ankles", "Core", "Glutes"],
                              metrics: DrillMetrics(sets: 3, rest: "15 sec", totalTime: "6 min", spaceRequired: "1 m square", athleteLevelNote: "All levels"),
                              variations: [
                                  DrillVariation(title: "Unstable surface",
                                                 detail: "Perform the holds on a balance pad or folded mat to increase ankle demand.")
                              ],
                              notes: "Excellent low-intensity filler between high-power drills or during injury rehab.",
                              relatedDrillIDs: [],
                              imageAssetName: "drill_single_leg_balance",
                              videoDurationSeconds: 38),
            // 7 — technique
            DrillLibraryEntry(id: tornadoKickId,
                              name: "Tornado kick drill",
                              nameAr: "تمرين ركلة الإعصار",
                              category: .technique,
                              summary: "Lead-leg setup → 360° spin into roundhouse on pad. 3 × 5 reps.",
                              durationMinutes: 10,
                              addressesWeaknessTags: ["tornadoKick", "spinningHookKick"],
                              minBelt: BeltRank(kind: .gup, number: 2),
                              equipmentRequired: ["kick pad"],
                              difficulty: .advanced,
                              tags: ["Technique", "Spinning Kicks", "Pad Work"],
                              intensity: 4,
                              instructions: [
                                  "Have a partner hold the kick pad at head height in a stable stance.",
                                  "From fighting stance, hop the lead leg forward as the setup step.",
                                  "Spin 360 degrees, leading the rotation with the head and eyes.",
                                  "Whip the rear leg through into a roundhouse, striking the pad at full extension.",
                                  "Land balanced back in fighting stance, ready to chain another technique.",
                                  "Perform five reps per side across three rounds."
                              ],
                              coachingTip: "The spin starts with the eyes — tell athletes to spot the pad early and the body follows.",
                              equipment: [
                                  DrillEquipmentItem(name: "Kick pad", quantityNote: "1 per pair", systemIcon: "shield.fill")
                              ],
                              muscleFocus: ["Hip flexors", "Obliques", "Glutes", "Calves", "Core"],
                              metrics: DrillMetrics(sets: 3, rest: "45 sec", totalTime: "10 min", spaceRequired: "3 m clear", athleteLevelNote: "Red belt and above"),
                              variations: [
                                  DrillVariation(title: "Tornado to back kick",
                                                 detail: "Follow the landing immediately with a back kick to train spin recovery."),
                                  DrillVariation(title: "No-pad shadow reps",
                                                 detail: "Run slow-motion spins without a pad to clean up the rotation axis.")
                              ],
                              notes: "Demands a confident spin — regress to a 180-degree version if athletes lose balance.",
                              relatedDrillIDs: [slipPadLadderId, pushStepComboId],
                              imageAssetName: "drill_tornado_kick",
                              videoDurationSeconds: 72),
            // 8 — poomsae
            DrillLibraryEntry(name: "Taegeuk slow-motion form",
                              nameAr: "أداء التيغوك ببطء",
                              category: .poomsae,
                              summary: "Run the athlete's belt-required form at 50% speed focusing on stances.",
                              durationMinutes: 12,
                              addressesWeaknessTags: ["taegeuk1", "taegeuk4", "taegeuk8"],
                              minBelt: BeltRank(kind: .gup, number: 8),
                              equipmentRequired: [],
                              difficulty: .beginner,
                              tags: ["Poomsae", "Forms", "Precision"],
                              intensity: 2,
                              instructions: [
                                  "Select the Taegeuk form required for the athlete's current belt.",
                                  "Begin the form at roughly half normal speed with no power on techniques.",
                                  "Pause in each stance and self-check foot placement, depth, and weight distribution.",
                                  "Hold every block and strike at the finish position for two full seconds.",
                                  "Complete the full form twice slowly, then once at competition speed.",
                                  "Note any stance the athlete consistently shortens for follow-up work."
                              ],
                              coachingTip: "Slow motion exposes balance leaks — fix the stance before adding any speed.",
                              equipment: [
                                  DrillEquipmentItem(name: "Floor markers", quantityNote: "Optional", systemIcon: "smallcircle.filled.circle")
                              ],
                              muscleFocus: ["Quads", "Glutes", "Core", "Calves"],
                              metrics: DrillMetrics(sets: 3, rest: "30 sec", totalTime: "12 min", spaceRequired: "Poomsae floor", athleteLevelNote: "All levels"),
                              variations: [
                                  DrillVariation(title: "Mirror form",
                                                 detail: "Perform the form on the mirrored side to balance left-right stance consistency.")
                              ],
                              notes: "Pairs well with video review — film the slow run and compare against the reference form.",
                              relatedDrillIDs: [],
                              imageAssetName: "drill_taegeuk_slow_motion",
                              videoDurationSeconds: 80),
            // 9 — footwork
            DrillLibraryEntry(id: pushStepComboId,
                              name: "Back-leg push-step combo",
                              nameAr: "توليفة الخطوة الخلفية",
                              category: .footwork,
                              summary: "Push-step back, switch, then back-leg roundhouse. 3 × 8 reps.",
                              durationMinutes: 8,
                              addressesWeaknessTags: ["pushStep", "switchStep", "backKicks10s"],
                              minBelt: BeltRank(kind: .gup, number: 6),
                              equipmentRequired: ["kick pad"],
                              difficulty: .intermediate,
                              tags: ["Footwork", "Combinations", "Distance"],
                              intensity: 3,
                              instructions: [
                                  "Start in fighting stance facing a partner who holds a kick pad.",
                                  "Push-step backward off the front foot to open distance.",
                                  "Switch the stance with a quick hop to load the rear leg.",
                                  "Fire a back-leg roundhouse into the pad without telegraphing.",
                                  "Recover to fighting stance and reset distance for the next rep.",
                                  "Perform eight reps per side across three rounds."
                              ],
                              coachingTip: "The push-step and switch should blur into one motion — drill the timing slowly first.",
                              equipment: [
                                  DrillEquipmentItem(name: "Kick pad", quantityNote: "1 per pair", systemIcon: "shield.fill")
                              ],
                              muscleFocus: ["Calves", "Quads", "Hip flexors", "Glutes"],
                              metrics: DrillMetrics(sets: 3, rest: "30 sec", totalTime: "8 min", spaceRequired: "4 m lane", athleteLevelNote: "Blue belt and above"),
                              variations: [
                                  DrillVariation(title: "Live distance",
                                                 detail: "The pad holder moves freely so the athlete must judge real distance each rep.")
                              ],
                              notes: "Trains the defensive-to-offensive transition that wins exchanges in competition.",
                              relatedDrillIDs: [slipPadLadderId, tornadoKickId],
                              imageAssetName: "drill_push_step_combo",
                              videoDurationSeconds: 55),
            // 10 — sparring
            DrillLibraryEntry(id: openStanceId,
                              name: "Open-stance sparring rounds",
                              nameAr: "جولات وقفة مفتوحة",
                              category: .sparring,
                              summary: "Two athletes spar exclusively from open stance for 3 × 90 s rounds.",
                              durationMinutes: 9,
                              addressesWeaknessTags: ["openingAttacks", "counterAttacks"],
                              minBelt: BeltRank(kind: .gup, number: 3),
                              equipmentRequired: ["full sparring gear"],
                              difficulty: .advanced,
                              tags: ["Sparring", "Tactics", "Match Play"],
                              intensity: 5,
                              instructions: [
                                  "Pair athletes of similar weight and rank in full protective gear.",
                                  "Both athletes adopt an open stance — opposite lead legs — and stay there.",
                                  "Spar at competition tempo for a 90-second round.",
                                  "Focus on the angles and targets unique to the open-stance matchup.",
                                  "Rest for 60 seconds, then run the next round switching the lead leg.",
                                  "Complete three rounds and debrief the tactical reads afterward."
                              ],
                              coachingTip: "Open stance favours the rear-leg round kick and the front-leg cut — call these out live.",
                              equipment: [
                                  DrillEquipmentItem(name: "Full sparring gear", quantityNote: "1 set per athlete", systemIcon: "figure.martial.arts"),
                                  DrillEquipmentItem(name: "Stopwatch", systemIcon: "stopwatch.fill")
                              ],
                              muscleFocus: ["Quads", "Hip flexors", "Core", "Calves", "Shoulders"],
                              metrics: DrillMetrics(sets: 3, rest: "60 sec", totalTime: "9 min", spaceRequired: "Sparring ring", athleteLevelNote: "Red belt and above"),
                              variations: [
                                  DrillVariation(title: "Score-only round",
                                                 detail: "Only valid scoring techniques count — sloppy exchanges are reset by the coach."),
                                  DrillVariation(title: "One-attack constraint",
                                                 detail: "Each athlete may throw only one technique per exchange to sharpen shot selection.")
                              ],
                              notes: "High intensity — cap total volume and watch fatigue, as technique decays fast in open stance.",
                              relatedDrillIDs: [counterAttackId],
                              imageAssetName: "drill_open_stance_rounds",
                              videoDurationSeconds: 78),
            // 11 — technique
            DrillLibraryEntry(name: "Double roundhouse on the move",
                              nameAr: "ركلة دائرية مزدوجة أثناء الحركة",
                              category: .technique,
                              summary: "Athlete throws two fast roundhouse kicks while advancing down a pad line.",
                              durationMinutes: 9,
                              addressesWeaknessTags: ["roundhouseFront", "doubleKick"],
                              minBelt: BeltRank(kind: .gup, number: 6),
                              equipmentRequired: ["kick pad"],
                              difficulty: .intermediate,
                              tags: ["Technique", "Combinations", "Speed"],
                              intensity: 3,
                              instructions: [
                                  "Line up three pad holders two paces apart down a lane.",
                                  "The athlete throws two quick roundhouse kicks at the first pad.",
                                  "Advance to the next holder without dropping the guard.",
                                  "Repeat the double roundhouse at each pad along the line.",
                                  "Jog back to the start and complete four passes."
                              ],
                              coachingTip: "The second kick should land before the first foot fully settles — keep the hips loose.",
                              equipment: [
                                  DrillEquipmentItem(name: "Kick pad", quantityNote: "3 per lane", systemIcon: "shield.fill")
                              ],
                              muscleFocus: ["Hip flexors", "Quads", "Calves", "Core"],
                              metrics: DrillMetrics(sets: 4, rest: "40 sec", totalTime: "9 min", spaceRequired: "6 m lane", athleteLevelNote: "Blue belt and above"),
                              notes: "Builds the rhythm needed for fast scoring exchanges.",
                              imageAssetName: "drill_double_roundhouse",
                              videoDurationSeconds: 48),
            // 12 — technique
            DrillLibraryEntry(name: "Axe kick precision drops",
                              nameAr: "إسقاطات ركلة الفأس الدقيقة",
                              category: .technique,
                              summary: "Athlete drops controlled axe kicks onto a chest-height target for accuracy.",
                              durationMinutes: 8,
                              addressesWeaknessTags: ["axeKick", "headKickAccuracy"],
                              minBelt: BeltRank(kind: .gup, number: 4),
                              equipmentRequired: ["paddle target"],
                              difficulty: .intermediate,
                              tags: ["Technique", "Accuracy", "Head Kicks"],
                              intensity: 3,
                              instructions: [
                                  "A partner holds a paddle target at the athlete's head height.",
                                  "Lift the kicking leg straight up past the target.",
                                  "Drop the heel sharply onto the paddle with control, not force.",
                                  "Lower the leg under control and reset stance.",
                                  "Perform ten reps per leg across two rounds."
                              ],
                              coachingTip: "Cue a tall posture — leaning back to reach height kills both accuracy and balance.",
                              equipment: [
                                  DrillEquipmentItem(name: "Paddle target", quantityNote: "1 per pair", systemIcon: "circle.dashed")
                              ],
                              muscleFocus: ["Hamstrings", "Hip flexors", "Core", "Glutes"],
                              metrics: DrillMetrics(sets: 2, rest: "30 sec", totalTime: "8 min", spaceRequired: "2 m clear", athleteLevelNote: "Green belt and above"),
                              variations: [
                                  DrillVariation(title: "Step-in axe",
                                                 detail: "Add a forward step before the kick to train the scoring approach.")
                              ],
                              notes: "Flexibility-dependent — pair with the front-split progression for athletes who lack height.",
                              imageAssetName: "drill_axe_kick_drops",
                              videoDurationSeconds: 44),
            // 13 — sparring
            DrillLibraryEntry(name: "Clinch-break sparring",
                              nameAr: "مبارزة كسر الاشتباك",
                              category: .sparring,
                              summary: "Athletes start in a clinch and must create space to land a scoring kick.",
                              durationMinutes: 8,
                              addressesWeaknessTags: ["clinchWork", "counterAttacks"],
                              minBelt: BeltRank(kind: .gup, number: 3),
                              equipmentRequired: ["full sparring gear"],
                              difficulty: .advanced,
                              tags: ["Sparring", "Clinch", "Tactics"],
                              intensity: 4,
                              instructions: [
                                  "Two geared athletes begin chest-to-chest in a neutral clinch.",
                                  "On the coach's call, both work to break the clinch and create kicking distance.",
                                  "The first athlete to reset distance throws a single scoring kick.",
                                  "Reset to the clinch and repeat for a 90-second round.",
                                  "Run three rounds, rotating partners between rounds."
                              ],
                              coachingTip: "Breaking the clinch is footwork, not strength — push the hips, not the hands.",
                              equipment: [
                                  DrillEquipmentItem(name: "Full sparring gear", quantityNote: "1 set per athlete", systemIcon: "figure.martial.arts")
                              ],
                              muscleFocus: ["Core", "Shoulders", "Quads", "Calves"],
                              metrics: DrillMetrics(sets: 3, rest: "60 sec", totalTime: "8 min", spaceRequired: "Sparring ring", athleteLevelNote: "Red belt and above"),
                              notes: "Teaches a calm response to body contact, a common scoring opportunity at competition.",
                              imageAssetName: "drill_clinch_break",
                              videoDurationSeconds: 62),
            // 14 — sparring
            DrillLibraryEntry(name: "Last-ten-seconds scenario",
                              nameAr: "سيناريو العشر ثوانٍ الأخيرة",
                              category: .sparring,
                              summary: "Athletes spar a simulated final 10 seconds while one point behind.",
                              durationMinutes: 7,
                              addressesWeaknessTags: ["matchManagement", "openingAttacks"],
                              minBelt: BeltRank(kind: .gup, number: 2),
                              equipmentRequired: ["full sparring gear"],
                              difficulty: .advanced,
                              tags: ["Sparring", "Match Play", "Pressure"],
                              intensity: 5,
                              instructions: [
                                  "Brief one athlete that they trail by a single point.",
                                  "Start a 10-second clock and call live sparring.",
                                  "The trailing athlete must attack to score before time expires.",
                                  "The leading athlete defends and runs the clock legally.",
                                  "Reset, swap roles, and repeat for ten total scenarios."
                              ],
                              coachingTip: "Coach decision-making out loud — the right shot late beats a rushed wrong one.",
                              equipment: [
                                  DrillEquipmentItem(name: "Full sparring gear", quantityNote: "1 set per athlete", systemIcon: "figure.martial.arts"),
                                  DrillEquipmentItem(name: "Match clock", systemIcon: "timer")
                              ],
                              muscleFocus: ["Quads", "Core", "Hip flexors", "Calves"],
                              metrics: DrillMetrics(sets: 10, rest: "45 sec", totalTime: "7 min", spaceRequired: "Sparring ring", athleteLevelNote: "Red belt and above"),
                              notes: "A psychological drill as much as a physical one — keep the stakes loud and real.",
                              imageAssetName: "drill_last_ten_seconds",
                              videoDurationSeconds: 58),
            // 15 — flexibility
            DrillLibraryEntry(name: "Dynamic leg-swing series",
                              nameAr: "سلسلة أرجحة الساق الديناميكية",
                              category: .flexibility,
                              summary: "Front, side, and crossover leg swings to mobilise the hips before training.",
                              durationMinutes: 5,
                              addressesWeaknessTags: ["legRaiseAngle", "hipMobility"],
                              difficulty: .beginner,
                              tags: ["Flexibility", "Warm-up", "Mobility"],
                              intensity: 2,
                              instructions: [
                                  "Hold a wall or barre for support and stand tall.",
                                  "Swing one leg forward and back through a comfortable range for 12 reps.",
                                  "Swing the same leg side to side across the body for 12 reps.",
                                  "Add a crossover swing, sweeping the leg in front of the standing leg.",
                                  "Switch legs and repeat the full series."
                              ],
                              coachingTip: "Increase range gradually rep by rep — never force the first swing to full height.",
                              equipment: [
                                  DrillEquipmentItem(name: "Wall or barre", quantityNote: "Shared", systemIcon: "rectangle.portrait.fill")
                              ],
                              muscleFocus: ["Hip flexors", "Hamstrings", "Adductors", "Glutes"],
                              metrics: DrillMetrics(sets: 2, rest: "None", totalTime: "5 min", spaceRequired: "1 m beside wall", athleteLevelNote: "All levels"),
                              notes: "Standard pre-training mobiliser — should leave athletes warm, not stretched out.",
                              imageAssetName: "drill_leg_swing_series",
                              videoDurationSeconds: 36),
            // 16 — flexibility
            DrillLibraryEntry(name: "Side-split wall sit",
                              nameAr: "جلسة الانقسام الجانبي على الجدار",
                              category: .flexibility,
                              summary: "Supported side-split hold against a wall to build adductor length.",
                              durationMinutes: 7,
                              addressesWeaknessTags: ["sideSplitCm", "highKickHeight"],
                              difficulty: .intermediate,
                              tags: ["Flexibility", "Mobility", "Cool-down"],
                              intensity: 2,
                              instructions: [
                                  "Lie on the back with the hips against a wall and legs pointing up.",
                                  "Let both legs slowly spread apart into a side split under gravity.",
                                  "Relax the inner thighs and breathe out as the legs widen.",
                                  "Hold the deepest pain-free position for 45 seconds.",
                                  "Gently bring the legs together and rest, then repeat three times."
                              ],
                              coachingTip: "Tell athletes to relax fully — tension in the adductors blocks the stretch.",
                              equipment: [
                                  DrillEquipmentItem(name: "Mat", quantityNote: "1 per athlete", systemIcon: "square.fill")
                              ],
                              muscleFocus: ["Adductors", "Hip flexors", "Hamstrings"],
                              metrics: DrillMetrics(sets: 3, rest: "30 sec", totalTime: "7 min", spaceRequired: "Wall space", athleteLevelNote: "All levels"),
                              variations: [
                                  DrillVariation(title: "Light ankle weights",
                                                 detail: "Add light ankle weights to gently increase the stretch for advanced athletes.")
                              ],
                              notes: "A passive, low-risk way to chase side-split depth. Best at the end of a session.",
                              imageAssetName: "drill_side_split_wall_sit",
                              videoDurationSeconds: 42),
            // 17 — conditioning
            DrillLibraryEntry(name: "Kick-and-recover intervals",
                              nameAr: "فترات الركل والاستشفاء",
                              category: .conditioning,
                              summary: "30 s of continuous pad kicking followed by 30 s active recovery.",
                              durationMinutes: 10,
                              addressesWeaknessTags: ["roundhouseKicks10s", "anaerobicCapacity"],
                              minBelt: BeltRank(kind: .gup, number: 6),
                              equipmentRequired: ["kick pad"],
                              difficulty: .intermediate,
                              tags: ["Conditioning", "Cardio", "Endurance"],
                              intensity: 4,
                              instructions: [
                                  "Pair each athlete with a pad holder.",
                                  "Kick the pad continuously at a steady pace for 30 seconds.",
                                  "Shift to 30 seconds of light movement and shadow footwork.",
                                  "Alternate kicking and recovery for eight total intervals.",
                                  "Swap holder and kicker roles and repeat the set."
                              ],
                              coachingTip: "Hold technique under fatigue — sloppy kicks in the last interval mean the pace was too high.",
                              equipment: [
                                  DrillEquipmentItem(name: "Kick pad", quantityNote: "1 per pair", systemIcon: "shield.fill"),
                                  DrillEquipmentItem(name: "Interval timer", systemIcon: "timer")
                              ],
                              muscleFocus: ["Quads", "Hip flexors", "Calves", "Core", "Shoulders"],
                              metrics: DrillMetrics(sets: 8, rest: "30 sec active", totalTime: "10 min", spaceRequired: "2 m per pair", athleteLevelNote: "Blue belt and above"),
                              notes: "Directly mirrors the work-rest pattern of a competition round.",
                              imageAssetName: "drill_kick_recover_intervals",
                              videoDurationSeconds: 54),
            // 18 — conditioning
            DrillLibraryEntry(name: "Burpee-to-kick ladder",
                              nameAr: "سلم البيربي إلى الركلة",
                              category: .conditioning,
                              summary: "Burpee followed immediately by a roundhouse, climbing reps each round.",
                              durationMinutes: 9,
                              addressesWeaknessTags: ["anaerobicCapacity", "verticalJumpCm"],
                              difficulty: .intermediate,
                              tags: ["Conditioning", "Cardio", "Full Body"],
                              intensity: 5,
                              instructions: [
                                  "Start standing in an open space with room to drop.",
                                  "Perform one burpee, then immediately throw one roundhouse per leg.",
                                  "Rest briefly, then perform two burpees and two kicks per leg.",
                                  "Climb the ladder up to five burpees and five kicks per leg.",
                                  "Walk one lap to recover, then descend the ladder back to one."
                              ],
                              coachingTip: "Keep the kick crisp even when gassed — it is the part that transfers to the ring.",
                              equipment: [
                                  DrillEquipmentItem(name: "Mat", quantityNote: "1 per athlete", systemIcon: "square.fill")
                              ],
                              muscleFocus: ["Quads", "Glutes", "Core", "Shoulders", "Calves"],
                              metrics: DrillMetrics(sets: 5, rest: "60 sec", totalTime: "9 min", spaceRequired: "2 m square", athleteLevelNote: "All levels"),
                              notes: "A brutal finisher — place it at the very end of the conditioning block.",
                              imageAssetName: "drill_burpee_kick_ladder",
                              videoDurationSeconds: 50),
            // 19 — poomsae
            DrillLibraryEntry(name: "Stance transition holds",
                              nameAr: "ثبات الانتقال بين الوقفات",
                              category: .poomsae,
                              summary: "Step between front, back, and horse stances, holding each for accuracy.",
                              durationMinutes: 8,
                              addressesWeaknessTags: ["stanceAccuracy", "taegeuk1"],
                              minBelt: BeltRank(kind: .gup, number: 8),
                              difficulty: .beginner,
                              tags: ["Poomsae", "Stances", "Precision"],
                              intensity: 2,
                              instructions: [
                                  "Mark a straight line on the floor with tape.",
                                  "Step into a front stance and hold it for five seconds, checking depth.",
                                  "Transition smoothly into a back stance and hold for five seconds.",
                                  "Move into a horse stance and hold, keeping the spine tall.",
                                  "Cycle through all three stances down and back along the line, four passes."
                              ],
                              coachingTip: "Eyes up and chest tall — athletes drop their posture the moment they look at their feet.",
                              equipment: [
                                  DrillEquipmentItem(name: "Floor tape", quantityNote: "1 line", systemIcon: "ruler.fill")
                              ],
                              muscleFocus: ["Quads", "Glutes", "Adductors", "Core"],
                              metrics: DrillMetrics(sets: 4, rest: "20 sec", totalTime: "8 min", spaceRequired: "4 m line", athleteLevelNote: "All levels"),
                              notes: "Builds the stance discipline every Taegeuk form depends on.",
                              imageAssetName: "drill_stance_transitions",
                              videoDurationSeconds: 46),
            // 20 — poomsae
            DrillLibraryEntry(name: "Form segmentation reps",
                              nameAr: "تكرار تقسيم النموذج",
                              category: .poomsae,
                              summary: "Break a Taegeuk form into four blocks and drill each block to mastery.",
                              durationMinutes: 12,
                              addressesWeaknessTags: ["taegeuk4", "taegeuk8", "formFlow"],
                              minBelt: BeltRank(kind: .gup, number: 4),
                              difficulty: .intermediate,
                              tags: ["Poomsae", "Forms", "Repetition"],
                              intensity: 3,
                              instructions: [
                                  "Divide the target form into four roughly equal segments.",
                                  "Perform the first segment five times, refining timing each rep.",
                                  "Move to the second segment and repeat the five-rep cycle.",
                                  "Continue through the third and fourth segments.",
                                  "Link all four segments and run the full form twice end to end."
                              ],
                              coachingTip: "Always rejoin the segments — isolated blocks must flow back into one rhythm.",
                              equipment: [],
                              muscleFocus: ["Quads", "Core", "Glutes", "Calves"],
                              metrics: DrillMetrics(sets: 4, rest: "30 sec", totalTime: "12 min", spaceRequired: "Poomsae floor", athleteLevelNote: "Green belt and above"),
                              variations: [
                                  DrillVariation(title: "Weakest-block focus",
                                                 detail: "Spend double the reps on the segment the athlete scores lowest on.")
                              ],
                              notes: "Efficient way to fix a specific trouble spot without grinding the whole form.",
                              imageAssetName: "drill_form_segmentation",
                              videoDurationSeconds: 76),
            // 21 — footwork
            DrillLibraryEntry(name: "Agility ladder in-and-out",
                              nameAr: "سلم الرشاقة دخول وخروج",
                              category: .footwork,
                              summary: "Fast in-and-out foot patterns through an agility ladder for quick feet.",
                              durationMinutes: 7,
                              addressesWeaknessTags: ["footSpeed", "agility"],
                              difficulty: .beginner,
                              tags: ["Footwork", "Agility", "Speed"],
                              intensity: 3,
                              instructions: [
                                  "Lay an agility ladder flat on the training floor.",
                                  "Step both feet into the first box, then both feet out to the sides.",
                                  "Move forward and repeat the in-and-out pattern through every box.",
                                  "Keep the steps light, fast, and on the balls of the feet.",
                                  "Jog back to the start and complete six passes."
                              ],
                              coachingTip: "Speed comes from short ground contact — cue quiet, quick feet over big steps.",
                              equipment: [
                                  DrillEquipmentItem(name: "Agility ladder", quantityNote: "1 per group", systemIcon: "square.grid.3x1.below.line.grid.1x2")
                              ],
                              muscleFocus: ["Calves", "Quads", "Ankles", "Hip flexors"],
                              metrics: DrillMetrics(sets: 6, rest: "30 sec", totalTime: "7 min", spaceRequired: "5 m lane", athleteLevelNote: "All levels"),
                              variations: [
                                  DrillVariation(title: "Lateral shuffle",
                                                 detail: "Run the ladder sideways to train frontal-plane quickness."),
                                  DrillVariation(title: "Kick at the exit",
                                                 detail: "Finish each pass with a roundhouse on a pad to link footwork to scoring.")
                              ],
                              notes: "Great athletic warm-up that doubles as light coordination work.",
                              imageAssetName: "drill_agility_ladder",
                              videoDurationSeconds: 40),
            // 22 — footwork
            DrillLibraryEntry(name: "Mirror footwork game",
                              nameAr: "لعبة محاكاة حركة القدمين",
                              category: .footwork,
                              summary: "One athlete leads with footwork while a partner mirrors every movement.",
                              durationMinutes: 6,
                              addressesWeaknessTags: ["footSpeed", "distanceControl"],
                              minBelt: BeltRank(kind: .gup, number: 7),
                              difficulty: .beginner,
                              tags: ["Footwork", "Reaction", "Distance"],
                              intensity: 3,
                              instructions: [
                                  "Pair athletes facing each other in fighting stance.",
                                  "Designate one as the leader and one as the mirror.",
                                  "The leader moves freely — forward, back, and laterally.",
                                  "The mirror matches every movement to hold a constant distance.",
                                  "Switch roles every 45 seconds for a total of six rounds."
                              ],
                              coachingTip: "The mirror should react to the hips, not the feet — that is where movement starts.",
                              equipment: [],
                              muscleFocus: ["Calves", "Quads", "Hip flexors", "Core"],
                              metrics: DrillMetrics(sets: 6, rest: "15 sec", totalTime: "6 min", spaceRequired: "3 m square", athleteLevelNote: "All levels"),
                              notes: "Sharpens distance management — the foundation of safe, effective sparring.",
                              imageAssetName: "drill_mirror_footwork",
                              videoDurationSeconds: 44),
            // 23 — strength
            DrillLibraryEntry(name: "Bodyweight squat tempo set",
                              nameAr: "مجموعة القرفصاء بإيقاع",
                              category: .strength,
                              summary: "Slow-tempo bodyweight squats to build leg strength and control.",
                              durationMinutes: 8,
                              addressesWeaknessTags: ["legStrength", "singleLegSquatReps"],
                              difficulty: .beginner,
                              tags: ["Strength", "Legs", "Control"],
                              intensity: 3,
                              instructions: [
                                  "Stand with feet shoulder-width apart and arms extended for balance.",
                                  "Lower into a squat over a slow three-second count.",
                                  "Pause for one second at the bottom with the chest tall.",
                                  "Drive back up to standing over a two-second count.",
                                  "Perform twelve controlled reps, then rest.",
                                  "Complete four sets."
                              ],
                              coachingTip: "Keep the knees tracking over the toes — never let them collapse inward under load.",
                              equipment: [],
                              muscleFocus: ["Quads", "Glutes", "Hamstrings", "Core"],
                              metrics: DrillMetrics(sets: 4, rest: "60 sec", totalTime: "8 min", spaceRequired: "1 m square", athleteLevelNote: "All levels"),
                              variations: [
                                  DrillVariation(title: "Single-leg progression",
                                                 detail: "Advance to assisted pistol squats once bodyweight tempo squats feel easy.")
                              ],
                              notes: "Foundational leg strength work — no equipment needed, easy to scale by tempo.",
                              imageAssetName: "drill_squat_tempo",
                              videoDurationSeconds: 48),
            // 24 — strength
            DrillLibraryEntry(name: "Resistance-band kick holds",
                              nameAr: "تثبيت الركلة بشريط المقاومة",
                              category: .strength,
                              summary: "Isometric kick holds against a resistance band to strengthen the chamber.",
                              durationMinutes: 9,
                              addressesWeaknessTags: ["legStrength", "kickHeight"],
                              minBelt: BeltRank(kind: .gup, number: 6),
                              equipmentRequired: ["resistance band"],
                              difficulty: .intermediate,
                              tags: ["Strength", "Isometric", "Kicks"],
                              intensity: 3,
                              instructions: [
                                  "Loop a resistance band around the ankle and a fixed anchor point.",
                                  "Chamber the kicking leg into the roundhouse position.",
                                  "Hold the chamber against band tension for ten seconds.",
                                  "Extend slowly into the kick, then return under control.",
                                  "Perform six reps per leg across three sets."
                              ],
                              coachingTip: "Hold the standing leg strong and tall — most athletes wobble here, not at the chamber.",
                              equipment: [
                                  DrillEquipmentItem(name: "Resistance band", quantityNote: "1 per athlete", systemIcon: "alternatingcurrent"),
                                  DrillEquipmentItem(name: "Anchor point", quantityNote: "Shared", systemIcon: "pin.fill")
                              ],
                              muscleFocus: ["Hip flexors", "Quads", "Glutes", "Core", "Calves"],
                              metrics: DrillMetrics(sets: 3, rest: "45 sec", totalTime: "9 min", spaceRequired: "2 m clear", athleteLevelNote: "Blue belt and above"),
                              notes: "Builds the static strength that keeps a high kick chambered under pressure.",
                              imageAssetName: "drill_band_kick_holds",
                              videoDurationSeconds: 56),
            // 25 — strength
            DrillLibraryEntry(name: "Core anti-rotation plank",
                              nameAr: "بلانك مقاومة الدوران للجذع",
                              category: .strength,
                              summary: "Plank holds with a partner-applied pull to train anti-rotation strength.",
                              durationMinutes: 7,
                              addressesWeaknessTags: ["coreStability", "balance"],
                              difficulty: .intermediate,
                              tags: ["Strength", "Core", "Stability"],
                              intensity: 3,
                              instructions: [
                                  "Set up in a forearm plank with a flat back and braced core.",
                                  "A partner gently pulls one shoulder to one side.",
                                  "Resist the pull and keep the hips and shoulders square.",
                                  "Hold against the pull for ten seconds, then switch sides.",
                                  "Complete four sets of holds per side."
                              ],
                              coachingTip: "No sagging hips — if the plank line breaks, shorten the hold rather than the quality.",
                              equipment: [
                                  DrillEquipmentItem(name: "Mat", quantityNote: "1 per athlete", systemIcon: "square.fill")
                              ],
                              muscleFocus: ["Core", "Obliques", "Shoulders", "Glutes"],
                              metrics: DrillMetrics(sets: 4, rest: "30 sec", totalTime: "7 min", spaceRequired: "2 m mat", athleteLevelNote: "Green belt and above"),
                              notes: "A strong anti-rotation core protects balance during spinning kicks.",
                              imageAssetName: "drill_anti_rotation_plank",
                              videoDurationSeconds: 42),
            // 26 — strength
            DrillLibraryEntry(name: "Calf-raise endurance set",
                              nameAr: "مجموعة تحمل رفع السمانة",
                              category: .strength,
                              summary: "High-rep calf raises to build the ankle endurance kicking demands.",
                              durationMinutes: 6,
                              addressesWeaknessTags: ["legStrength", "footSpeed"],
                              difficulty: .beginner,
                              tags: ["Strength", "Calves", "Endurance"],
                              intensity: 2,
                              instructions: [
                                  "Stand tall on the edge of a step with the heels hanging off.",
                                  "Rise onto the toes as high as possible.",
                                  "Pause briefly at the top, fully contracting the calves.",
                                  "Lower the heels slowly below the step level.",
                                  "Perform twenty reps, then rest.",
                                  "Complete three sets."
                              ],
                              coachingTip: "Full range every rep — half-range calf raises build half the strength.",
                              equipment: [
                                  DrillEquipmentItem(name: "Step or platform", quantityNote: "Shared", systemIcon: "stairs")
                              ],
                              muscleFocus: ["Calves", "Ankles", "Soleus"],
                              metrics: DrillMetrics(sets: 3, rest: "45 sec", totalTime: "6 min", spaceRequired: "Beside a step", athleteLevelNote: "All levels"),
                              variations: [
                                  DrillVariation(title: "Single-leg raises",
                                                 detail: "Perform on one leg at a time to double the load and expose imbalances.")
                              ],
                              notes: "Often-neglected work that supports fast footwork and bouncy stance.",
                              imageAssetName: "drill_calf_raise_endurance",
                              videoDurationSeconds: 34),
            // 27 — technique
            DrillLibraryEntry(name: "Back kick spin accuracy",
                              nameAr: "دقة دوران الركلة الخلفية",
                              category: .technique,
                              summary: "Spin and deliver a back kick to a body target, refining the rotation line.",
                              durationMinutes: 9,
                              addressesWeaknessTags: ["backKick", "spinningHookKick"],
                              minBelt: BeltRank(kind: .gup, number: 3),
                              equipmentRequired: ["kick pad"],
                              difficulty: .advanced,
                              tags: ["Technique", "Spinning Kicks", "Accuracy"],
                              intensity: 4,
                              instructions: [
                                  "A partner holds a body pad at the athlete's chest height.",
                                  "From fighting stance, look over the shoulder to spot the pad.",
                                  "Spin and drive the rear leg straight back into the pad.",
                                  "Keep the kicking foot's path on a straight line to the target.",
                                  "Recover facing the pad in a balanced stance.",
                                  "Perform six reps per side across three rounds."
                              ],
                              coachingTip: "The kick travels in a straight line — any curve means the hip turned too early.",
                              equipment: [
                                  DrillEquipmentItem(name: "Kick pad", quantityNote: "1 per pair", systemIcon: "shield.fill")
                              ],
                              muscleFocus: ["Glutes", "Hamstrings", "Core", "Obliques", "Calves"],
                              metrics: DrillMetrics(sets: 3, rest: "45 sec", totalTime: "9 min", spaceRequired: "3 m clear", athleteLevelNote: "Red belt and above"),
                              notes: "The back kick is a top scoring technique — accuracy on the line matters more than power.",
                              imageAssetName: "drill_back_kick_accuracy",
                              videoDurationSeconds: 60),
            // 28 — sparring
            DrillLibraryEntry(name: "Cut-kick timing drill",
                              nameAr: "تمرين توقيت ركلة القطع",
                              category: .sparring,
                              summary: "Athlete intercepts a partner's advance with a well-timed cut kick.",
                              durationMinutes: 8,
                              addressesWeaknessTags: ["cutKick", "reactionMs"],
                              minBelt: BeltRank(kind: .gup, number: 4),
                              equipmentRequired: ["chest protector"],
                              difficulty: .intermediate,
                              tags: ["Sparring", "Timing", "Defense"],
                              intensity: 4,
                              instructions: [
                                  "Pair athletes at sparring distance with chest protectors on.",
                                  "One athlete steps forward to attack at random intervals.",
                                  "The defender reads the step and lifts a front-leg cut kick.",
                                  "The cut kick should stop the advance before the attack lands.",
                                  "Reset and repeat for 90 seconds, then swap roles.",
                                  "Complete three rounds each."
                              ],
                              coachingTip: "Time the cut to the attacker's weight shift, not their kick — early beats fast.",
                              equipment: [
                                  DrillEquipmentItem(name: "Chest protector", quantityNote: "1 per athlete", systemIcon: "shield.lefthalf.filled")
                              ],
                              muscleFocus: ["Hip flexors", "Quads", "Core", "Calves"],
                              metrics: DrillMetrics(sets: 3, rest: "45 sec", totalTime: "8 min", spaceRequired: "3 m lane", athleteLevelNote: "Green belt and above"),
                              notes: "The cut kick is the primary defensive weapon — timing is everything.",
                              imageAssetName: "drill_cut_kick_timing",
                              videoDurationSeconds: 52),
            // 29 — conditioning
            DrillLibraryEntry(name: "Shadow-spar tempo rounds",
                              nameAr: "جولات إيقاع المبارزة الوهمية",
                              category: .conditioning,
                              summary: "Continuous shadow sparring at competition tempo to build round fitness.",
                              durationMinutes: 9,
                              addressesWeaknessTags: ["anaerobicCapacity", "roundhouseKicks10s"],
                              difficulty: .beginner,
                              tags: ["Conditioning", "Cardio", "Endurance"],
                              intensity: 3,
                              instructions: [
                                  "Spread athletes out with space to move freely.",
                                  "Shadow-spar with full footwork and kicks at competition pace.",
                                  "Continue without stopping for a 90-second round.",
                                  "Rest for 30 seconds with light movement.",
                                  "Complete five rounds, raising tempo each round."
                              ],
                              coachingTip: "No empty motion — every kick should have a real imaginary target.",
                              equipment: [
                                  DrillEquipmentItem(name: "Interval timer", systemIcon: "timer")
                              ],
                              muscleFocus: ["Quads", "Calves", "Core", "Hip flexors", "Shoulders"],
                              metrics: DrillMetrics(sets: 5, rest: "30 sec", totalTime: "9 min", spaceRequired: "2 m per athlete", athleteLevelNote: "All levels"),
                              notes: "Equipment-free conditioning that also rehearses combinations and movement.",
                              imageAssetName: "drill_shadow_spar_tempo",
                              videoDurationSeconds: 50),
            // 30 — flexibility
            DrillLibraryEntry(name: "High-kick wall slides",
                              nameAr: "انزلاقات الركلة العالية على الجدار",
                              category: .flexibility,
                              summary: "Slow controlled high kicks against a wall to extend active kicking range.",
                              durationMinutes: 7,
                              addressesWeaknessTags: ["highKickHeight", "legRaiseAngle"],
                              minBelt: BeltRank(kind: .gup, number: 7),
                              difficulty: .intermediate,
                              tags: ["Flexibility", "Active Mobility", "Kicks"],
                              intensity: 3,
                              instructions: [
                                  "Stand an arm's length from a wall, using it for balance.",
                                  "Slowly raise the kicking leg as high as control allows.",
                                  "Pause at the top height for two seconds without leaning back.",
                                  "Lower the leg under full control.",
                                  "Perform ten slow reps per leg across two sets."
                              ],
                              coachingTip: "Active range beats passive — only count height the athlete reaches under control.",
                              equipment: [
                                  DrillEquipmentItem(name: "Wall", quantityNote: "Shared", systemIcon: "rectangle.portrait.fill")
                              ],
                              muscleFocus: ["Hip flexors", "Hamstrings", "Quads", "Core"],
                              metrics: DrillMetrics(sets: 2, rest: "30 sec", totalTime: "7 min", spaceRequired: "Wall space", athleteLevelNote: "Green belt and above"),
                              notes: "Bridges passive flexibility into the active range athletes can actually kick to.",
                              imageAssetName: "drill_high_kick_wall_slides",
                              videoDurationSeconds: 46),
            // 31 — poomsae
            DrillLibraryEntry(name: "Kihap and breath timing",
                              nameAr: "توقيت الكيهاب والتنفس",
                              category: .poomsae,
                              summary: "Drill the kihap shout and breathing rhythm across a full form.",
                              durationMinutes: 6,
                              addressesWeaknessTags: ["formExpression", "taegeuk1"],
                              minBelt: BeltRank(kind: .gup, number: 8),
                              difficulty: .beginner,
                              tags: ["Poomsae", "Expression", "Breathing"],
                              intensity: 2,
                              instructions: [
                                  "Identify the official kihap points in the target form.",
                                  "Walk the form slowly, exhaling sharply on each focused technique.",
                                  "Deliver a strong, controlled kihap exactly at the marked points.",
                                  "Run the form again at normal speed with full breath timing.",
                                  "Finish with one performance-quality run for expression."
                              ],
                              coachingTip: "The kihap comes from the core, not the throat — power it from the abdomen.",
                              equipment: [],
                              muscleFocus: ["Core", "Diaphragm", "Obliques"],
                              metrics: DrillMetrics(sets: 3, rest: "20 sec", totalTime: "6 min", spaceRequired: "Poomsae floor", athleteLevelNote: "All levels"),
                              notes: "Expression and breath control are scored in poomsae — train them deliberately.",
                              imageAssetName: "drill_kihap_breath_timing",
                              videoDurationSeconds: 38),
            // 32 — strength
            DrillLibraryEntry(name: "Hip-thrust power set",
                              nameAr: "مجموعة قوة دفع الورك",
                              category: .strength,
                              summary: "Bodyweight hip thrusts to build the glute drive behind every kick.",
                              durationMinutes: 8,
                              addressesWeaknessTags: ["legStrength", "kickPower"],
                              difficulty: .beginner,
                              tags: ["Strength", "Glutes", "Power"],
                              intensity: 3,
                              instructions: [
                                  "Sit with the upper back resting against a low bench.",
                                  "Plant the feet flat and bend the knees to about 90 degrees.",
                                  "Drive through the heels and lift the hips into a straight line.",
                                  "Squeeze the glutes hard at the top for one second.",
                                  "Lower the hips under control just short of the floor.",
                                  "Perform fifteen reps across four sets."
                              ],
                              coachingTip: "Finish each rep with a hard glute squeeze — that contraction is the kicking driver.",
                              equipment: [
                                  DrillEquipmentItem(name: "Low bench", quantityNote: "Shared", systemIcon: "bed.double.fill"),
                                  DrillEquipmentItem(name: "Mat", quantityNote: "1 per athlete", systemIcon: "square.fill")
                              ],
                              muscleFocus: ["Glutes", "Hamstrings", "Core", "Lower back"],
                              metrics: DrillMetrics(sets: 4, rest: "60 sec", totalTime: "8 min", spaceRequired: "2 m beside bench", athleteLevelNote: "All levels"),
                              variations: [
                                  DrillVariation(title: "Single-leg thrust",
                                                 detail: "Perform with one leg extended to increase load and correct side-to-side imbalance.")
                              ],
                              notes: "Strong glutes are the engine of kicking power — a high-value, low-risk strength staple.",
                              imageAssetName: "drill_hip_thrust_power",
                              videoDurationSeconds: 50)
        ]

        // === Improvement plans: one active plan for each ready-to-grade
        // athlete, with a placeholder weakness + 2 random drill picks. ===
        var improvementPlans: [ImprovementPlan] = []
        let drillIDs = drills.map(\.id)
        for (idx, athlete) in athletes.enumerated() where athlete.status == .readyToGrade {
            let coachID = athlete.primaryCoachID ?? coachYassin.id
            let pickedDrills = [drillIDs[(idx) % drillIDs.count],
                                drillIDs[(idx + 3) % drillIDs.count]]
            improvementPlans.append(ImprovementPlan(
                athleteID: athlete.id,
                createdAt: days(-14),
                createdByCoachID: coachID,
                weaknesses: [
                    Weakness(kind: "frontSplitCm", label: "metric.frontSplitCm",
                             severity: .medium, source: .peer)
                ],
                recommendedDrillIDs: pickedDrills,
                notes: "Two-week focus block before the upcoming grading.",
                targetDate: days(21),
                reviewDate: days(7),
                status: .active
            ))
        }

        // === Peer benchmarks: pre-compute mean/σ across age + belt slices
        // from the seeded metrics so the demo isn't empty. ===
        let peerBenchmarks = BenchmarkComputer.compute(
            athletes: athletes,
            metrics: physicalMetrics,
            minSampleSize: 3
        )

        // === Wellness entries: 7 per athlete (last 7 days) ===
        var wellness: [WellnessEntry] = []
        for (idx, athlete) in athletes.enumerated() {
            for dayBack in 0..<7 {
                wellness.append(WellnessEntry(
                    athleteID: athlete.id,
                    recordedAt: days(-dayBack),
                    sleepHours: 7.5 + Double((dayBack + idx) % 3) * 0.4,
                    mood: 6 + ((dayBack + idx) % 4),
                    soreness: 2 + (idx % 4),
                    motivation: 6 + ((idx + dayBack) % 4),
                    stress: 3 + ((idx * 2 + dayBack) % 4),
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
            // Use the branch's primary coach (and Layla if Al Rahmania) as examiner.
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

        // Demo credentials — every seeded account, including the developer /
        // project-owner account below, signs in with password "12345678"
        // (the SHA-256 hash that value produces is shared across all rows).
        let credentials = [
            SeedCredential(email: "gulflens.studio@gmail.com", passwordHash: "ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f", userID: userDev.id),
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

        let hoursNouf = BranchHours(
            branchID: branchAlNouf.id, regular: standardWeek(),
            ramadan: ramadanWeek(), ramadanStart: ramadanStart, ramadanEnd: ramadanEnd,
            holidayClosures: [days(20), days(45)]
        )
        let hoursNasserya = BranchHours(branchID: branchAlNasserya.id, regular: standardWeek())
        let hoursIndustrial18 = BranchHours(branchID: branchIndustrial18.id, regular: standardWeek())
        let hoursRahmania = BranchHours(branchID: branchAlRahmania.id, regular: standardWeek(closedFri: true))
        let allBranchHours = [hoursNouf, hoursNasserya, hoursIndustrial18, hoursRahmania]

        // Facilities: Al Rahmania is the headquarters (1200 sqm, 2 halls, PSS).
        let facilityNouf = BranchFacility(
            branchID: branchAlNouf.id,
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
                "https://placehold.co/1200x800/png?text=Al+Rahmania+Main",
                "https://placehold.co/1200x800/png?text=Al+Rahmania+Hall",
                "https://placehold.co/1200x800/png?text=Al+Rahmania+Lobby",
                "https://placehold.co/1200x800/png?text=Al+Rahmania+Spectators"
            ]
        )
        let facilityNasserya = BranchFacility(
            branchID: branchAlNasserya.id,
            floorAreaSqm: 600, hallCount: 1,
            hallDimensions: [HallSpec(name: "Main Hall", lengthM: 12, widthM: 10,
                                      matSpec: "WT puzzle 25mm", isCompetitionGrade: true)],
            hasMirrorWalls: true, hasSoundSystem: true, hasAC: true,
            hasInstalledScoreboard: true,
            changingRoomsM: 1, changingRoomsF: 1,
            spectatorSeats: 40, parkingSpots: 12,
            hasPrayerRoom: true, hasWudu: true
        )
        let facilityIndustrial18 = BranchFacility(
            branchID: branchIndustrial18.id,
            floorAreaSqm: 500, hallCount: 1,
            hallDimensions: [HallSpec(name: "Community Hall", lengthM: 10, widthM: 9,
                                      matSpec: "Foam tatami 20mm")],
            hasMirrorWalls: false, hasSoundSystem: true, hasAC: true,
            changingRoomsM: 1, changingRoomsF: 1,
            spectatorSeats: 20, parkingSpots: 8,
            hasPrayerRoom: false, hasWudu: false
        )
        let facilityRahmania = BranchFacility(
            branchID: branchAlRahmania.id,
            floorAreaSqm: 700, hallCount: 1,
            hallDimensions: [HallSpec(name: "Women's Hall", lengthM: 12, widthM: 10,
                                      matSpec: "WT puzzle 25mm", isCompetitionGrade: true)],
            hasMirrorWalls: true, hasSoundSystem: true, hasAC: true,
            changingRoomsM: 0, changingRoomsF: 3,
            spectatorSeats: 30, parkingSpots: 16,
            hasPrayerRoom: true, hasWudu: true
        )
        let allFacilities = [facilityNouf, facilityNasserya, facilityIndustrial18, facilityRahmania]

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

        let programsNouf = [
            program(branchAlNouf, name: "Cubs after-school", nameAr: "أشبال بعد المدرسة",
                    age: .cubs, disciplines: [.fundamentals],
                    pattern: [.sun, .tue, .thu], start: "16:00", end: "17:00",
                    capacity: 16, fee: 350),
            program(branchAlNouf, name: "Junior fundamentals", nameAr: "أساسيات الناشئين",
                    age: .kids, disciplines: [.fundamentals, .poomsae],
                    pattern: [.sun, .tue, .thu], start: "17:15", end: "18:30",
                    capacity: 20, fee: 450),
            program(branchAlNouf, name: "Cadet kyorugi", nameAr: "كيوروجي كاديت",
                    age: .cadets, disciplines: [.kyorugi],
                    pattern: [.mon, .wed, .sat], start: "18:30", end: "20:00",
                    capacity: 18, fee: 500),
            program(branchAlNouf, name: "Junior comp team", nameAr: "فريق منافسات الناشئين",
                    age: .juniors, disciplines: [.kyorugi, .competition],
                    pattern: [.mon, .wed, .fri], start: "19:00", end: "21:00",
                    capacity: 12, fee: 650),
            program(branchAlNouf, name: "Senior fitness", nameAr: "لياقة الكبار",
                    age: .seniors, disciplines: [.fitness],
                    pattern: [.tue, .thu], start: "20:00", end: "21:00",
                    capacity: 20, fee: 400),
            program(branchAlNouf, name: "Adult beginners", nameAr: "مبتدئين بالغين",
                    age: .seniors, disciplines: [.fundamentals],
                    pattern: [.mon, .wed], start: "20:30", end: "21:30",
                    capacity: 16, fee: 400),
        ]
        let programsNasserya = [
            program(branchAlNasserya, name: "Junior fundamentals", nameAr: "أساسيات الناشئين",
                    age: .kids, disciplines: [.fundamentals],
                    pattern: [.sun, .tue, .thu], start: "16:30", end: "18:00",
                    capacity: 18, fee: 350),
            program(branchAlNasserya, name: "Cadet kyorugi", nameAr: "كيوروجي كاديت",
                    age: .cadets, disciplines: [.kyorugi],
                    pattern: [.mon, .wed, .sat], start: "18:00", end: "19:30",
                    capacity: 16, fee: 450),
            program(branchAlNasserya, name: "Cadet poomsae", nameAr: "بومساي كاديت",
                    age: .cadets, disciplines: [.poomsae],
                    pattern: [.tue, .thu], start: "16:30", end: "18:00",
                    capacity: 14, fee: 400),
            program(branchAlNasserya, name: "Junior comp", nameAr: "منافسات الناشئين",
                    age: .juniors, disciplines: [.competition, .kyorugi],
                    pattern: [.sun, .tue, .thu], start: "19:00", end: "20:30",
                    capacity: 12, fee: 550),
        ]
        let programsIndustrial18 = [
            program(branchIndustrial18, name: "Cubs club", nameAr: "نادي الأشبال",
                    age: .cubs, disciplines: [.fundamentals],
                    pattern: [.mon, .wed], start: "16:30", end: "17:30",
                    capacity: 14, fee: 250),
            program(branchIndustrial18, name: "Kids poomsae", nameAr: "بومساي الأطفال",
                    age: .kids, disciplines: [.poomsae],
                    pattern: [.sun, .tue, .thu], start: "17:30", end: "18:45",
                    capacity: 16, fee: 350),
            program(branchIndustrial18, name: "Open class", nameAr: "حصة مفتوحة",
                    age: .seniors, disciplines: [.fundamentals, .fitness],
                    pattern: [.tue, .thu, .sat], start: "19:00", end: "20:30",
                    capacity: 20, fee: 400),
        ]
        let programsRahmania = [
            program(branchAlRahmania, name: "Girls cubs", nameAr: "بنات الأشبال",
                    age: .cubs, disciplines: [.fundamentals],
                    pattern: [.sun, .tue, .thu], start: "16:00", end: "17:00",
                    capacity: 14, fee: 350, womenOnly: true),
            program(branchAlRahmania, name: "Junior girls", nameAr: "ناشئات",
                    age: .kids, disciplines: [.fundamentals, .poomsae],
                    pattern: [.sun, .tue, .thu], start: "17:15", end: "18:30",
                    capacity: 16, fee: 450, womenOnly: true),
            program(branchAlRahmania, name: "Women's kyorugi", nameAr: "كيوروجي للنساء",
                    age: .seniors, disciplines: [.kyorugi],
                    pattern: [.mon, .wed], start: "19:00", end: "20:30",
                    capacity: 14, fee: 500, womenOnly: true),
            program(branchAlRahmania, name: "Women's fitness", nameAr: "لياقة النساء",
                    age: .seniors, disciplines: [.fitness],
                    pattern: [.tue, .thu, .sat], start: "10:00", end: "11:00",
                    capacity: 18, fee: 400, womenOnly: true),
        ]
        let allBranchPrograms = programsNouf + programsNasserya + programsIndustrial18 + programsRahmania

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
            inventory(branch: branchAlNouf, scale: 1.0),
            inventory(branch: branchAlNasserya, scale: 0.7),
            inventory(branch: branchIndustrial18, scale: 0.5),
            inventory(branch: branchAlRahmania, scale: 0.6),
        ]

        // Compliance
        let complianceNouf = BranchCompliance(
            branchID: branchAlNouf.id,
            civilDefenceCertNumber: "CD-2024-A-1057", civilDefenceExpiry: days(220),
            sharjahSportsCouncilRegNumber: "SSC-2024-AR-19", sharjahSportsCouncilExpiry: days(180),
            insurancePolicyNumber: "DAMAN-PRT-77194", insuranceProvider: "Daman", insuranceExpiry: days(190),
            lastHealthSafetyInspectionAt: days(-45), lastEmergencyPlanReviewAt: days(-30),
            hasAED: true, aedLastServiceAt: days(-60), firstAidKitLastCheckedAt: days(-7)
        )
        let complianceNasserya = BranchCompliance(
            branchID: branchAlNasserya.id,
            civilDefenceCertNumber: "CD-2024-J-4022", civilDefenceExpiry: days(150),
            sharjahSportsCouncilRegNumber: "SSC-2024-JZ-22", sharjahSportsCouncilExpiry: days(160),
            insurancePolicyNumber: "ADNIC-44990", insuranceProvider: "ADNIC", insuranceExpiry: days(170),
            lastHealthSafetyInspectionAt: days(-30), hasAED: true, aedLastServiceAt: days(-90),
            firstAidKitLastCheckedAt: days(-14)
        )
        // Industrial 18 has a cert expiring next month → drives a TD alert.
        let complianceIndustrial18 = BranchCompliance(
            branchID: branchIndustrial18.id,
            civilDefenceCertNumber: "CD-2024-K-7715", civilDefenceExpiry: days(20),
            sharjahSportsCouncilRegNumber: "SSC-2024-KH-08", sharjahSportsCouncilExpiry: days(140),
            insurancePolicyNumber: "ORIENT-12054", insuranceProvider: "Orient", insuranceExpiry: days(120),
            lastHealthSafetyInspectionAt: days(-90), hasAED: false,
            firstAidKitLastCheckedAt: days(-21)
        )
        let complianceRahmania = BranchCompliance(
            branchID: branchAlRahmania.id,
            civilDefenceCertNumber: "CD-2024-S-3019", civilDefenceExpiry: days(280),
            sharjahSportsCouncilRegNumber: "SSC-2024-SH-31", sharjahSportsCouncilExpiry: days(260),
            insurancePolicyNumber: "DAMAN-PRT-88210", insuranceProvider: "Daman", insuranceExpiry: days(250),
            lastHealthSafetyInspectionAt: days(-20), lastEmergencyPlanReviewAt: days(-20),
            hasAED: true, aedLastServiceAt: days(-30), firstAidKitLastCheckedAt: days(-3)
        )
        let allCompliances = [complianceNouf, complianceNasserya, complianceIndustrial18, complianceRahmania]

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
            pricing(branch: branchAlNouf, base: 450),
            pricing(branch: branchAlNasserya, base: 400),
            pricing(branch: branchIndustrial18, base: 300, trial: 30, reg: 150, equip: 250),
            pricing(branch: branchAlRahmania, base: 425),
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
            financialsSeries(branch: branchAlNouf, baseRevenue: 85_000, baseRent: 22_000)
            + financialsSeries(branch: branchAlNasserya, baseRevenue: 50_000, baseRent: 14_000)
            + financialsSeries(branch: branchIndustrial18, baseRevenue: 32_000, baseRent: 9_000)
            + financialsSeries(branch: branchAlRahmania, baseRevenue: 45_000, baseRent: 13_000)

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
                branchID: branchAlNouf.id,
                whatsappParentsLink: "https://chat.whatsapp.com/ramtha-parents",
                whatsappAthletesLink: "https://chat.whatsapp.com/ramtha-athletes",
                instagramHandle: "@ssdsc_taekwondo",
                tiktokHandle: "@ssdsc_taekwondo",
                websiteURL: "https://ssdsc.ae"
            ),
            BranchSocialLinks(
                branchID: branchAlNasserya.id,
                whatsappParentsLink: "https://chat.whatsapp.com/jazzat-parents",
                instagramHandle: "@ssdsc_jazzat"
            ),
            BranchSocialLinks(
                branchID: branchIndustrial18.id,
                whatsappParentsLink: "https://chat.whatsapp.com/khan-parents",
                instagramHandle: "@ssdsc_khan"
            ),
            BranchSocialLinks(
                branchID: branchAlRahmania.id,
                whatsappParentsLink: "https://chat.whatsapp.com/shaghrafa-parents",
                instagramHandle: "@ssdsc_shaghrafa_girls"
            ),
        ]

        // Safeguarding
        let allSafeguarding = [
            BranchSafeguarding(
                branchID: branchAlNouf.id,
                safeguardingOfficerCoachID: coachYassin.id,
                lastTeamTrainingAt: days(-90),
                staffCheckCurrentPct: 0.95,
                openIncidentCount: 0,
                lastIncidentAt: days(-200)
            ),
            BranchSafeguarding(
                branchID: branchAlNasserya.id,
                safeguardingOfficerCoachID: coachYassin.id,
                lastTeamTrainingAt: days(-150),
                staffCheckCurrentPct: 0.80,
                openIncidentCount: 1,
                lastIncidentAt: days(-30)
            ),
            BranchSafeguarding(
                branchID: branchIndustrial18.id,
                safeguardingOfficerCoachID: coachAshraf.id,
                lastTeamTrainingAt: days(-200),
                staffCheckCurrentPct: 0.66
            ),
            BranchSafeguarding(
                branchID: branchAlRahmania.id,
                safeguardingOfficerCoachID: coachAli.id,
                lastTeamTrainingAt: days(-60),
                staffCheckCurrentPct: 1.0
            ),
        ]

        // Milestones
        let allMilestones = [
            BranchMilestone(branchID: branchAlNouf.id, occurredAt: branchAlNouf.foundedAt,
                            titleEn: "Branch founded", titleAr: "تأسيس الفرع",
                            descriptionEn: "Al Rahmania opens as the founding SSDSC dojang.",
                            descriptionAr: "افتتاح فرع الرحمانية كأول دوجانغ تابع لـ SSDSC.",
                            category: .founded),
            BranchMilestone(branchID: branchAlNouf.id, occurredAt: monthsAgo(11),
                            titleEn: "UAE Junior League champions",
                            titleAr: "أبطال دوري الناشئين الإماراتي",
                            descriptionEn: "Al Rahmania team wins the 2025 UAE Junior League.",
                            descriptionAr: "فاز فريق الرحمانية ببطولة دوري الناشئين الإماراتي 2025.",
                            category: .championshipWon),
            BranchMilestone(branchID: branchAlNouf.id, occurredAt: monthsAgo(4),
                            titleEn: "PSS calibration", titleAr: "معايرة نظام النقاط",
                            descriptionEn: "Daedo PSS recalibrated for the new season.",
                            descriptionAr: "إعادة معايرة نظام Daedo للموسم الجديد.",
                            category: .recordSet),
            BranchMilestone(branchID: branchAlNasserya.id, occurredAt: branchAlNasserya.foundedAt,
                            titleEn: "Branch founded", titleAr: "تأسيس الفرع",
                            category: .founded),
            BranchMilestone(branchID: branchAlNasserya.id, occurredAt: monthsAgo(20),
                            titleEn: "Hall renovation", titleAr: "تجديد القاعة",
                            descriptionEn: "Mat replacement and AC upgrade.",
                            descriptionAr: "استبدال السجاد وتطوير التكييف.",
                            category: .renovation),
            BranchMilestone(branchID: branchIndustrial18.id, occurredAt: branchIndustrial18.foundedAt,
                            titleEn: "Branch founded", titleAr: "تأسيس الفرع",
                            category: .founded),
            BranchMilestone(branchID: branchIndustrial18.id, occurredAt: monthsAgo(6),
                            titleEn: "Community partnership",
                            titleAr: "شراكة مجتمعية",
                            descriptionEn: "Sharjah Community Centre partnership renewed.",
                            descriptionAr: "تجديد شراكة مركز الشارقة المجتمعي.",
                            category: .partnership),
            BranchMilestone(branchID: branchAlRahmania.id, occurredAt: branchAlRahmania.foundedAt,
                            titleEn: "Girls-only branch opens", titleAr: "افتتاح الفرع النسائي",
                            descriptionEn: "Sharjah's first dedicated women's taekwondo dojang.",
                            descriptionAr: "أول دوجانغ تايكوندو مخصص للنساء في الشارقة.",
                            category: .founded),
            BranchMilestone(branchID: branchAlRahmania.id, occurredAt: monthsAgo(3),
                            titleEn: "First female national medal",
                            titleAr: "أول ميدالية وطنية للناشئات",
                            descriptionEn: "First female athlete from Al Nouf wins UAE bronze.",
                            descriptionAr: "أول رياضية من النوف تحصد برونزية الإمارات.",
                            category: .alumniAchievement),
        ]

        // === Squads: cross-branch groups for competitions & activities ===
        let squadCompetition = AthleteGroup(
            name: "UAE Junior Open Squad",
            nameAr: "فريق بطولة الإمارات للناشئين",
            purpose: .competition,
            createdByCoachID: coachAli.id,
            athleteIDs: [a4.id, a6.id, a9.id, g2.id, g5.id],
            createdAt: days(-10),
            linkedTournamentID: upcomingTournament.id,
            nationalityFilter: "AE",
            notes: "Emirati nationals only — UAE Junior Open requirement"
        )
        let squadCadetCamp = AthleteGroup(
            name: "Cadet Training Camp",
            nameAr: "معسكر تدريب الكاديت",
            purpose: .trainingCamp,
            createdByCoachID: coachYassin.id,
            athleteIDs: [a1.id, a2.id, a8.id, a9.id, g1.id, g4.id],
            createdAt: days(-5),
            expiresAt: days(30),
            ageGroupFilter: .cadets,
            notes: "Pre-season intensive for all cadets across branches"
        )
        let squadGrading = AthleteGroup(
            name: "Grading Batch — May 2026",
            nameAr: "دفعة الاختبار — مايو 2026",
            purpose: .grading,
            createdByCoachID: coachAli.id,
            athleteIDs: [a3.id, a8.id, g4.id],
            createdAt: days(-3),
            expiresAt: days(21)
        )
        let allSquads = [squadCompetition, squadCadetCamp, squadGrading]

        // === Stage 1.6 coach-redesign dossier seed ===
        //
        // Enrich all 4 coaches with federation IDs, identity, specialisation,
        // role, status, competency ratings, ranking, and a handful of peer
        // notes so the new Coach Profile cards have realistic content.
        for index in coaches.indices {
            var c = coaches[index]
            c.nationality = "AE"
            c.gender = .male
            c.federationCoachID = String(format: "UAE-CO-%04d", 1024 + index * 41)
            c.worldTaekwondoCoachID = String(format: "WT-CO-%06d", 280011 + index * 137)
            c.emiratesID = String(format: "784-198%d-%07d-%d", index % 10, 1234567 + index * 11, (index + 3) % 10)
            c.bloodType = [.oPositive, .aPositive, .bPositive, .abNegative][index % 4]
            c.mobileNumber = String(format: "+9715%d-%07d", index, 1234500 + index * 17)
            c.email = "\(c.fullName.split(separator: " ").first.map(String.init)?.lowercased() ?? "coach")@ssdc.ae"

            switch index {
            case 0:
                // coachAli — Head of Performance, the most senior coach
                c.coachLevel = .head
                c.licenseLevel = .dan4
                c.specialisation = .multi
                c.nationalTeamStatus = .leadStaff
                c.olympicProgramStatus = .member
                c.technicalLevel = 5
                c.sparringLevel = 5
                c.poomsaeLevel = 4
                c.fitnessLevel = 5
                c.ranking = CoachRanking(club: 1, uae: 3, worldTier: "Class A", asOf: days(-7))
                c.coachNotes = [
                    CoachNote(
                        authorCoachID: coachYassin.id,
                        authorName: coachYassin.fullName,
                        date: days(-10),
                        category: .technical,
                        body: "Phenomenal session-design depth. Cadet squad showed clear improvement on guard discipline within two weeks.",
                        isPinned: true
                    ),
                    CoachNote(
                        authorCoachID: nil,
                        authorName: "HQ Performance Review",
                        date: days(-45),
                        category: .general,
                        body: "Year-end review: exceeded targets on athlete progression. Recommended for international assignment in next cycle."
                    )
                ]
            case 1:
                // coachYassin — Senior Sparring Coach
                c.coachLevel = .senior
                c.licenseLevel = .dan3
                c.specialisation = .sparring
                c.nationalTeamStatus = .supportStaff
                c.olympicProgramStatus = .candidate
                c.technicalLevel = 4
                c.sparringLevel = 5
                c.poomsaeLevel = 3
                c.fitnessLevel = 4
                c.ranking = CoachRanking(club: 3, uae: 12, worldTier: "Class B", asOf: days(-7))
                c.coachNotes = [
                    CoachNote(
                        authorCoachID: coachAli.id,
                        authorName: coachAli.fullName,
                        date: days(-6),
                        category: .tactical,
                        body: "Match-tape analysis sessions with juniors are exceptional. Continue the weekly cadence."
                    )
                ]
            case 2:
                // coachAshraf — Poomsae specialist
                c.coachLevel = .senior
                c.licenseLevel = .dan2
                c.specialisation = .poomsae
                c.nationalTeamStatus = .member
                c.technicalLevel = 5
                c.sparringLevel = 3
                c.poomsaeLevel = 5
                c.fitnessLevel = 3
                c.ranking = CoachRanking(club: 4, uae: 18, worldTier: "Class B", asOf: days(-7))
                c.coachNotes = [
                    CoachNote(
                        authorCoachID: coachAli.id,
                        authorName: coachAli.fullName,
                        date: days(-14),
                        category: .technical,
                        body: "Poomsae syllabus alignment with WT 2024 changes is up-to-date. Other coaches should consult on technical breakdowns."
                    )
                ]
            default:
                // coachElias — Junior development
                c.coachLevel = .junior
                c.licenseLevel = .dan1
                c.specialisation = .technical
                c.technicalLevel = 4
                c.sparringLevel = 3
                c.poomsaeLevel = 4
                c.fitnessLevel = 4
                c.ranking = CoachRanking(club: 7, uae: 34, worldTier: nil, asOf: days(-7))
            }
            coaches[index] = c
        }

        // === Stage 1.6 athlete-redesign dossier seed ===
        //
        // Enrich the first 4 athletes with worldTaekwondoID + coach notes +
        // documents + ranking snapshots so the redesigned profile cards have
        // realistic content out of the box. Append-only mutation against the
        // existing array — does not touch any other seeded data.
        for index in 0..<min(4, athletes.count) {
            var dossier = athletes[index]
            dossier.worldTaekwondoID = String(format: "WT-%07d", 1010234 + index * 137)

            let authorName = coachAli.fullName
            let authorID = coachAli.id

            switch index {
            case 0:
                dossier.coachNotes = [
                    CoachNote(
                        authorCoachID: authorID,
                        authorName: authorName,
                        date: days(-2),
                        category: .tactical,
                        body: "Excellent ring control in last sparring block. Keep pushing on opening exchanges — opponent dropped guard within first 15s consistently.",
                        isPinned: true
                    ),
                    CoachNote(
                        authorCoachID: authorID,
                        authorName: authorName,
                        date: days(-9),
                        category: .technical,
                        body: "Spinning back kick still telegraphing on the load. Drill the chamber-to-release transition this week."
                    ),
                    CoachNote(
                        authorCoachID: authorID,
                        authorName: authorName,
                        date: days(-21),
                        category: .mental,
                        body: "Composure rating improved this cycle. Pre-match routine is working — keep the breathing protocol."
                    )
                ]
                dossier.documents = [
                    AthleteDocument(kind: .emiratesID, issuedAt: years(-3), expiresAt: years(2), status: .valid),
                    AthleteDocument(kind: .passport, issuedAt: years(-5), expiresAt: years(3), status: .valid),
                    AthleteDocument(kind: .federationLicence, issuedAt: days(-200), expiresAt: days(165), status: .valid),
                    AthleteDocument(kind: .worldTaekwondoCard, issuedAt: days(-180), expiresAt: days(20), status: .expiringSoon),
                    AthleteDocument(kind: .medicalClearance, issuedAt: days(-120), expiresAt: days(245), status: .valid),
                    AthleteDocument(kind: .imageRightsConsent, issuedAt: days(-365), status: .valid),
                    AthleteDocument(kind: .travelPermission, issuedAt: days(-90), expiresAt: days(275), status: .valid)
                ]
                dossier.ranking = AthleteRanking(club: 2, uae: 5, world: 158, olympic: nil, asOf: days(-7))

            case 1:
                dossier.coachNotes = [
                    CoachNote(
                        authorCoachID: authorID,
                        authorName: authorName,
                        date: days(-5),
                        category: .technical,
                        body: "Hook kick mechanics are now textbook. Time to layer in feint combinations off the back leg.",
                        isPinned: true
                    ),
                    CoachNote(
                        authorCoachID: authorID,
                        authorName: authorName,
                        date: days(-18),
                        category: .behavioural,
                        body: "Leadership in junior class drills — pairing with newer athletes is paying dividends for both sides."
                    )
                ]
                dossier.documents = [
                    AthleteDocument(kind: .emiratesID, issuedAt: years(-2), expiresAt: years(3), status: .valid),
                    AthleteDocument(kind: .passport, issuedAt: years(-4), expiresAt: years(4), status: .valid),
                    AthleteDocument(kind: .federationLicence, issuedAt: days(-150), expiresAt: days(215), status: .valid),
                    AthleteDocument(kind: .medicalClearance, issuedAt: days(-200), expiresAt: days(-10), status: .expired),
                    AthleteDocument(kind: .imageRightsConsent, issuedAt: days(-300), status: .valid)
                ]
                dossier.ranking = AthleteRanking(club: 4, uae: 12, world: nil, olympic: nil, asOf: days(-7))

            case 2:
                dossier.coachNotes = [
                    CoachNote(
                        authorCoachID: authorID,
                        authorName: authorName,
                        date: days(-4),
                        category: .general,
                        body: "Sparring confidence is climbing. Ready to step up to next category for the upcoming open."
                    )
                ]
                dossier.documents = [
                    AthleteDocument(kind: .emiratesID, issuedAt: years(-2), expiresAt: years(3), status: .valid),
                    AthleteDocument(kind: .federationLicence, issuedAt: days(-100), expiresAt: days(265), status: .valid),
                    AthleteDocument(kind: .medicalClearance, issuedAt: days(-60), expiresAt: days(305), status: .valid)
                ]
                dossier.ranking = AthleteRanking(club: 6, uae: 23, world: nil, olympic: nil, asOf: days(-7))

            case 3:
                dossier.coachNotes = [
                    CoachNote(
                        authorCoachID: authorID,
                        authorName: authorName,
                        date: days(-11),
                        category: .medical,
                        body: "Cleared post-knee niggle. Volume back to baseline next cycle."
                    )
                ]
                dossier.documents = [
                    AthleteDocument(kind: .emiratesID, issuedAt: years(-1), expiresAt: years(4), status: .valid),
                    AthleteDocument(kind: .federationLicence, issuedAt: days(-80), expiresAt: days(285), status: .valid)
                ]

            default:
                break
            }

            athletes[index] = dossier
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
            physicalMetrics: physicalMetrics,
            technicalSkills: technicalSkills,
            poomsaeAssessments: poomsaeAssessments,
            trainingLoad: trainingLoad,
            drills: drills,
            improvementPlans: improvementPlans,
            peerBenchmarks: peerBenchmarks,
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
            athleteGroups: allSquads,
            defaultCurrentUserID: userDev.id
        )
    }
}

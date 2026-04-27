import SwiftUI
import Charts

public enum BranchEditTab: String, CaseIterable, Hashable {
    case identity, facility, hours, programs, pricing, inventory
    case compliance, media, social, safeguarding, financials, milestones

    public var labelKey: LocalizedStringKey {
        switch self {
        case .identity: return "branch.tab.identity"
        case .facility: return "branch.tab.facility"
        case .hours: return "branch.tab.hours"
        case .programs: return "branch.tab.programs"
        case .pricing: return "branch.tab.pricing"
        case .inventory: return "branch.tab.inventory"
        case .compliance: return "branch.tab.compliance"
        case .media: return "branch.tab.media"
        case .social: return "branch.tab.social"
        case .safeguarding: return "branch.tab.safeguarding"
        case .financials: return "branch.tab.financials"
        case .milestones: return "branch.tab.milestones"
        }
    }

    public var icon: String {
        switch self {
        case .identity: return "info.circle.fill"
        case .facility: return "building.2.fill"
        case .hours: return "clock.fill"
        case .programs: return "person.3.fill"
        case .pricing: return "tag.fill"
        case .inventory: return "shippingbox.fill"
        case .compliance: return "checkmark.shield.fill"
        case .media: return "photo.fill"
        case .social: return "link"
        case .safeguarding: return "hand.raised.fill"
        case .financials: return "dollarsign.circle.fill"
        case .milestones: return "rosette"
        }
    }
}

public struct BranchEditView: View {
    @Environment(AppSession.self) private var session
    @State private var store: BranchProfileStore?
    @State private var selectedTab: BranchEditTab

    public let branchID: EntityID

    public init(branchID: EntityID, initialTab: BranchEditTab = .identity) {
        self.branchID = branchID
        _selectedTab = State(initialValue: initialTab)
    }

    public var body: some View {
        VStack(spacing: 0) {
            tabStrip
            Divider()
            ScrollView {
                Group {
                    if let store, let branch = store.branch {
                        currentTab(store: store, branch: branch)
                    } else {
                        ProgressView().padding(.top, 80)
                    }
                }
                .padding(16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Text(verbatim: store?.branch?.name ?? ""))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            if store == nil { store = BranchProfileStore(repository: session.repository) }
            await store?.load(branchID: branchID)
        }
    }

    private var visibleTabs: [BranchEditTab] {
        let canSeeFinancials = (session.currentUser?.role).map {
            PermissionMatrix.allowed(role: $0, permission: .viewBranchFinancials)
        } ?? false
        return BranchEditTab.allCases.filter { $0 != .financials || canSeeFinancials }
    }

    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(visibleTabs, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Label(tab.labelKey, systemImage: tab.icon)
                            .font(.caption.bold())
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(selectedTab == tab ? Color.accentColor : Color(.tertiarySystemGroupedBackground),
                                        in: Capsule())
                            .foregroundStyle(selectedTab == tab ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private func currentTab(store: BranchProfileStore, branch: Branch) -> some View {
        switch selectedTab {
        case .identity:
            IdentityEditor(branch: branch, save: saveBranch)
        case .facility:
            FacilityEditor(branchID: branch.id, facility: store.facility, save: saveFacility)
        case .hours:
            HoursEditor(branchID: branch.id, hours: store.hours, save: saveHours)
        case .programs:
            ProgramsEditor(branchID: branch.id, programs: store.programs, save: saveProgram)
        case .pricing:
            PricingEditor(branchID: branch.id, pricing: store.pricing, save: savePricing)
        case .inventory:
            InventoryEditor(branchID: branch.id, inventory: store.inventory,
                            currentUserID: session.currentUser?.id ?? UUID(),
                            save: saveInventory)
        case .compliance:
            ComplianceEditor(branchID: branch.id, compliance: store.compliance, save: saveCompliance)
        case .media:
            MediaEditor(branchID: branch.id, media: store.media, save: saveMedia)
        case .social:
            SocialEditor(branchID: branch.id, links: store.socialLinks, save: saveSocial)
        case .safeguarding:
            SafeguardingEditor(branchID: branch.id, safe: store.safeguarding,
                               coaches: store.coaches, save: saveSafeguarding)
        case .financials:
            FinancialsEditor(branchID: branch.id, financials: store.financials, save: saveFinancials)
        case .milestones:
            MilestonesEditor(branchID: branch.id, milestones: store.milestones, save: saveMilestone)
        }
    }

    // MARK: - Save handlers (each refreshes the relevant slice)

    private func saveBranch(_ b: Branch) async {
        // Branch identity is part of the core branches table — there's no
        // dedicated upsert in the protocol yet. Stage 5 wires this up; for
        // demo we mutate the in-memory copy via the existing branch list
        // by writing back through the matching profile sub-records is wrong,
        // so we punt with a print until that hook lands.
        print("Stage 1.5 limitation: Branch core identity save not wired (waiting on upsert(_ branch:)).")
        await store?.load(branchID: branchID)
    }

    private func saveFacility(_ f: BranchFacility) async {
        try? await session.repository.upsert(f)
        await store?.load(branchID: branchID)
    }
    private func saveHours(_ h: BranchHours) async {
        try? await session.repository.upsert(h)
        await store?.load(branchID: branchID)
    }
    private func saveProgram(_ p: BranchProgram) async {
        try? await session.repository.upsert(p)
        await store?.load(branchID: branchID)
    }
    private func savePricing(_ p: BranchPricing) async {
        try? await session.repository.upsert(p)
        await store?.load(branchID: branchID)
    }
    private func saveInventory(_ i: BranchInventory) async {
        try? await session.repository.upsert(i)
        await store?.load(branchID: branchID)
    }
    private func saveCompliance(_ c: BranchCompliance) async {
        try? await session.repository.upsert(c)
        await store?.load(branchID: branchID)
    }
    private func saveMedia(_ m: BranchMedia) async {
        try? await session.repository.upsert(m)
        await store?.load(branchID: branchID)
    }
    private func saveSocial(_ s: BranchSocialLinks) async {
        try? await session.repository.upsert(s)
        await store?.load(branchID: branchID)
    }
    private func saveSafeguarding(_ s: BranchSafeguarding) async {
        try? await session.repository.upsert(s)
        await store?.load(branchID: branchID)
    }
    private func saveFinancials(_ f: BranchFinancials) async {
        try? await session.repository.upsert(f)
        await store?.load(branchID: branchID)
    }
    private func saveMilestone(_ m: BranchMilestone) async {
        try? await session.repository.upsert(m)
        await store?.load(branchID: branchID)
    }
}

// MARK: - Identity tab

private struct IdentityEditor: View {
    let branch: Branch
    let save: (Branch) async -> Void

    @State private var name: String
    @State private var nameAr: String
    @State private var area: String
    @State private var capacity: Int
    @State private var focus: String
    @State private var streetAddress: String
    @State private var streetAddressAr: String
    @State private var phone: String
    @State private var email: String
    @State private var taglineEn: String
    @State private var taglineAr: String
    @State private var brandHex: String

    init(branch: Branch, save: @escaping (Branch) async -> Void) {
        self.branch = branch
        self.save = save
        _name = State(initialValue: branch.name)
        _nameAr = State(initialValue: branch.nameAr)
        _area = State(initialValue: branch.area)
        _capacity = State(initialValue: branch.capacity)
        _focus = State(initialValue: branch.focus)
        _streetAddress = State(initialValue: branch.streetAddress)
        _streetAddressAr = State(initialValue: branch.streetAddressAr)
        _phone = State(initialValue: branch.phone)
        _email = State(initialValue: branch.email)
        _taglineEn = State(initialValue: branch.taglineEn ?? "")
        _taglineAr = State(initialValue: branch.taglineAr ?? "")
        _brandHex = State(initialValue: branch.brandHexColor ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("branch.tab.identity")
            labeled("auth.full_name") { TextField("auth.full_name", text: $name).textFieldStyle(.roundedBorder) }
            labeled("auth.full_name_ar") {
                TextField("auth.full_name_ar", text: $nameAr).textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
            }
            HStack {
                labeled("branch.area") { TextField("branch.area", text: $area).textFieldStyle(.roundedBorder) }
                labeled("branch.capacity") {
                    Stepper(value: $capacity, in: 0...500) {
                        Text(verbatim: "\(capacity)")
                    }
                }
            }
            labeled("branch.focus") { TextField("branch.focus", text: $focus).textFieldStyle(.roundedBorder) }
            labeled("branch.address") {
                TextField("branch.address", text: $streetAddress, axis: .vertical)
                    .lineLimit(2...3).textFieldStyle(.roundedBorder)
            }
            labeled("branch.address_ar") {
                TextField("branch.address_ar", text: $streetAddressAr, axis: .vertical)
                    .lineLimit(2...3).textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
            }
            HStack {
                labeled("branch.phone") { TextField("branch.phone", text: $phone).textFieldStyle(.roundedBorder) }
                labeled("branch.email") { TextField("branch.email", text: $email).textFieldStyle(.roundedBorder) }
            }
            labeled("branch.tagline_en") {
                TextField("branch.tagline_en", text: $taglineEn).textFieldStyle(.roundedBorder)
            }
            labeled("branch.tagline_ar") {
                TextField("branch.tagline_ar", text: $taglineAr).textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
            }
            labeled("branch.brand_color") {
                TextField("#E24B4A", text: $brandHex).textFieldStyle(.roundedBorder)
                    .environment(\.layoutDirection, .leftToRight)
            }
            saveBar {
                var b = branch
                b.name = name
                b.nameAr = nameAr
                b.area = area
                b.capacity = capacity
                b.focus = focus
                b.streetAddress = streetAddress
                b.streetAddressAr = streetAddressAr
                b.phone = phone
                b.email = email
                b.taglineEn = taglineEn.isEmpty ? nil : taglineEn
                b.taglineAr = taglineAr.isEmpty ? nil : taglineAr
                b.brandHexColor = brandHex.isEmpty ? nil : brandHex
                Task { await save(b) }
            }
        }
    }
}

// MARK: - Facility tab

private struct FacilityEditor: View {
    let branchID: EntityID
    let facility: BranchFacility?
    let save: (BranchFacility) async -> Void

    @State private var floorAreaSqm: Double
    @State private var hallCount: Int
    @State private var hasMirrorWalls: Bool
    @State private var hasSoundSystem: Bool
    @State private var hasAC: Bool
    @State private var hasInstalledScoreboard: Bool
    @State private var hasPSS: Bool
    @State private var pssBrand: String
    @State private var spectatorSeats: Int
    @State private var parkingSpots: Int
    @State private var hasPrayerRoom: Bool
    @State private var hasWudu: Bool

    init(branchID: EntityID, facility: BranchFacility?, save: @escaping (BranchFacility) async -> Void) {
        self.branchID = branchID
        self.facility = facility
        self.save = save
        _floorAreaSqm = State(initialValue: facility?.floorAreaSqm ?? 0)
        _hallCount = State(initialValue: facility?.hallCount ?? 1)
        _hasMirrorWalls = State(initialValue: facility?.hasMirrorWalls ?? false)
        _hasSoundSystem = State(initialValue: facility?.hasSoundSystem ?? false)
        _hasAC = State(initialValue: facility?.hasAC ?? true)
        _hasInstalledScoreboard = State(initialValue: facility?.hasInstalledScoreboard ?? false)
        _hasPSS = State(initialValue: facility?.hasPSS ?? false)
        _pssBrand = State(initialValue: facility?.pssBrand ?? "")
        _spectatorSeats = State(initialValue: facility?.spectatorSeats ?? 0)
        _parkingSpots = State(initialValue: facility?.parkingSpots ?? 0)
        _hasPrayerRoom = State(initialValue: facility?.hasPrayerRoom ?? false)
        _hasWudu = State(initialValue: facility?.hasWudu ?? false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("branch.tab.facility")
            HStack {
                labeled("facility.floor_area") {
                    Stepper(value: $floorAreaSqm, in: 0...10_000, step: 50) {
                        Text(verbatim: "\(Int(floorAreaSqm)) m²")
                    }
                }
                labeled("facility.halls") {
                    Stepper(value: $hallCount, in: 1...10) {
                        Text(verbatim: "\(hallCount)")
                    }
                }
            }
            Toggle("facility.mirror_walls", isOn: $hasMirrorWalls)
            Toggle("facility.sound_system", isOn: $hasSoundSystem)
            Toggle("facility.ac", isOn: $hasAC)
            Toggle("facility.scoreboard", isOn: $hasInstalledScoreboard)
            Toggle("facility.pss", isOn: $hasPSS)
            if hasPSS {
                labeled("facility.pss_brand") {
                    TextField("Daedo / KP&P", text: $pssBrand).textFieldStyle(.roundedBorder)
                }
            }
            HStack {
                labeled("facility.spectator_seats") {
                    Stepper(value: $spectatorSeats, in: 0...500) {
                        Text(verbatim: "\(spectatorSeats)")
                    }
                }
                labeled("facility.parking") {
                    Stepper(value: $parkingSpots, in: 0...500) {
                        Text(verbatim: "\(parkingSpots)")
                    }
                }
            }
            Toggle("facility.prayer_room", isOn: $hasPrayerRoom)
            Toggle("facility.wudu", isOn: $hasWudu)
            saveBar {
                var f = facility ?? BranchFacility(branchID: branchID, floorAreaSqm: floorAreaSqm, hallCount: hallCount)
                f.floorAreaSqm = floorAreaSqm
                f.hallCount = hallCount
                f.hasMirrorWalls = hasMirrorWalls
                f.hasSoundSystem = hasSoundSystem
                f.hasAC = hasAC
                f.hasInstalledScoreboard = hasInstalledScoreboard
                f.hasPSS = hasPSS
                f.pssBrand = pssBrand.isEmpty ? nil : pssBrand
                f.spectatorSeats = spectatorSeats
                f.parkingSpots = parkingSpots
                f.hasPrayerRoom = hasPrayerRoom
                f.hasWudu = hasWudu
                Task { await save(f) }
            }
        }
    }
}

// MARK: - Hours tab

private struct HoursEditor: View {
    let branchID: EntityID
    let hours: BranchHours?
    let save: (BranchHours) async -> Void

    @State private var rows: [DayHours]

    init(branchID: EntityID, hours: BranchHours?, save: @escaping (BranchHours) async -> Void) {
        self.branchID = branchID
        self.hours = hours
        self.save = save
        let regular = hours?.regular ?? DayOfWeek.allCases.map {
            DayHours(day: $0, isOpen: true, opensAt: "16:00", closesAt: "21:00")
        }
        _rows = State(initialValue: regular)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("branch.tab.hours")
            ForEach(rows.indices, id: \.self) { i in
                HStack(spacing: 8) {
                    Text(LocalizedStringKey(rows[i].day.labelKey))
                        .font(.caption.bold())
                        .frame(width: 56, alignment: .leading)
                    Toggle("", isOn: Binding(
                        get: { rows[i].isOpen },
                        set: { rows[i].isOpen = $0 }
                    )).labelsHidden()
                    if rows[i].isOpen {
                        TextField("06:00", text: Binding(
                            get: { rows[i].opensAt ?? "" },
                            set: { rows[i].opensAt = $0.isEmpty ? nil : $0 }
                        )).textFieldStyle(.roundedBorder).frame(width: 80)
                            .environment(\.layoutDirection, .leftToRight)
                        Text(verbatim: "→")
                        TextField("23:00", text: Binding(
                            get: { rows[i].closesAt ?? "" },
                            set: { rows[i].closesAt = $0.isEmpty ? nil : $0 }
                        )).textFieldStyle(.roundedBorder).frame(width: 80)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    Spacer()
                }
            }
            saveBar {
                var h = hours ?? BranchHours(branchID: branchID, regular: rows)
                h.regular = rows
                Task { await save(h) }
            }
        }
    }
}

// MARK: - Programs tab

private struct ProgramsEditor: View {
    let branchID: EntityID
    let programs: [BranchProgram]
    let save: (BranchProgram) async -> Void

    @State private var draftIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("branch.tab.programs")
            ForEach(programs.indices, id: \.self) { i in
                ProgramRow(program: programs[i], save: save)
            }
            Button {
                let p = BranchProgram(
                    branchID: branchID,
                    customName: "New program", customNameAr: "برنامج جديد",
                    descriptionEn: "", descriptionAr: "",
                    ageGroup: .kids, disciplines: [.fundamentals],
                    schedulePattern: [.sun, .tue, .thu],
                    startTime: "16:00", endTime: "17:00",
                    capacity: 16, monthlyFeeAED: 350
                )
                Task { await save(p) }
            } label: {
                Label("manager.add_program", systemImage: "plus.circle.fill")
            }
        }
    }
}

private struct ProgramRow: View {
    @State var program: BranchProgram
    let save: (BranchProgram) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField("name", text: Binding(
                    get: { program.customName ?? "" },
                    set: { program.customName = $0 }
                )).textFieldStyle(.roundedBorder)
                Toggle("", isOn: $program.isActive).labelsHidden()
            }
            HStack {
                Stepper(value: $program.capacity, in: 0...100) {
                    Text(verbatim: "Cap \(program.capacity)")
                        .environment(\.layoutDirection, .leftToRight)
                }
                Stepper(value: $program.monthlyFeeAED, in: 0...5000, step: 25) {
                    Text(verbatim: "AED \(Int(program.monthlyFeeAED))")
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
            HStack {
                TextField("16:00", text: $program.startTime).textFieldStyle(.roundedBorder).frame(width: 80)
                    .environment(\.layoutDirection, .leftToRight)
                Text(verbatim: "→")
                TextField("17:00", text: $program.endTime).textFieldStyle(.roundedBorder).frame(width: 80)
                    .environment(\.layoutDirection, .leftToRight)
                Spacer()
                Button("action.save") { Task { await save(program) } }.buttonStyle(.borderedProminent)
            }
        }
        .padding(8)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Pricing tab

private struct PricingEditor: View {
    let branchID: EntityID
    let pricing: BranchPricing?
    let save: (BranchPricing) async -> Void

    @State private var base: Double
    @State private var trial: Double
    @State private var registration: Double
    @State private var equipment: Double
    @State private var siblingPct: Double
    @State private var prepayPct: Double

    init(branchID: EntityID, pricing: BranchPricing?, save: @escaping (BranchPricing) async -> Void) {
        self.branchID = branchID
        self.pricing = pricing
        self.save = save
        _base = State(initialValue: pricing?.baseMonthlyFeeAED ?? 350)
        _trial = State(initialValue: pricing?.trialClassFeeAED ?? 50)
        _registration = State(initialValue: pricing?.registrationFeeAED ?? 200)
        _equipment = State(initialValue: pricing?.equipmentPackageFeeAED ?? 350)
        _siblingPct = State(initialValue: pricing?.siblingDiscountPct ?? 0.1)
        _prepayPct = State(initialValue: pricing?.annualPrepayDiscountPct ?? 0.05)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("branch.tab.pricing")
            stepperAED("program.monthly_fee", value: $base, step: 25)
            stepperAED("program.trial_class", value: $trial, step: 5)
            stepperAED("program.registration_fee", value: $registration, step: 10)
            stepperAED("program.equipment_package", value: $equipment, step: 10)
            HStack {
                Text("program.sibling_discount").font(.caption)
                Slider(value: $siblingPct, in: 0...0.5)
                Text(verbatim: "\(Int(siblingPct * 100))%").frame(width: 44).font(.caption.monospacedDigit())
                    .environment(\.layoutDirection, .leftToRight)
            }
            HStack {
                Text("program.annual_prepay").font(.caption)
                Slider(value: $prepayPct, in: 0...0.3)
                Text(verbatim: "\(Int(prepayPct * 100))%").frame(width: 44).font(.caption.monospacedDigit())
                    .environment(\.layoutDirection, .leftToRight)
            }
            saveBar {
                var p = pricing ?? BranchPricing(
                    branchID: branchID, baseMonthlyFeeAED: base,
                    trialClassFeeAED: trial, registrationFeeAED: registration,
                    equipmentPackageFeeAED: equipment
                )
                p.baseMonthlyFeeAED = base
                p.trialClassFeeAED = trial
                p.registrationFeeAED = registration
                p.equipmentPackageFeeAED = equipment
                p.siblingDiscountPct = siblingPct
                p.annualPrepayDiscountPct = prepayPct
                Task { await save(p) }
            }
        }
    }

    private func stepperAED(_ label: LocalizedStringKey, value: Binding<Double>, step: Double) -> some View {
        HStack {
            Text(label).font(.caption)
            Spacer()
            Stepper(value: value, in: 0...10_000, step: step) {
                Text(verbatim: "AED \(Int(value.wrappedValue))")
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
    }
}

// MARK: - Inventory tab

private struct InventoryEditor: View {
    let branchID: EntityID
    let inventory: BranchInventory?
    let currentUserID: EntityID
    let save: (BranchInventory) async -> Void

    @State private var items: [InventoryItem]

    init(branchID: EntityID, inventory: BranchInventory?, currentUserID: EntityID, save: @escaping (BranchInventory) async -> Void) {
        self.branchID = branchID
        self.inventory = inventory
        self.currentUserID = currentUserID
        self.save = save
        _items = State(initialValue: inventory?.items ?? [])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("branch.tab.inventory")
            if let last = inventory?.lastAuditAt {
                Text("inventory.last_audit").font(.caption2).foregroundStyle(.secondary)
                Text(last, style: .date).font(.caption2).foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            ForEach(items.indices, id: \.self) { i in
                HStack {
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey(items[i].labelKey)).font(.caption.bold())
                        if let s = items[i].size {
                            Text(verbatim: s).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Stepper(value: $items[i].quantity, in: 0...500) {
                        Text(verbatim: "\(items[i].quantity)")
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
                .padding(8)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }
            Button {
                items.append(InventoryItem(category: .other, labelKey: "inventory.other", quantity: 0))
            } label: {
                Label("manager.add_item", systemImage: "plus.circle.fill")
            }
            saveBar {
                var inv = inventory ?? BranchInventory(branchID: branchID, items: items,
                                                       lastAuditAt: Date(), lastAuditByUserID: currentUserID)
                inv.items = items
                inv.lastAuditAt = Date()
                inv.lastAuditByUserID = currentUserID
                Task { await save(inv) }
            }
        }
    }
}

// MARK: - Compliance tab

private struct ComplianceEditor: View {
    let branchID: EntityID
    let compliance: BranchCompliance?
    let save: (BranchCompliance) async -> Void

    @State private var civilNum: String
    @State private var civilDate: Date
    @State private var sportsNum: String
    @State private var sportsDate: Date
    @State private var insuranceNum: String
    @State private var insuranceProvider: String
    @State private var insuranceDate: Date
    @State private var hasAED: Bool

    init(branchID: EntityID, compliance: BranchCompliance?, save: @escaping (BranchCompliance) async -> Void) {
        self.branchID = branchID
        self.compliance = compliance
        self.save = save
        _civilNum = State(initialValue: compliance?.civilDefenceCertNumber ?? "")
        _civilDate = State(initialValue: compliance?.civilDefenceExpiry ?? Date().addingTimeInterval(365 * 24 * 3600))
        _sportsNum = State(initialValue: compliance?.sharjahSportsCouncilRegNumber ?? "")
        _sportsDate = State(initialValue: compliance?.sharjahSportsCouncilExpiry ?? Date().addingTimeInterval(365 * 24 * 3600))
        _insuranceNum = State(initialValue: compliance?.insurancePolicyNumber ?? "")
        _insuranceProvider = State(initialValue: compliance?.insuranceProvider ?? "")
        _insuranceDate = State(initialValue: compliance?.insuranceExpiry ?? Date().addingTimeInterval(365 * 24 * 3600))
        _hasAED = State(initialValue: compliance?.hasAED ?? false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("branch.tab.compliance")
            certBlock("compliance.civil_defence", number: $civilNum, expiry: $civilDate)
            certBlock("compliance.sports_council", number: $sportsNum, expiry: $sportsDate)
            VStack(alignment: .leading, spacing: 4) {
                Text("compliance.insurance").font(.caption.bold())
                TextField("policy", text: $insuranceNum).textFieldStyle(.roundedBorder)
                TextField("provider", text: $insuranceProvider).textFieldStyle(.roundedBorder)
                DatePicker("compliance.expires_on", selection: $insuranceDate, displayedComponents: .date)
            }
            Toggle("compliance.aed", isOn: $hasAED)
            saveBar {
                var c = compliance ?? BranchCompliance(branchID: branchID)
                c.civilDefenceCertNumber = civilNum.isEmpty ? nil : civilNum
                c.civilDefenceExpiry = civilDate
                c.sharjahSportsCouncilRegNumber = sportsNum.isEmpty ? nil : sportsNum
                c.sharjahSportsCouncilExpiry = sportsDate
                c.insurancePolicyNumber = insuranceNum.isEmpty ? nil : insuranceNum
                c.insuranceProvider = insuranceProvider.isEmpty ? nil : insuranceProvider
                c.insuranceExpiry = insuranceDate
                c.hasAED = hasAED
                Task { await save(c) }
            }
        }
    }

    private func certBlock(_ label: LocalizedStringKey, number: Binding<String>, expiry: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.bold())
            TextField("certificate number", text: number).textFieldStyle(.roundedBorder)
            DatePicker("compliance.expires_on", selection: expiry, displayedComponents: .date)
        }
    }
}

// MARK: - Media tab

private struct MediaEditor: View {
    let branchID: EntityID
    let media: BranchMedia?
    let save: (BranchMedia) async -> Void

    @State private var logoURL: String
    @State private var heroURL: String
    @State private var galleryRaw: String
    @State private var videoURL: String

    init(branchID: EntityID, media: BranchMedia?, save: @escaping (BranchMedia) async -> Void) {
        self.branchID = branchID
        self.media = media
        self.save = save
        _logoURL = State(initialValue: media?.logoURL ?? "")
        _heroURL = State(initialValue: media?.heroPhotoURL ?? "")
        _galleryRaw = State(initialValue: (media?.galleryURLs ?? []).joined(separator: "\n"))
        _videoURL = State(initialValue: media?.videoTourURL ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("branch.tab.media")
            Text("manager.media_url_hint").font(.caption2).foregroundStyle(.secondary)
            labeled("manager.logo_url") { TextField("https://", text: $logoURL).textFieldStyle(.roundedBorder)
                .environment(\.layoutDirection, .leftToRight) }
            labeled("manager.hero_url") { TextField("https://", text: $heroURL).textFieldStyle(.roundedBorder)
                .environment(\.layoutDirection, .leftToRight) }
            labeled("manager.gallery_urls") {
                TextField("one per line", text: $galleryRaw, axis: .vertical)
                    .lineLimit(4...8).textFieldStyle(.roundedBorder)
                    .environment(\.layoutDirection, .leftToRight)
            }
            labeled("manager.video_url") { TextField("https://", text: $videoURL).textFieldStyle(.roundedBorder)
                .environment(\.layoutDirection, .leftToRight) }
            saveBar {
                let urls = galleryRaw.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }
                                     .filter { !$0.isEmpty }
                var m = media ?? BranchMedia(branchID: branchID)
                m.logoURL = logoURL.isEmpty ? nil : logoURL
                m.heroPhotoURL = heroURL.isEmpty ? nil : heroURL
                m.galleryURLs = urls
                m.videoTourURL = videoURL.isEmpty ? nil : videoURL
                Task { await save(m) }
            }
        }
    }
}

// MARK: - Social tab

private struct SocialEditor: View {
    let branchID: EntityID
    let links: BranchSocialLinks?
    let save: (BranchSocialLinks) async -> Void

    @State private var whatsappParents: String
    @State private var whatsappAthletes: String
    @State private var instagram: String
    @State private var tiktok: String
    @State private var youtube: String
    @State private var website: String

    init(branchID: EntityID, links: BranchSocialLinks?, save: @escaping (BranchSocialLinks) async -> Void) {
        self.branchID = branchID
        self.links = links
        self.save = save
        _whatsappParents = State(initialValue: links?.whatsappParentsLink ?? "")
        _whatsappAthletes = State(initialValue: links?.whatsappAthletesLink ?? "")
        _instagram = State(initialValue: links?.instagramHandle ?? "")
        _tiktok = State(initialValue: links?.tiktokHandle ?? "")
        _youtube = State(initialValue: links?.youtubeChannelURL ?? "")
        _website = State(initialValue: links?.websiteURL ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("branch.tab.social")
            labeled("social.whatsapp_parents") {
                TextField("https://chat.whatsapp.com/", text: $whatsappParents).textFieldStyle(.roundedBorder)
                    .environment(\.layoutDirection, .leftToRight)
            }
            labeled("social.whatsapp_athletes") {
                TextField("https://chat.whatsapp.com/", text: $whatsappAthletes).textFieldStyle(.roundedBorder)
                    .environment(\.layoutDirection, .leftToRight)
            }
            labeled("social.instagram") { TextField("@handle", text: $instagram).textFieldStyle(.roundedBorder)
                .environment(\.layoutDirection, .leftToRight) }
            labeled("social.tiktok") { TextField("@handle", text: $tiktok).textFieldStyle(.roundedBorder)
                .environment(\.layoutDirection, .leftToRight) }
            labeled("social.youtube") { TextField("https://", text: $youtube).textFieldStyle(.roundedBorder)
                .environment(\.layoutDirection, .leftToRight) }
            labeled("social.website") { TextField("https://", text: $website).textFieldStyle(.roundedBorder)
                .environment(\.layoutDirection, .leftToRight) }
            saveBar {
                var s = links ?? BranchSocialLinks(branchID: branchID)
                s.whatsappParentsLink = whatsappParents.isEmpty ? nil : whatsappParents
                s.whatsappAthletesLink = whatsappAthletes.isEmpty ? nil : whatsappAthletes
                s.instagramHandle = instagram.isEmpty ? nil : instagram
                s.tiktokHandle = tiktok.isEmpty ? nil : tiktok
                s.youtubeChannelURL = youtube.isEmpty ? nil : youtube
                s.websiteURL = website.isEmpty ? nil : website
                Task { await save(s) }
            }
        }
    }
}

// MARK: - Safeguarding tab

private struct SafeguardingEditor: View {
    let branchID: EntityID
    let safe: BranchSafeguarding?
    let coaches: [Coach]
    let save: (BranchSafeguarding) async -> Void

    @State private var officerID: EntityID?
    @State private var lastTraining: Date
    @State private var policyURL: String

    init(branchID: EntityID, safe: BranchSafeguarding?, coaches: [Coach], save: @escaping (BranchSafeguarding) async -> Void) {
        self.branchID = branchID
        self.safe = safe
        self.coaches = coaches
        self.save = save
        _officerID = State(initialValue: safe?.safeguardingOfficerCoachID)
        _lastTraining = State(initialValue: safe?.lastTeamTrainingAt ?? Date())
        _policyURL = State(initialValue: safe?.policyDocumentURL ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("branch.tab.safeguarding")
            labeled("safeguarding.officer") {
                Menu {
                    Button("filter.none") { officerID = nil }
                    Divider()
                    ForEach(coaches) { c in
                        Button { officerID = c.id } label: { Text(verbatim: c.fullName) }
                    }
                } label: {
                    HStack {
                        Text(verbatim: coaches.first(where: { $0.id == officerID })?.fullName ?? "—")
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down").font(.caption2)
                    }
                    .padding(6).background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 6))
                }
            }
            DatePicker("safeguarding.last_training", selection: $lastTraining, displayedComponents: .date)
            labeled("safeguarding.policy_url") {
                TextField("https://", text: $policyURL).textFieldStyle(.roundedBorder)
                    .environment(\.layoutDirection, .leftToRight)
            }
            saveBar {
                var s = safe ?? BranchSafeguarding(branchID: branchID)
                s.safeguardingOfficerCoachID = officerID
                s.lastTeamTrainingAt = lastTraining
                s.policyDocumentURL = policyURL.isEmpty ? nil : policyURL
                Task { await save(s) }
            }
        }
    }
}

// MARK: - Financials tab (admin-gated)

private struct FinancialsEditor: View {
    let branchID: EntityID
    let financials: [BranchFinancials]
    let save: (BranchFinancials) async -> Void

    @State private var month: Date = Date()
    @State private var revenue: Double = 0
    @State private var rent: Double = 0
    @State private var utilities: Double = 0
    @State private var staff: Double = 0
    @State private var equipment: Double = 0
    @State private var marketing: Double = 0
    @State private var other: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("branch.tab.financials")
            if !financials.isEmpty {
                financialsChart
                financialsTable
                Divider()
            }
            sectionTitle("manager.add_month")
            DatePicker("financials.month", selection: $month, displayedComponents: .date)
            stepperAED("financials.revenue", value: $revenue)
            stepperAED("financials.rent", value: $rent)
            stepperAED("financials.utilities", value: $utilities)
            stepperAED("financials.staff_cost", value: $staff)
            stepperAED("financials.equipment", value: $equipment)
            stepperAED("financials.marketing", value: $marketing)
            stepperAED("financials.other", value: $other)
            saveBar {
                let cal = Calendar.current
                let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: month)) ?? month
                let f = BranchFinancials(
                    branchID: branchID, month: monthStart,
                    revenueAED: revenue, rentAED: rent, utilitiesAED: utilities,
                    staffCostAED: staff, equipmentAED: equipment,
                    marketingAED: marketing, otherExpensesAED: other
                )
                Task { await save(f) }
            }
        }
    }

    private var financialsChart: some View {
        Chart(financials) { f in
            BarMark(
                x: .value("month", f.month, unit: .month),
                y: .value("revenue", f.revenueAED)
            ).foregroundStyle(.green)
            BarMark(
                x: .value("month", f.month, unit: .month),
                y: .value("expenses", -f.totalExpensesAED)
            ).foregroundStyle(.red)
        }
        .frame(height: 200)
    }

    private var financialsTable: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(financials) { f in
                HStack {
                    Text(f.month, format: .dateTime.month(.abbreviated).year())
                        .font(.caption.monospacedDigit())
                        .frame(width: 80, alignment: .leading)
                        .environment(\.layoutDirection, .leftToRight)
                    Text(verbatim: "+\(Int(f.revenueAED))").foregroundStyle(.green)
                        .font(.caption.monospacedDigit())
                        .environment(\.layoutDirection, .leftToRight)
                    Text(verbatim: "−\(Int(f.totalExpensesAED))").foregroundStyle(.red)
                        .font(.caption.monospacedDigit())
                        .environment(\.layoutDirection, .leftToRight)
                    Spacer()
                    Text(verbatim: "\(Int(f.netContributionAED))")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(f.netContributionAED >= 0 ? .green : .red)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
        }
    }

    private func stepperAED(_ label: LocalizedStringKey, value: Binding<Double>) -> some View {
        HStack {
            Text(label).font(.caption)
            Spacer()
            Stepper(value: value, in: 0...1_000_000, step: 500) {
                Text(verbatim: "AED \(Int(value.wrappedValue))")
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
    }
}

// MARK: - Milestones tab

private struct MilestonesEditor: View {
    let branchID: EntityID
    let milestones: [BranchMilestone]
    let save: (BranchMilestone) async -> Void

    @State private var titleEn: String = ""
    @State private var titleAr: String = ""
    @State private var category: MilestoneCategory = .recordSet
    @State private var occurredAt: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("branch.tab.milestones")
            ForEach(milestones) { m in
                HStack {
                    Image(systemName: "circle.fill").font(.caption2).foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: m.titleEn).font(.caption.bold())
                        Text(m.occurredAt, style: .date).font(.caption2).foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    Spacer()
                    Text(LocalizedStringKey(m.category.labelKey))
                        .font(.caption2).foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }
            Divider()
            sectionTitle("manager.add_milestone")
            TextField("title (en)", text: $titleEn).textFieldStyle(.roundedBorder)
            TextField("title (ar)", text: $titleAr).textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
            DatePicker("financials.month", selection: $occurredAt, displayedComponents: .date)
            Picker("category", selection: $category) {
                ForEach(MilestoneCategory.allCases, id: \.self) { c in
                    Text(LocalizedStringKey(c.labelKey)).tag(c)
                }
            }
            saveBar {
                let m = BranchMilestone(
                    branchID: branchID, occurredAt: occurredAt,
                    titleEn: titleEn, titleAr: titleAr, category: category
                )
                Task {
                    await save(m)
                    titleEn = ""
                    titleAr = ""
                }
            }
        }
    }
}

// MARK: - Helpers

private func sectionTitle(_ key: LocalizedStringKey) -> some View {
    Text(key).font(.headline)
}

private func labeled<Content: View>(_ label: LocalizedStringKey, @ViewBuilder _ content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(label).font(.caption.bold()).foregroundStyle(.secondary)
        content()
    }
}

private func saveBar(_ action: @escaping () -> Void) -> some View {
    HStack {
        Spacer()
        Button {
            action()
        } label: {
            Label("action.save", systemImage: "checkmark.circle.fill")
                .font(.callout.bold())
        }
        .buttonStyle(.borderedProminent)
    }
    .padding(.top, 8)
}

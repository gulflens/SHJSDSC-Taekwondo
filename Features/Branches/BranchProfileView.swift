import SwiftUI
import MapKit

public struct BranchProfileView: View {
    @Environment(AppSession.self) private var session
    @State private var store: BranchProfileStore?
    @State private var showingEdit = false
    @State private var showingPromotions = false

    public let branchID: EntityID

    public init(branchID: EntityID) {
        self.branchID = branchID
    }

    public var body: some View {
        ScrollView {
            if let store, let branch = store.branch {
                content(store: store, branch: branch)
            } else {
                ProgressView().padding(.top, 80)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Text(verbatim: store?.branch?.name ?? ""))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if let role = session.currentUser?.role,
               PermissionMatrix.allowed(role: role, permission: .editBranchProfile) {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("manager.dashboard", systemImage: "slider.horizontal.3")
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showingEdit) {
            BranchEditView(branchID: branchID)
        }
        .task {
            if store == nil { store = BranchProfileStore(repository: session.repository) }
            await store?.load(branchID: branchID)
        }
    }

    @ViewBuilder
    private func content(store: BranchProfileStore, branch: Branch) -> some View {
        VStack(spacing: 18) {
            heroSection(store: store, branch: branch)
            quickInfoStrip(store: store, branch: branch)
            aboutSection(branch: branch)
            if !store.programs.isEmpty {
                programsSection(store: store)
            }
            if let hours = store.hours {
                hoursSection(hours: hours)
            }
            facilityTour(store: store)
            if let pricing = store.pricing {
                pricingSection(pricing: pricing)
            }
            if !store.coaches.isEmpty {
                coachesSection(coaches: store.coaches)
            }
            if !store.milestones.isEmpty {
                achievementsSection(milestones: store.milestones)
            }
            if let social = store.socialLinks {
                connectSection(links: social, branch: branch)
            }
            visitSection(branch: branch)
            Color.clear.frame(height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: 1. Hero

    private func heroSection(store: BranchProfileStore, branch: Branch) -> some View {
        ZStack(alignment: .bottomLeading) {
            heroBackground(url: store.media?.heroPhotoURL, color: brandColor(branch))
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    LinearGradient(colors: [.black.opacity(0.65), .clear],
                                   startPoint: .bottom, endPoint: .top)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: branch.name)
                    .font(.title.bold()).foregroundStyle(.white)
                Text(verbatim: branch.nameAr)
                    .font(.headline).foregroundStyle(.white.opacity(0.85))
                if let tagline = branch.taglineEn, !tagline.isEmpty {
                    Text(verbatim: tagline)
                        .font(.callout).foregroundStyle(.white.opacity(0.85))
                }
                HStack(spacing: 8) {
                    Button {
                        openInMaps(branch: branch)
                    } label: {
                        Label("branch.directions", systemImage: "map.fill")
                            .font(.caption.bold())
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(.white, in: Capsule())
                            .foregroundStyle(brandColor(branch))
                    }
                }
                .padding(.top, 4)
            }
            .padding(14)
        }
    }

    @ViewBuilder
    private func heroBackground(url: String?, color: Color) -> some View {
        if let url, let parsed = URL(string: url) {
            AsyncImage(url: parsed) { phase in
                switch phase {
                case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                default: color
                }
            }
        } else {
            color
        }
    }

    // MARK: 2. Quick info

    private func quickInfoStrip(store: BranchProfileStore, branch: Branch) -> some View {
        let isOpen = store.hours?.isOpenNow() ?? false
        let today = store.hours?.today()
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label(isOpen ? "branch.open_now" : "branch.closed_now",
                      systemImage: isOpen ? "checkmark.circle.fill" : "moon.stars.fill")
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background((isOpen ? Color.green : Color.gray).opacity(0.18), in: Capsule())
                    .foregroundStyle(isOpen ? .green : .gray)
                if let today, today.isOpen, let opens = today.opensAt, let closes = today.closesAt {
                    Text(verbatim: "\(opens)–\(closes)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .environment(\.layoutDirection, .leftToRight)
                }
                Spacer()
            }
            HStack(spacing: 12) {
                if !branch.phone.isEmpty {
                    Button {
                        if let url = URL(string: "tel://\(branch.phone.filter { !$0.isWhitespace })") {
                            openURL(url)
                        }
                    } label: {
                        Label(LocalizedStringKey(branch.phone), systemImage: "phone.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
                if let wa = branch.whatsappBusiness, !wa.isEmpty {
                    Button {
                        let digits = wa.filter(\.isNumber)
                        if let url = URL(string: "https://wa.me/\(digits)") { openURL(url) }
                    } label: {
                        Label("WhatsApp", systemImage: "message.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: 3. About

    private func aboutSection(branch: Branch) -> some View {
        sectionCard(icon: "info.circle.fill", title: "branch.about") {
            VStack(alignment: .leading, spacing: 6) {
                infoRow(label: "branch.focus", value: branch.focus.capitalized)
                infoRow(label: "branch.founded", value: dateFormatter.string(from: branch.foundedAt))
                infoRow(label: "branch.area", value: branch.area)
                if !branch.streetAddress.isEmpty {
                    infoRow(label: "branch.address", value: branch.streetAddress)
                }
                if !branch.streetAddressAr.isEmpty {
                    infoRow(label: "branch.address_ar", value: branch.streetAddressAr)
                }
            }
        }
    }

    // MARK: 4. Programs

    private func programsSection(store: BranchProfileStore) -> some View {
        sectionCard(icon: "person.3.fill", title: "branch.programs") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.programs) { p in
                        ProgramCard(program: p)
                    }
                }
            }
        }
    }

    // MARK: 5. Hours

    private func hoursSection(hours: BranchHours) -> some View {
        sectionCard(icon: "clock.fill", title: "branch.hours") {
            VStack(alignment: .leading, spacing: 4) {
                if hours.isRamadanActive() {
                    Text("branch.ramadan_hours")
                        .font(.caption.bold())
                        .foregroundStyle(.purple)
                }
                ForEach(hours.currentSchedule(), id: \.day) { d in
                    HStack {
                        Text(LocalizedStringKey(d.day.labelKey))
                            .font(.caption)
                            .frame(width: 60, alignment: .leading)
                        Spacer()
                        if d.isOpen, let o = d.opensAt, let c = d.closesAt {
                            Text(verbatim: "\(o) – \(c)")
                                .font(.caption.monospacedDigit())
                                .environment(\.layoutDirection, .leftToRight)
                        } else {
                            Text("branch.closed_now").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                let upcoming = hours.holidayClosures
                    .filter { $0 >= Date() && $0 <= Date().addingTimeInterval(60 * 24 * 3600) }
                if !upcoming.isEmpty {
                    Divider().padding(.vertical, 4)
                    Text("branch.holiday_closures").font(.caption.bold())
                    ForEach(upcoming, id: \.self) { d in
                        Text(d, style: .date).font(.caption2).foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
            }
        }
    }

    // MARK: 6. Facility tour

    private func facilityTour(store: BranchProfileStore) -> some View {
        sectionCard(icon: "building.2.fill", title: "branch.facility") {
            VStack(alignment: .leading, spacing: 10) {
                if let f = store.facility, !f.photoURLs.isEmpty {
                    TabView {
                        ForEach(f.photoURLs, id: \.self) { url in
                            AsyncImage(url: URL(string: url)) { phase in
                                switch phase {
                                case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                                default: Color.secondary.opacity(0.2)
                                }
                            }
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .frame(height: 200)
                    #if os(iOS)
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    #endif
                }
                if let f = store.facility {
                    facilitySpecGrid(facility: f)
                }
            }
        }
    }

    private func facilitySpecGrid(facility: BranchFacility) -> some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 8) {
            facilityChip(icon: "square.stack.3d.up.fill",
                         label: "facility.floor_area",
                         value: "\(Int(facility.floorAreaSqm)) m²")
            facilityChip(icon: "rectangle.split.3x1.fill",
                         label: "facility.halls",
                         value: "\(facility.hallCount)")
            facilityChip(icon: "checkerboard.shield",
                         label: "facility.pss",
                         value: facility.hasPSS ? (facility.pssBrand ?? "✓") : "—")
            facilityChip(icon: "tv",
                         label: "facility.scoreboard",
                         value: facility.hasInstalledScoreboard ? "✓" : "—")
            facilityChip(icon: "person.2.fill",
                         label: "facility.changing_rooms",
                         value: "M\(facility.changingRoomsM)·F\(facility.changingRoomsF)")
            facilityChip(icon: "chair.lounge.fill",
                         label: "facility.spectator_seats",
                         value: "\(facility.spectatorSeats)")
            facilityChip(icon: "car.fill",
                         label: "facility.parking",
                         value: "\(facility.parkingSpots)")
            facilityChip(icon: "moon.stars.fill",
                         label: "facility.prayer_room",
                         value: facility.hasPrayerRoom ? "✓" : "—")
        }
    }

    private func facilityChip(icon: String, label: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(.tint).frame(width: 18)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.caption2).foregroundStyle(.secondary)
                Text(verbatim: value).font(.caption.bold())
                    .environment(\.layoutDirection, .leftToRight)
            }
            Spacer()
        }
        .padding(8)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: 7. Pricing

    private func pricingSection(pricing: BranchPricing) -> some View {
        sectionCard(icon: "tag.fill", title: "branch.pricing") {
            VStack(alignment: .leading, spacing: 6) {
                priceRow(label: "program.monthly_fee", value: pricing.baseMonthlyFeeAED)
                priceRow(label: "program.trial_class", value: pricing.trialClassFeeAED)
                priceRow(label: "program.registration_fee", value: pricing.registrationFeeAED)
                priceRow(label: "program.equipment_package", value: pricing.equipmentPackageFeeAED)
                if pricing.siblingDiscountPct > 0 {
                    Text(verbatim: String(format: NSLocalizedString("program.sibling_discount", comment: ""),
                                          Int(pricing.siblingDiscountPct * 100)))
                        .font(.caption).foregroundStyle(.secondary)
                }
                if pricing.annualPrepayDiscountPct > 0 {
                    Text(verbatim: String(format: NSLocalizedString("program.annual_prepay", comment: ""),
                                          Int(pricing.annualPrepayDiscountPct * 100)))
                        .font(.caption).foregroundStyle(.secondary)
                }
                if !pricing.promotions.isEmpty {
                    Button {
                        showingPromotions = true
                    } label: {
                        Label("branch.see_promotions", systemImage: "ticket.fill").font(.caption.bold())
                    }
                    .padding(.top, 4)
                    .sheet(isPresented: $showingPromotions) {
                        PromotionsSheet(promotions: pricing.promotions)
                    }
                }
            }
        }
    }

    private func priceRow(label: LocalizedStringKey, value: Double) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(verbatim: "AED \(Int(value))")
                .font(.callout.bold().monospacedDigit())
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    // MARK: 8. Coaches

    private func coachesSection(coaches: [Coach]) -> some View {
        sectionCard(icon: "figure.taekwondo", title: "branch.coaches") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(coaches) { c in
                        NavigationLink(destination: CoachDetailView(coach: c)) {
                            VStack(spacing: 6) {
                                Avatar(seed: c.avatarSeed, label: c.initials, size: 56)
                                Text(verbatim: c.fullName)
                                    .font(.caption.bold())
                                    .lineLimit(1)
                                Text(verbatim: "\(c.danRank) Dan")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .environment(\.layoutDirection, .leftToRight)
                            }
                            .frame(width: 96)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: 9. Achievements

    private func achievementsSection(milestones: [BranchMilestone]) -> some View {
        sectionCard(icon: "rosette", title: "branch.achievements") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(milestones.prefix(5)) { m in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: milestoneIcon(m.category))
                            .foregroundStyle(.tint)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: m.titleEn).font(.caption.bold())
                            Text(m.occurredAt, style: .date)
                                .font(.caption2).foregroundStyle(.secondary)
                                .environment(\.layoutDirection, .leftToRight)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private func milestoneIcon(_ c: MilestoneCategory) -> String {
        switch c {
        case .founded: return "flag.fill"
        case .championshipWon: return "trophy.fill"
        case .alumniAchievement: return "star.fill"
        case .renovation: return "hammer.fill"
        case .staffMilestone: return "person.crop.rectangle.fill"
        case .recordSet: return "chart.line.uptrend.xyaxis"
        case .partnership: return "link"
        }
    }

    // MARK: 10. Connect

    private func connectSection(links: BranchSocialLinks, branch: Branch) -> some View {
        sectionCard(icon: "link", title: "branch.connect") {
            HStack(spacing: 12) {
                socialIcon("envelope.fill", url: branch.email.isEmpty ? nil : "mailto:\(branch.email)")
                socialIcon("link", url: links.websiteURL)
                socialIcon("camera.fill", url: links.instagramHandle.map { "https://instagram.com/\($0.replacingOccurrences(of: "@", with: ""))" })
                socialIcon("music.note", url: links.tiktokHandle.map { "https://tiktok.com/\($0)" })
                socialIcon("play.rectangle.fill", url: links.youtubeChannelURL)
                socialIcon("paperplane.fill", url: links.telegramChannelLink)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func socialIcon(_ system: String, url: String?) -> some View {
        if let url, let parsed = URL(string: url) {
            Button {
                openURL(parsed)
            } label: {
                Image(systemName: system)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 36, height: 36)
                    .background(Color(.tertiarySystemGroupedBackground), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: 11. Visit

    private func visitSection(branch: Branch) -> some View {
        sectionCard(icon: "mappin.and.ellipse", title: "branch.visit") {
            VStack(alignment: .leading, spacing: 8) {
                if branch.latitude != 0 || branch.longitude != 0 {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: branch.latitude, longitude: branch.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))) {
                        Marker(branch.name, coordinate: CLLocationCoordinate2D(latitude: branch.latitude, longitude: branch.longitude))
                    }
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Text(verbatim: branch.streetAddress).font(.caption)
                if !branch.streetAddressAr.isEmpty {
                    Text(verbatim: branch.streetAddressAr).font(.caption).foregroundStyle(.secondary)
                }
                Button {
                    openInMaps(branch: branch)
                } label: {
                    Label("branch.directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Helpers

    private func sectionCard<Content: View>(
        icon: String, title: LocalizedStringKey,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 6))
                Text(title).font(.subheadline.bold())
                Spacer()
            }
            content()
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(label: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(verbatim: value).font(.caption)
                .multilineTextAlignment(.trailing).lineLimit(2)
        }
    }

    private func brandColor(_ branch: Branch) -> Color {
        if let hex = branch.brandHexColor { return Color(hex: hex) }
        return .accentColor
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }

    private func openInMaps(branch: Branch) {
        let lat = branch.latitude
        let lon = branch.longitude
        guard lat != 0 || lon != 0 else { return }
        let urlStr = "https://maps.apple.com/?ll=\(lat),\(lon)&q=\(branch.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: urlStr) { openURL(url) }
    }

    @Environment(\.openURL) private var openURL
}

private struct ProgramCard: View {
    let program: BranchProgram

    var body: some View {
        let title = program.customName ?? program.nameKey ?? ""
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: title).font(.callout.bold()).lineLimit(2)
            HStack(spacing: 4) {
                Image(systemName: "person.fill").font(.caption2).foregroundStyle(.secondary)
                Text(LocalizedStringKey(program.ageGroup.labelKey)).font(.caption2).foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                Image(systemName: "calendar").font(.caption2).foregroundStyle(.secondary)
                Text(verbatim: scheduleSummary(program: program))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Spacer(minLength: 4)
            Text(verbatim: "AED \(Int(program.monthlyFeeAED)) / mo")
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(.tint)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(10)
        .frame(width: 180, height: 120, alignment: .topLeading)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private func scheduleSummary(program: BranchProgram) -> String {
        let days = program.schedulePattern.map { dayShort($0) }.joined(separator: " ")
        return "\(days)  \(program.startTime)–\(program.endTime)"
    }

    private func dayShort(_ d: DayOfWeek) -> String {
        switch d {
        case .sun: return "Sun"
        case .mon: return "Mon"
        case .tue: return "Tue"
        case .wed: return "Wed"
        case .thu: return "Thu"
        case .fri: return "Fri"
        case .sat: return "Sat"
        }
    }
}

private struct PromotionsSheet: View {
    let promotions: [Promotion]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(promotions) { p in
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: p.titleEn).font(.headline)
                    Text(verbatim: p.descriptionEn).font(.callout)
                    HStack {
                        if let pct = p.discountPct {
                            Text(verbatim: "\(Int(pct * 100))%").font(.caption.bold())
                                .foregroundStyle(.tint)
                                .environment(\.layoutDirection, .leftToRight)
                        } else if let aed = p.discountAED {
                            Text(verbatim: "AED \(Int(aed))").font(.caption.bold())
                                .foregroundStyle(.tint)
                                .environment(\.layoutDirection, .leftToRight)
                        }
                        Spacer()
                        if let code = p.promoCode {
                            Text(verbatim: code)
                                .font(.caption.monospaced())
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15), in: Capsule())
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle(Text("branch.see_promotions"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.ok") { dismiss() }
                }
            }
        }
    }
}


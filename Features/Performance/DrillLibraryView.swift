import SwiftUI

// MARK: - Drill Library
//
// Stage 1.8 — premium remodel. Adaptive two-panel layout: a drill list panel
// and a drill detail panel side-by-side on iPad, list-only with a pushed
// detail screen on iPhone. The sidebar is provided by `AdaptiveNavigationShell`.

public struct DrillLibraryView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var hSize

    @Binding private var isLibrary: Bool

    @State private var drills: [DrillLibraryEntry] = []
    @State private var loading = true
    @State private var categoryFilter: DrillCategory?
    @State private var difficultyFilter: DrillDifficulty?
    @State private var searchText = ""
    @State private var sort: DrillSort = .recentlyAdded
    @State private var selectedID: EntityID?
    @State private var page = 0
    @State private var editing: DrillLibraryEntry?
    @State private var showingEditor = false

    @State private var rowsPerPage = 10

    public init(isLibrary: Binding<Bool> = .constant(true)) {
        _isLibrary = isLibrary
    }

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        VStack(spacing: 0) {
            DrillLibraryHeader(
                isLibrary: $isLibrary,
                searchText: $searchText,
                canCreate: canEdit,
                isWide: isWide,
                onCreate: { editing = nil; showingEditor = true }
            )
            DrillCategoryPills(
                category: $categoryFilter,
                difficulty: $difficultyFilter
            )
            content
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task { await load() }
        .onChange(of: searchText) { _, _ in page = 0 }
        .onChange(of: categoryFilter) { _, _ in page = 0 }
        .onChange(of: difficultyFilter) { _, _ in page = 0 }
        .onChange(of: rowsPerPage) { _, _ in page = 0 }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                DrillEditorSheet(
                    initial: editing,
                    onSave: { drill in Task { await save(drill) } },
                    onDelete: editing.map { existing in
                        { Task { await delete(id: existing.id) } }
                    }
                )
            }
        }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if loading {
            Spacer(); ProgressView(); Spacer()
        } else {
            // The list+detail split is shown only on a wide landscape canvas;
            // iPhone and iPad-portrait drop the panel and push a detail screen.
            GeometryReader { _ in
                let split = usesSplitDetailLayout()
                if split {
                    GeometryReader { geo in
                        let gap: CGFloat = 16
                        let w = max(0, geo.size.width - gap)
                        HStack(alignment: .top, spacing: gap) {
                            listPanel(split: true).frame(width: w * 0.5)
                            detailColumn.frame(width: w * 0.5)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                } else {
                    listPanel(split: false)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 14)
                }
            }
        }
    }

    // MARK: List panel

    private func listPanel(split: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(verbatim: String(format: NSLocalizedString("drill.count.fmt", comment: ""),
                                      filtered.count))
                    .scaledFont(.subheadline, weight: .semibold)
                Spacer(minLength: 8)
                sortMenu
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            Divider().opacity(0.5)

            if filtered.isEmpty {
                EmptyStateCard(
                    icon: "magnifyingglass",
                    titleKey: searchText.isEmpty ? "drill_library.empty" : "drill_library.empty_search",
                    messageKey: "drill.empty.hint"
                )
                .padding(16)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(pageSlice) { drill in
                            drillRow(drill, split: split)
                        }
                    }
                    .padding(12)
                }
                // Footer — rows-per-page picker + pager, matching every
                // other list module.
                Divider().opacity(0.5)
                HStack(spacing: 10) {
                    RowsPerPageMenu(rowsPerPage: $rowsPerPage)
                    Spacer(minLength: 8)
                    if pageCount > 1 {
                        DrillPager(page: $page, pageCount: pageCount)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
            }
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }

    @ViewBuilder
    private func drillRow(_ drill: DrillLibraryEntry, split: Bool) -> some View {
        if split {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { selectedID = drill.id }
            } label: {
                DrillListRow(drill: drill,
                             selected: selectedID == drill.id,
                             canEdit: canEdit,
                             onEdit: { editing = drill; showingEditor = true },
                             onDelete: { Task { await delete(id: drill.id) } })
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                DrillDetailScreen(drill: drill,
                                  related: related(for: drill),
                                  canEdit: canEdit,
                                  onEdit: { editing = drill; showingEditor = true })
            } label: {
                DrillListRow(drill: drill,
                             selected: false,
                             canEdit: canEdit,
                             onEdit: { editing = drill; showingEditor = true },
                             onDelete: { Task { await delete(id: drill.id) } })
            }
            .buttonStyle(.plain)
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(DrillSort.allCases) { option in
                Button {
                    sort = option
                    page = 0
                } label: {
                    if sort == option {
                        Label { Text(localizedKey: option.titleKey) }
                        icon: { Image(systemName: "checkmark") }
                    } else {
                        Text(localizedKey: option.titleKey)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text("drill.sort_by").scaledFont(.caption).foregroundStyle(.secondary)
                Text(localizedKey: sort.titleKey)
                    .scaledFont(.caption, weight: .semibold)
                Image(systemName: "chevron.down")
                    .scaledFont(.caption2, weight: .semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
    }

    // MARK: Detail column

    @ViewBuilder
    private var detailColumn: some View {
        if let drill = selectedDrill {
            DrillDetailPanel(
                drill: drill,
                related: related(for: drill),
                canEdit: canEdit,
                onEdit: { editing = drill; showingEditor = true },
                onStartTimer: { isLibrary = false },
                onSelectRelated: { r in
                    withAnimation(.easeInOut(duration: 0.2)) { selectedID = r.id }
                }
            )
        } else {
            VStack(spacing: 12) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 38))
                    .foregroundStyle(.tertiary)
                Text("drill.detail.empty")
                    .scaledFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 320)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
            )
        }
    }

    // MARK: Data

    private var filtered: [DrillLibraryEntry] {
        var out = drills
        if let cat = categoryFilter { out = out.filter { $0.category == cat } }
        if let diff = difficultyFilter { out = out.filter { $0.difficulty == diff } }
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            out = out.filter {
                $0.name.lowercased().contains(q)
                    || $0.summary.lowercased().contains(q)
                    || $0.tags.contains { $0.lowercased().contains(q) }
            }
        }
        switch sort {
        case .recentlyAdded: break
        case .name:          out.sort { $0.name < $1.name }
        case .duration:      out.sort { ($0.durationMinutes ?? 0) < ($1.durationMinutes ?? 0) }
        case .difficulty:    out.sort { ($0.difficulty?.order ?? 0) < ($1.difficulty?.order ?? 0) }
        }
        return out
    }

    private var pageCount: Int {
        max(1, Int(ceil(Double(filtered.count) / Double(rowsPerPage))))
    }

    private var pageSlice: [DrillLibraryEntry] {
        let all = filtered
        guard !all.isEmpty else { return [] }
        let safePage = min(page, pageCount - 1)
        let start = safePage * rowsPerPage
        return Array(all[start..<min(start + rowsPerPage, all.count)])
    }

    private var selectedDrill: DrillLibraryEntry? {
        guard let id = selectedID else { return nil }
        return drills.first { $0.id == id }
    }

    private func related(for drill: DrillLibraryEntry) -> [DrillLibraryEntry] {
        let explicit = drill.relatedDrillIDs.compactMap { id in drills.first { $0.id == id } }
        if !explicit.isEmpty { return explicit }
        // Fall back to same-category drills so the tab is never empty.
        return drills.filter { $0.category == drill.category && $0.id != drill.id }.prefix(4).map { $0 }
    }

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editAthlete)
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            drills = try await session.repository.drills()
            if selectedID == nil, isWide { selectedID = drills.first?.id }
        } catch {
            print("DrillLibraryView.load:", error)
        }
    }

    private func save(_ drill: DrillLibraryEntry) async {
        do {
            try await session.repository.upsert(drill: drill)
            await load()
            selectedID = drill.id
        } catch {
            print("DrillLibraryView.save:", error)
        }
    }

    private func delete(id: EntityID) async {
        do {
            try await session.repository.deleteDrill(id: id)
            if selectedID == id { selectedID = nil }
            await load()
        } catch {
            print("DrillLibraryView.delete:", error)
        }
    }
}

// MARK: - Sort

enum DrillSort: String, CaseIterable, Identifiable, Hashable {
    case recentlyAdded, name, duration, difficulty
    var id: String { rawValue }
    var titleKey: String { "drill.sort.\(rawValue)" }
}

private extension DrillDifficulty {
    var order: Int {
        switch self {
        case .beginner: 0
        case .intermediate: 1
        case .advanced: 2
        }
    }
}

// MARK: - Header

struct DrillLibraryHeader: View {
    @Binding var isLibrary: Bool
    @Binding var searchText: String
    let canCreate: Bool
    let isWide: Bool
    let onCreate: () -> Void

    var body: some View {
        Group {
            if isWide {
                HStack(alignment: .center, spacing: 16) {
                    titleBlock
                    Spacer(minLength: 8)
                    DrillModeSwitcher(isLibrary: $isLibrary)
                    Spacer(minLength: 8)
                    searchField.frame(maxWidth: 240)
                    if canCreate { newDrillButton }
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        titleBlock
                        Spacer(minLength: 8)
                        if canCreate { newDrillButton }
                    }
                    DrillModeSwitcher(isLibrary: $isLibrary)
                    searchField
                }
            }
        }
        .padding(.horizontal, isWide ? 18 : 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("drill_library.title").scaledFont(.title2, weight: .bold)
            Text("drill_library.subtitle")
                .scaledFont(.caption).foregroundStyle(.secondary)
        }
    }

    private var searchField: some View {
        SearchDrillsField(text: $searchText)
    }

    private var newDrillButton: some View {
        PrimaryActionButton(titleKey: "drill_library.add", systemIcon: "plus", action: onCreate)
    }
}

/// Rounded glass-material search field with a magnifier and clear button.
struct SearchDrillsField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .scaledFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
            TextField(text: $text) { Text("drill.search") }
                .textFieldStyle(.plain)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .scaledFont(.footnote)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.secondary.opacity(0.14), lineWidth: 1))
    }
}

// MARK: - Category pills

struct DrillCategoryPills: View {
    @Binding var category: DrillCategory?
    @Binding var difficulty: DrillDifficulty?

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    pill(titleKey: "filter.all", icon: nil,
                         tint: .accentColor, on: category == nil) { category = nil }
                    ForEach(DrillCategory.allCases, id: \.self) { cat in
                        pill(titleKey: cat.labelKey, icon: cat.systemIcon,
                             tint: cat.tint, on: category == cat) {
                            category = (category == cat) ? nil : cat
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            filtersMenu
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    private func pill(titleKey: String, icon: String?, tint: Color,
                      on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) { action() }
        } label: {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon).scaledFont(.caption2, weight: .semibold)
                }
                Text(localizedKey: titleKey).scaledFont(.caption, weight: .semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(on ? Color.white : Color.primary)
            .background(
                Capsule().fill(on ? Color.accentColor : tint.opacity(0.12))
            )
            .shadow(color: on ? Color.accentColor.opacity(0.3) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var filtersMenu: some View {
        Menu {
            Picker("drill.filter.level", selection: $difficulty) {
                Text("filter.all").tag(DrillDifficulty?.none)
                ForEach(DrillDifficulty.allCases, id: \.self) { d in
                    Text(localizedKey: d.labelKey).tag(DrillDifficulty?.some(d))
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "line.3.horizontal.decrease")
                    .scaledFont(.caption2, weight: .semibold)
                Text("drill.filters").scaledFont(.caption, weight: .semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(difficulty == nil ? Color.primary : Color.accentColor)
            .background(
                Capsule().fill(difficulty == nil
                               ? Color.secondary.opacity(0.10)
                               : Color.accentColor.opacity(0.14))
            )
        }
        .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
    }
}

// MARK: - Pager

struct DrillPager: View {
    @Binding var page: Int
    let pageCount: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<min(pageCount, 6), id: \.self) { i in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { page = i }
                } label: {
                    Text(verbatim: "\(i + 1)")
                        .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                        .frame(width: 30, height: 30)
                        .foregroundStyle(page == i ? Color.white : Color.primary)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(page == i ? Color.accentColor : Color.secondary.opacity(0.10))
                        )
                }
                .buttonStyle(.plain)
            }
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    page = min(page + 1, pageCount - 1)
                }
            } label: {
                Text("drill.pager.next")
                    .scaledFont(.caption, weight: .semibold)
                    .padding(.horizontal, 12).frame(height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(page + 1 >= pageCount)
            .opacity(page + 1 >= pageCount ? 0.4 : 1)
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

// MARK: - iPhone detail screen

struct DrillDetailScreen: View {
    let drill: DrillLibraryEntry
    let related: [DrillLibraryEntry]
    let canEdit: Bool
    let onEdit: () -> Void

    var body: some View {
        ScrollView {
            DrillDetailPanel(
                drill: drill,
                related: related,
                canEdit: canEdit,
                onEdit: onEdit,
                onStartTimer: {},
                onSelectRelated: { _ in }
            )
            .padding(14)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(Text(verbatim: drill.name))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Editor sheet

struct DrillEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let initial: DrillLibraryEntry?
    let onSave: (DrillLibraryEntry) -> Void
    let onDelete: (() -> Void)?

    @State private var name: String
    @State private var nameAr: String
    @State private var category: DrillCategory
    @State private var summary: String
    @State private var hasDuration: Bool
    @State private var durationMinutes: Int
    @State private var hasDifficulty: Bool
    @State private var difficulty: DrillDifficulty
    @State private var hasMinBelt: Bool
    @State private var minBeltKind: BeltKind
    @State private var minBeltNumber: Int
    @State private var hasMaxBelt: Bool
    @State private var maxBeltKind: BeltKind
    @State private var maxBeltNumber: Int
    @State private var weaknessTagsText: String
    @State private var equipmentText: String
    @State private var videoURL: String
    @State private var tagsText: String
    @State private var hasIntensity: Bool
    @State private var intensity: Int
    @State private var instructionsText: String
    @State private var coachingTip: String
    @State private var muscleFocusText: String
    @State private var notes: String

    init(
        initial: DrillLibraryEntry?,
        onSave: @escaping (DrillLibraryEntry) -> Void,
        onDelete: (() -> Void)?
    ) {
        self.initial = initial
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: initial?.name ?? "")
        _nameAr = State(initialValue: initial?.nameAr ?? "")
        _category = State(initialValue: initial?.category ?? .technique)
        _summary = State(initialValue: initial?.summary ?? "")
        _hasDuration = State(initialValue: initial?.durationMinutes != nil)
        _durationMinutes = State(initialValue: initial?.durationMinutes ?? 10)
        _hasDifficulty = State(initialValue: initial?.difficulty != nil)
        _difficulty = State(initialValue: initial?.difficulty ?? .intermediate)
        _hasMinBelt = State(initialValue: initial?.minBelt != nil)
        _minBeltKind = State(initialValue: initial?.minBelt?.kind ?? .gup)
        _minBeltNumber = State(initialValue: initial?.minBelt?.number ?? 8)
        _hasMaxBelt = State(initialValue: initial?.maxBelt != nil)
        _maxBeltKind = State(initialValue: initial?.maxBelt?.kind ?? .dan)
        _maxBeltNumber = State(initialValue: initial?.maxBelt?.number ?? 9)
        _weaknessTagsText = State(initialValue: (initial?.addressesWeaknessTags ?? []).joined(separator: ", "))
        _equipmentText = State(initialValue: (initial?.equipment ?? []).map(\.name).joined(separator: ", "))
        _videoURL = State(initialValue: initial?.videoURL ?? "")
        _tagsText = State(initialValue: (initial?.tags ?? []).joined(separator: ", "))
        _hasIntensity = State(initialValue: initial?.intensity != nil)
        _intensity = State(initialValue: initial?.intensity ?? 3)
        _instructionsText = State(initialValue: (initial?.instructions ?? []).joined(separator: "\n"))
        _coachingTip = State(initialValue: initial?.coachingTip ?? "")
        _muscleFocusText = State(initialValue: (initial?.muscleFocus ?? []).joined(separator: ", "))
        _notes = State(initialValue: initial?.notes ?? "")
    }

    var body: some View {
        Form {
            Section {
                TextField("drill.name", text: $name)
                TextField("drill.name_ar", text: $nameAr)
                Picker("drill.category", selection: $category) {
                    ForEach(DrillCategory.allCases, id: \.self) { c in
                        Label {
                            Text(localizedKey: c.labelKey)
                        } icon: {
                            Image(systemName: c.systemIcon)
                        }
                        .tag(c)
                    }
                }
            }

            Section {
                TextField("drill.summary", text: $summary, axis: .vertical)
                    .lineLimit(2...6)
            } header: {
                Text("drill.summary")
            }

            Section {
                Toggle("drill.has_duration", isOn: $hasDuration)
                if hasDuration {
                    Stepper(value: $durationMinutes, in: 1...120, step: 1) {
                        HStack {
                            Text("drill.duration")
                            Spacer()
                            Text(verbatim: "\(durationMinutes) min")
                                .foregroundStyle(.secondary)
                                .environment(\.layoutDirection, .leftToRight)
                        }
                    }
                }
                Toggle("drill.has_difficulty", isOn: $hasDifficulty)
                if hasDifficulty {
                    Picker("drill.difficulty", selection: $difficulty) {
                        ForEach(DrillDifficulty.allCases, id: \.self) { d in
                            Text(localizedKey: d.labelKey).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Toggle("drill.has_intensity", isOn: $hasIntensity)
                if hasIntensity {
                    Stepper(value: $intensity, in: 1...5) {
                        HStack {
                            Text("drill.meta.intensity")
                            Spacer()
                            IntensityDots(level: intensity)
                        }
                    }
                }
            }

            Section {
                Toggle("drill.has_min_belt", isOn: $hasMinBelt)
                if hasMinBelt {
                    beltPicker(kind: $minBeltKind, number: $minBeltNumber)
                }
                Toggle("drill.has_max_belt", isOn: $hasMaxBelt)
                if hasMaxBelt {
                    beltPicker(kind: $maxBeltKind, number: $maxBeltNumber)
                }
            } header: {
                Text("drill.belt_range")
            }

            Section {
                TextField("drill.instructions", text: $instructionsText, axis: .vertical)
                    .lineLimit(3...10)
            } header: {
                Text("drill.section.how_to")
            } footer: {
                Text("drill.instructions_help").scaledFont(.caption2).foregroundStyle(.secondary)
            }

            Section {
                TextField("drill.coaching_tip", text: $coachingTip, axis: .vertical)
                    .lineLimit(1...4)
            } header: {
                Text("drill.coaching_tip")
            }

            Section {
                TextField("drill.tags", text: $tagsText, axis: .vertical)
                    .lineLimit(1...3)
                TextField("drill.muscle_focus", text: $muscleFocusText, axis: .vertical)
                    .lineLimit(1...3)
                TextField("drill.weakness_tags", text: $weaknessTagsText, axis: .vertical)
                    .lineLimit(1...3)
            } header: {
                Text("drill.tags")
            } footer: {
                Text("drill.weakness_tags_help").scaledFont(.caption2).foregroundStyle(.secondary)
            }

            Section {
                TextField("drill.equipment", text: $equipmentText, axis: .vertical)
                    .lineLimit(1...3)
            } header: {
                Text("drill.equipment")
            } footer: {
                Text("drill.equipment_help").scaledFont(.caption2).foregroundStyle(.secondary)
            }

            Section {
                TextField("drill.tab.notes", text: $notes, axis: .vertical)
                    .lineLimit(2...6)
            } header: {
                Text("drill.tab.notes")
            }

            Section {
                TextField("technique.video_url", text: $videoURL)
                    #if os(iOS)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif
            } header: {
                Text("technique.video_url")
            }

            if let onDelete {
                Section {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label("action.delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle(Text(initial == nil ? "drill_library.add" : "drill_library.edit"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("action.save") { commit() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func beltPicker(kind: Binding<BeltKind>, number: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            Picker("", selection: kind) {
                ForEach(BeltKind.allCases, id: \.self) { k in
                    Text(localizedKey: k.labelKey).tag(k)
                }
            }
            .pickerStyle(.segmented)
            CompactStepper(value: number, range: range(for: kind.wrappedValue))
                .frame(maxWidth: 130)
        }
    }

    private func range(for kind: BeltKind) -> ClosedRange<Int> {
        switch kind {
        case .gup: 1...10
        case .poom: 1...4
        case .dan: 1...9
        }
    }

    private func parseList(_ raw: String) -> [String] {
        raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func parseLines(_ raw: String) -> [String] {
        raw.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func commit() {
        let trimmedURL = videoURL.trimmingCharacters(in: .whitespaces)
        let trimmedTip = coachingTip.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let equipmentItems = parseList(equipmentText).map { DrillEquipmentItem(name: $0) }
        let drill = DrillLibraryEntry(
            id: initial?.id ?? UUID(),
            name: name,
            nameAr: nameAr.isEmpty ? nil : nameAr,
            category: category,
            summary: summary,
            videoURL: trimmedURL.isEmpty ? nil : trimmedURL,
            durationMinutes: hasDuration ? durationMinutes : nil,
            addressesWeaknessTags: parseList(weaknessTagsText),
            minBelt: hasMinBelt ? BeltRank(kind: minBeltKind, number: clamped(minBeltNumber, kind: minBeltKind)) : nil,
            maxBelt: hasMaxBelt ? BeltRank(kind: maxBeltKind, number: clamped(maxBeltNumber, kind: maxBeltKind)) : nil,
            equipmentRequired: parseList(equipmentText),
            difficulty: hasDifficulty ? difficulty : nil,
            tags: parseList(tagsText),
            intensity: hasIntensity ? intensity : nil,
            instructions: parseLines(instructionsText),
            coachingTip: trimmedTip.isEmpty ? nil : trimmedTip,
            equipment: equipmentItems,
            muscleFocus: parseList(muscleFocusText),
            metrics: initial?.metrics,
            variations: initial?.variations ?? [],
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            relatedDrillIDs: initial?.relatedDrillIDs ?? [],
            imageAssetName: initial?.imageAssetName,
            videoDurationSeconds: initial?.videoDurationSeconds
        )
        onSave(drill)
        dismiss()
    }

    private func clamped(_ n: Int, kind: BeltKind) -> Int {
        let r = range(for: kind)
        return min(max(n, r.lowerBound), r.upperBound)
    }
}

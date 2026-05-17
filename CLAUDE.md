# CLAUDE.md — SHJSDSC Taekwondo

## Stack
- SwiftUI · iOS 17+ · macOS 14+ · Swift 5.9+
- Bilingual EN/AR with full RTL support
- No SwiftData. Models are pure `Codable` structs (Android-portable).
- Repository pattern: `DemoRepository` (actor, in-memory) → `SupabaseRepository` later.
- No third-party deps until Stage 5 (Supabase swap). No SPM packages added otherwise.

## Layered architecture
Core/Models       → pure data, no framework imports (SwiftUI/UIKit/AppKit forbidden)
Core/Repository   → protocol + actor-backed Demo + Supabase stub
Core/Services     → pure functions (ScoreEngine, GradingEngine, BracketEngine)
Core/Stores       → @Observable @MainActor view-facing state
Features/<Domain> → SwiftUI views, one feature per folder
Roles/            → one TabView per role, routed by RoleRouter
App/              → SHJSDSCApp, AppSession, RoleRouter
Resources/        → Localizable.xcstrings, assets

## Hard rules
- **Logic layer (`Core/`) MUST NOT import SwiftUI / UIKit / AppKit.** This is
  what makes Android port mechanical. Run `grep -r "import SwiftUI" Core/`
  before every commit — must return empty.
- One type per file. Filename matches primary type.
- `public` on every type/method that crosses a folder boundary (preparing for
  SPM modularisation).
- No force-unwraps. No `try!`. Use `try?` in views, `try await` in repos.
- `@MainActor` on stores. Repositories are `Sendable` actors.
- Dates: `Date()`, never strings. Format at the view layer only.
- IDs: `UUID` aliased as `EntityID = UUID`.
- Every user-facing string goes in `Localizable.xcstrings`. Hardcoded English
  string literals in views are forbidden — use `String(localized: "key")` or
  the `Text("key")` shorthand which auto-localises.

## RTL & Arabic rules
- Use `HStack` / `VStack` / `LazyVGrid` — these auto-mirror under RTL.
- Never hardcode `.leading` / `.trailing` paddings. Use `.padding(.horizontal, n)`.
- For directional icons (back arrow, chevron), use SF Symbols ending in
  `.rtl` variant or rely on the `.flipsForRightToLeftLayoutDirection()` modifier.
- Numbers stay LTR even in Arabic UI: wrap any number-heavy line in
  `.environment(\.layoutDirection, .leftToRight)` if it visually breaks.
- Test every screen by toggling Settings → SHJSDSC → Language → Arabic
  AND by adding scheme launch arg `-AppleLanguages (ar)` for fast iteration.
- Arabic strings in seed data: keep them Unicode (`\u{...}` not required, just
  paste). Use `fullNameAr`, `nameAr` etc. fields on every model.

## Conventions
- Folder structure stays flat — no deep nesting. Max 2 levels under `Features/`.
- Stores own state slices and expose async actions. Views never call
  `repository` directly except for read-once detail loads.
- `@Environment(AppSession.self)` is the only global. No singletons.
- Errors logged via `print("context:", error)` for now. Replace with a logger
  in Stage 4.
- Animations: 0.2s default, ease-in-out. No spring physics unless playful.
- Never use Apple-only API in `Core/`. `#if os(iOS)` / `#if os(macOS)` allowed
  in `Features/` and `Roles/` only.

## Demo data
- `SeedData.build()` produces realistic SSDSC content: 4 branches (Al Rahmania
  [main], Al Nasserya, Industrial 18, Al Nouf), 5 coaches with real names from public
  sources, 18 athletes with Emirati names, sessions for today + 2 days,
  performance scores per athlete, recent UAE Junior Open results.
- Demo role switcher in every home view's toolbar — no auth in demo build.
- All seeded names have both English and Arabic forms.

## Workflow per stage
1. Read this file first.
2. Read previous stage's commit log: `git log --oneline | head -10`.
3. Build the stage end-to-end before asking clarifying questions.
4. After each file written: `swift build` if SPM, or note Xcode-only.
5. Run `grep -r "import SwiftUI" Core/` — must be empty.
6. Run `grep -rn "Text(\"" Features/ Roles/ | grep -v "Text(\"key:"` — flag any
   hardcoded strings that aren't localisation keys.
7. Commit with `Stage N: <summary>`.

## Cross-platform port path (Stage 6)
- `Core/` ports to Kotlin: `struct` → `data class`, `protocol` → `interface`,
  `actor` → `Mutex`-guarded class, `async throws` → `suspend fun`,
  `@Observable` → `ViewModel + StateFlow`.
- See `ANDROID_PORT.md` for the mapping table.

## Design language (Stage 1.6 — Athlete redesign)
Premium, federation-grade visual system targeting an Apple-quality + Olympic
federation feel. Reference brief: `ATHLETE_REDESIGN.md`.

Tokens:
- **Surface**: `Color.cardBackground` (asset-catalogue auto-generated). Never pure white in dark mode.
- **Background**: `Color.appBackground` for screen, `Color.sidebarBackground` for chrome.
- **Hairline / divider**: `Color.secondary.opacity(0.12 … 0.18)`.
- **Soft shadow** (cards): `.shadow(color: .black.opacity(0.04), radius: 14, y: 6)`.
- **Corner radius**: 20 (hero), 16 (cards), 14 (note/tab strip), 10 (chips), 8 (status pills).
- **Accent**: blue via `Color.accentColor` — *use `Color.accentColor` for fills, `.tint` only for `ShapeStyle` slots*. `Color.tint` (Theme alias) survives but the bare member confuses SourceKit; prefer `accentColor` in new code.
- **Performance hues**: green for "good / ≥80%", `.accentColor` for "on track", orange for "behind", red for "critical".
- **Typography**: SF Pro (system). Stats: `.monospacedDigit()`. Numbers wrapped in `.environment(\.layoutDirection, .leftToRight)` to stay LTR under Arabic.

Design-system primitives live in `Features/Common/AthleteDesignSystem.swift`:
`SectionCard`, `ViewAllButton`, `IDChip`, `MetaChip`, `VerificationBadge`,
`CategoryBadge`, `ProgressRing`, `AthleteSummaryRow`, `TrainingStatRow`,
`RatingBarRow`, `RankingRow`, `AchievementMedalCard`, `UpcomingEventCard`,
`SegmentedTabBar`, `DocumentRow`, `CoachNoteCard`, `EmptyStateCard`. Reach
for these before inventing new card primitives.

Athlete profile module — file map:
- `AthleteDetailView` (container, data load, tab routing)
- `AthleteProfileHeader` (large hero, photo + bilingual name + IDs + status badges)
- `AthleteOverviewTab` (Athlete Summary, Progress ring, Training This Week,
  Latest Performance, Upcoming Event, Current Rankings, Recent Achievements)
- `AthletePerformanceTab` (composite trend + physical/technical/poomsae)
- `AthleteAttendanceTab` (KPI strip + 12-week heat grid + session list)
- `AthleteCompetitionsTab` (KPIs + table on iPad / cards on iPhone)
- `AthleteMedicalTab` (vitals + chip lists + injury log + weight history + consent)
- `AthleteDocumentsTab` (identity / medical / consent / federation sections)
- `AthleteCoachNotesTab` (filter chips + pinned-first feed + compose FAB)
- `AthleteMoreTab` (family, emergency contacts, belt progression, goals, plan)

Coach profile module — file map (visual twin of athlete module, reuses every
primitive from `AthleteDesignSystem.swift` — no new design tokens):
- `CoachDetailView` (container, data load, tab routing)
- `CoachProfileHeader` (mirrors athlete hero: photo + bilingual name + IDs +
  Head/National/Olympic badges)
- `CoachOverviewTab` (Coach Summary, Performance ring, Team Overview,
  Certifications, Upcoming Events, Rankings, Recent Achievements)
- `CoachAthletesTab` (roster filter chips + grid of assigned athletes)
- `CoachPerformanceTab` (win rate / improvement / promotion / satisfaction +
  per-discipline competency 1-5)
- `CoachAttendanceTab` (sessions-conducted KPI strip + 12-week heat grid + list)
- `CoachCompetitionsTab` (medal breakdown + tournaments-managed table)
- `CoachCertificationsTab` (completeness ring + expired/expiring/active
  sections + embedded compliance snapshot from Coach struct)
- `CoachReportsTab` (slot for the Reports module — empty state today)
- `CoachMoreTab` (contract + assigned branches + bio + peer notes)

Coach dossier additions live on `Coach` (federation IDs, identity, role,
status, competency, ranking, notes) — same embedded-Codable pattern as
Athlete. Cross-coach Certifications stay in the dedicated Repository surface
(`Certification`) — those have their own lifecycle.

Branch module — file map (reuses every primitive from `AthleteDesignSystem.swift`):
- `BranchesOverviewView` (top-level: hero gradient KPI card + main-branch
  dominant card + secondaries grid + analytics on iPad + upcoming events)
- `BranchHierarchyView` (iPad-only org-chart: main on top, 3 secondaries
  connected via elegant lines)
- `BranchCard` (premium card used in overview; `isDominant` flag enlarges
  the main branch)
- `BranchAnalyticsCards` (`BranchAthleteDistributionCard` donut +
  `BranchSessionsBarCard` + `BranchPerformanceTableCard`)
- `BranchProfileHeader` (banner: image/gradient + bilingual name + status +
  manager + key stat row)
- `BranchProfileView` rewritten as 7-tab operational console (Overview /
  Athletes / Coaches / Sessions / Competitions / Reports / More). Tab content
  is private nested views in the same file since they share `BranchProfileStore`
  state heavily and are leaner than the athlete/coach tabs.

Branch model gained `isMain: Bool` and `operationalStatus`
(active/maintenance/tournamentMode/closed). The Branches Overview pivots
around `isMain` — exactly one branch should be marked main; the main branch
gets dominant styling and is anchored to the top of the hierarchy.

## Stage 1.7 — Full app remodel

**Palette flip (asset catalogue).** Old green sidebar is gone. New tokens:
- `AccentColor` → Deep Royal Blue (`#1A4FCC` light / `#5E8AE6` dark)
- `SidebarBackground` → Layered neutral (`#F2F4F8` light / `#1A1D22` dark)
- `SidebarForeground` → Near-black / near-white (auto-inverts)
- `SecondaryAccent` (new) → Soft Emerald (`#10A26B` light / `#34D399` dark)
- `AppBackground` / `CardBackground` → unchanged

To swap accent again, edit `Assets.xcassets/AccentColor.colorset/Contents.json` only. SecondaryAccent is `Color.secondaryAccent` via asset-catalog codegen.

**Navigation chrome.** `AppNavigationChrome` now uses `.thinMaterial` instead of `Color.sidebarBackground`. The dark-color-scheme override is removed. iOS-only; macOS short-circuits.

**Nav shell.** `SidebarShell` is deprecated. New `AdaptiveNavigationShell` (`Features/Common/AdaptiveNavigationShell.swift`) — TabView on iPhone (4 primary tabs + overflow into "More"), `NavigationSplitView` with translucent floating sidebar on iPad. Same public API. Every role TabView (BranchManager / Admin / TechnicalDirector / Developer / Coach / Athlete / Parent) was migrated via single-line replace.

**Screens redesigned this stage:**
- `AnnouncementsView` — Apple News-style: filter chips, hero gradient card for the newest, grouped feed of rich cards, RSVP buttons styled per state
- `CertificationsListView` — compliance dashboard: health ring + active/expiring/expired counts, grouped sections, premium cert rows with kind icon and severity color
- `AuditLogView` — activity timeline grouped by day, severity stripe, user avatar, action verb, target chip, category filter
- `MoreView` (settings) — grouped premium cards: Account / Appearance / Notifications / Privacy & About / Developer (role-gated). No more bare Form.

The role home dashboards were remodelled to executive-grade in Stage 1.13 —
see that section.

iPad adaptation: each tab takes an `isWide` bool driven by `horizontalSizeClass == .regular`. Compact = single column; wide = multi-column grids with denser KPIs.

## Stage 1.8 — Drill Library remodel

Premium rebuild of the Drills experience — Apple-Fitness-for-coaches feel.
Adaptive **two-panel** layout: a drill list panel + a drill detail panel
side-by-side on iPad, list-only with a pushed detail screen on iPhone. The
sidebar is the shared `AdaptiveNavigationShell`. Reuses `AccentColor` /
`SecondaryAccent` and the Stage 1.6 card tokens — no new design tokens.

Drill module — file map (`Features/Performance/`):
- `DrillsAndTimerView` (router: owns `isLibrary`, routes to Library or
  `DrillTimerModeView`; the Timer/Library switch lives in each screen's header)
- `DrillLibraryView` (full library screen — header + category pills + list
  panel + detail column; hosts `DrillLibraryHeader`, `SearchDrillsField`,
  `DrillCategoryPills`, `DrillPager`, `DrillDetailScreen` iPhone push,
  `DrillEditorSheet`, `DrillSort`)
- `DrillDetailPanel` (header + metadata strip + 6 tabs — Overview / Steps /
  Equipment / Variations / Notes / Related; hosts `DrillMetadataCard`,
  `DrillInstructionStep`, `CoachingTipCard`, `DrillMetricsGrid` /
  `DrillMetricsCard`, `DrillPreviewPanel`, `DrillFlowLayout` / `FlowChips`)
- `DrillKit` (design tokens + shared chips: `DrillCategory.tint` /
  `DrillDifficulty.tint`, `DrillLevelBadge`, `DrillTagChip`, `EquipmentChip`,
  `MuscleFocusChip`, `IntensityDots`, `DrillThumbnail`, `PrimaryActionButton`,
  `DrillModeSwitcher`)

Drill Timer — file map (the from-scratch Timer mode, Stage 1.8):
- `DrillTimerView` (setup screen — tap-to-run presets + custom interval
  builder with athlete-group rotation; presents the run view full-screen)
- `DrillTimerRunView` (full-screen operational timer — phase-tinted canvas,
  giant countdown ring, round / group / drill context, transport controls)
- `DrillTimerKit` (`DrillTimerPhase.tint`, `CountdownRing`,
  `TimerControlButton`, `TimerPresetCard`, `TimerStepperRow`,
  `formatTimerClock`)
- `DrillTimerAudio` (`Features/Performance/` — system-sound + haptic cues;
  optional `timer_*` bundle assets override)
- `DrillTimerEngine` (`Core/Stores/`, `@Observable @MainActor` — flattens a
  `DrillTimerSession` into a `[Step]` timeline and walks it with a ticker)
- `DrillTimer` (`Core/Models/Training/` — `DrillTimerSession`,
  `DrillTimerInterval`, `DrillTimerPhase` + Tabata/Rounds/EMOM presets)

The Drill Timer is independent of the old `Pomodoro*` system, which stays —
`LiveClassView` still depends on it. Timer sessions are built fresh from a
preset or the builder each run (not persisted in Stage 1.8).

`DrillLibraryEntry` gained a **drill dossier** (Stage 1.8): `tags`,
`intensity` (1–5), `instructions`, `coachingTip`, `equipment`
(`DrillEquipmentItem`), `muscleFocus`, `metrics` (`DrillMetrics`),
`variations` (`DrillVariation`), `notes`, `relatedDrillIDs`, `imageAssetName`,
`videoDurationSeconds` — same embedded-Codable + backward-compatible-decoder
pattern as the athlete/coach dossiers. Supporting types live in
`Core/Models/DrillDossier.swift`. `DrillCategory` gained `.strength`.

Drill thumbnails / video previews load asset-catalogue images named
`drill_<slug>` (`imageAssetName` in `SeedData.swift`'s 32-drill catalogue);
`DrillThumbnail` checks the bundle and falls back to a category-tinted
gradient when an asset is absent, so the UI is never empty.

**Still deferred:** the sidebar user-footer card (avatar + name + role +
online dot in `AdaptiveNavigationShell`). Follow-up pass.

## Stage 1.9 — Announcements dashboard remodel

Premium rebuild of the Announcements module — an operations-console layout
(not the old Apple-News feed). Header + 5 summary stat tiles + status filter
pills + an adaptive two-panel workspace (announcement list + detail panel on
iPad, list with a pushed detail screen on iPhone). Reuses Stage 1.6 card
tokens — no new design tokens.

Announcements module — file map (`Features/Operations/`):
- `AnnouncementsView` (full screen — header + stat tiles + filter pills +
  list panel + detail column; pager footer + `AnnouncementDetailScreen`
  iPhone push)
- `AnnouncementDetailPanel` (`AnnouncementRow` + the detail panel: header,
  hero image, body, event meta, Audience + Delivery cards, Engagement grid,
  Attachments)
- `AnnouncementsKit` (`AnnouncementStatus.tint` / `AnnouncementCategory.tint`
  / `DeliveryState.tint`, `AnnouncementStatusPill`, `AnnouncementCategoryIcon`,
  `AnnouncementStatTile`, `AnnouncementHeroImage`, `EngagementStatCard`,
  `DeliveryChannelRow`, `AttachmentRow`, `AnnouncementSearchField`)

`Announcement` gained a dossier (Stage 1.9): `status` (`AnnouncementStatus`),
`category` (`AnnouncementCategory` — drives the row icon), `imageAssetName`,
`scheduledAt`, `audiences`, `location`, `eventStart`/`eventEnd`,
`registrationDeadline`, `delivery` (`AnnouncementDelivery`), `engagement`
(`AnnouncementEngagement`), `attachments` (`AnnouncementAttachment`),
`authorName` — same embedded-Codable + backward-compatible-decoder pattern.
Supporting types live in `Core/Models/AnnouncementDossier.swift`. Hero images
load `announcement_<slug>` asset images, falling back to a category gradient.

**Still deferred:** `ComposeAnnouncementView` is still create-only and only
covers pre-1.9 fields — the detail/row "Edit" action opens it as a fresh
compose. A true editor covering the dossier fields is a follow-up.

## Stage 1.10 — Certifications dashboard remodel

Federation-grade compliance dashboard. Fixed header + compliance overview
card + status filter pills + a custom certifications table with pagination.
Single-column (no detail panel) — the page scrolls as one surface.

Certifications module — file map (`Features/Operations/`):
- `CertificationsListView` (full screen — header with search / Filter menu /
  Add button, compliance overview card, filter pills, custom table, pagination
  footer; iPhone uses stacked cards. Keeps the Add + Renew sheets)
- `CertificationsKit` (`CertificationSeverity.tint`, `CertificationStatusIcon`,
  `StatusBadgeView`, `ExpiryMetadataView`, `ComplianceRing`,
  `SearchCertificationField`)

`CertificationKind` gained `systemIcon` and `categoryLabelKey`. The custom
table is hand-built (no `List` / `Table`) — column header + `LazyVStack` rows.

## Stage 1.11 — Branch Performance Overview remodel

Replaces the old progress-bar heat map with a federation-grade executive
dashboard. Header + 6 executive analytics cards + a branch performance
ranking + a Key Insights panel + three comparison charts.

Branch overview — file map:
- `BranchPerformanceView` (`Features/Branches/` — the dashboard; routed from
  the "branches" sidebar item for Admin / TD / Developer. `BranchHeatMapView`
  was deleted)
- `BranchOverviewKit` (`ExecutiveAnalyticsCard`, `MiniSparkline`,
  `TrendIndicator`, `BranchGradeRing`, `PerformanceMetricRing`,
  `BranchStatusChip`, `RankBadge`, `KeyInsightCard`, `BranchSectionCard`)
- `BranchCharts` (`AthleteDistributionChart` donut, `AttendanceTrendChart`
  12-week multi-line — both Swift Charts — and a hand-drawn `CoachingRadarChart`)
- `BranchAnalyticsEngine` (`Core/Services/`, pure — sibling to `ScoreEngine`)

`BranchAnalyticsEngine` turns repository data into `BranchAnalytics`:
composite / grade / the six metric scores are real averages of seeded
`PerformanceScore` data; growth %, the 12-week attendance trend and the
coaching radar are demo-derived (deterministic functions of the real scores
+ a stable per-branch FNV seed) so the dashboard is populated and
reproducible without a separate analytics table.

## Stage 1.12 — Athletes module remodel

Premium athlete-management dashboard, replacing the flat `List`. Header +
6 executive analytics cards + filter pills + an adaptive two-panel workspace
(athlete performance cards + a preview panel on iPad; list with a pushed full
profile on iPhone). `AthleteListView` keeps its `scope` API.

Athletes module — file map (`Features/Athletes/`):
- `AthleteListView` (the dashboard — header, analytics, filter pills, list +
  preview panels; keeps Add / Import navigation destinations)
- `AthleteIntelKit` (`AthleteIntel` view-model + `AthleteIntel.make`,
  `AthleteMetricKind`, `AthleteGradeRing`, `MiniMetricRing`, `AthleteTagChip`,
  `AthleteInsightCard`, `SearchAthleteField`)
- `AthleteDashboardCards` (`AthletePerformanceCard`, `AthletePreviewPanel`,
  `AthletePerformanceTrendChart`)

`AthleteIntel.make(athlete:score:branchName:)` builds the view-model:
composite / grade / the five metric scores are real (from the athlete's
`PerformanceScore`); the 12-week performance trend and recent-activity feed
are demo-derived deterministically. Executive cards reuse
`ExecutiveAnalyticsCard` / `MiniSparkline` / `TrendIndicator` from
`BranchOverviewKit`.

## Stage 1.13 — Role home dashboards remodel

Brings the four role home dashboards up to Stage 1.11/1.12 executive caliber —
greeting hero + an executive analytics row (`ExecutiveAnalyticsCard` +
synthesised sparklines) + premium content cards. No new design tokens.

Shared kit — `Features/Common/RoleHomeKit.swift`:
- `homeSpark(_:rising:)` — deterministic 12-point sparkline (no analytics
  table; same demo-derived approach as Stage 1.11)
- `homeAnalyticsColumns(isWide:wideCount:)` — adaptive analytics-grid columns
- `HomeQuickActionTile` — tinted quick-action tile (Coach / Branch Manager)
- `HomeActivityRow` — recent-activity feed row

Home views remodelled:
- `CoachHomeView` — analytics row (classes / athletes / hours / squad / squad
  score / attendance) + today's classes + squad performance snapshot (grade
  ring + averaged `MiniMetricRing`s, built from `AthleteIntel` over the
  coach's `AthletesStore`) + `PromotionReadinessCard` + quick actions
- `AthleteHomeView` (`FamilyHomeViews.swift`) — personal analytics row
  (composite + five metrics) + performance card (grade ring + strong/focus
  insights + `AthletePerformanceTrendChart`) + next class + recent activity,
  all from `AthleteIntel.make`
- `ParentHomeView` (`FamilyHomeViews.swift`) — aggregate analytics row across
  linked children + a rich per-child `AthletePerformanceCard`
- `BranchManagerHomeView` — `kpiGrid` replaced by an executive analytics row
  off `BranchOperationalMetrics`; quick actions moved to `HomeQuickActionTile`

Also fixed three Stage 1.12 format keys (`athlete.branch.fmt`,
`athlete.weight.fmt`, `athlete.height.fmt`) that shipped without
localizations and rendered as raw keys.

## Subview navigation chrome

The system `NavigationStack` back button is unreliable in this app's shell —
absent entirely on macOS (the shell is a plain `HStack`, so an embedded
`NavigationStack` has no toolbar surface). Every **pushed subview** therefore
draws its own bar via `.subviewChrome(_:)` (`Features/Common/SubviewChrome.swift`):
a guaranteed back button + title + optional trailing action slot, rendered as
a `safeAreaInset` so it works identically on macOS / iPad / iPhone. On iOS the
system navigation bar is hidden under it (no double bar).

Rules:
- Apply `.subviewChrome(Text(...))` in place of `.navigationTitle(_:)` on a
  view that is **pushed** (a `NavigationLink` / `navigationDestination`
  destination). Migrate any `.toolbar` action items into the trailing slot:
  `.subviewChrome(title) { actionButtons }`.
- Do NOT apply it to top-level sidebar root views — they are not pushed.
- When a root-type view is itself pushed as a subview (e.g. a home dashboard
  pushing `AthleteListView`), apply `.subviewChrome` at the push site, not
  inside the view.
- Sheet/`fullScreenCover` contents keep their own `NavigationStack` + toolbar.

## Embedded model dossiers
Heavy per-athlete records (`coachNotes`, `documents`, `ranking`, plus existing
`emergencyContacts` / `injuries` / `weightHistory`) live as embedded Codable
fields on `Athlete` rather than as separate repository tables. Rationale:
keeps the Repository protocol surface stable, makes the demo round-trippable,
and the Android port maps these embeddings directly to nested Kotlin data
classes. When a dossier grows past ~50 rows or needs cross-athlete queries,
promote it to a top-level Repository method.

## Future: SwiftData migration (deferred)
The athlete-redesign brief mentioned SwiftData. We deliberately did **not**
migrate at this stage — SwiftData adoption touches every model, every store,
and the Repository abstraction over Supabase, and breaks the
Android-port path. Visual redesign shipped on Codable + Repository. When
SwiftData is reconsidered, plan it as its own stage with its own brief.

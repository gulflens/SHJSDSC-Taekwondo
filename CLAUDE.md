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

**Still deferred:** role home dashboards (`BranchManagerHomeView`, `CoachHomeView`, `AthleteHomeView`, etc.) — left on existing primitives. Pick up in a follow-up pass once foundation is reviewed.

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

**Still deferred:** the from-scratch Timer rebuild (group mode, athlete
grouping, drill sequencing — `DrillTimerModeView` currently wraps the existing
`PomodoroLibraryView`) and the sidebar user-footer card. Follow-up pass.

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

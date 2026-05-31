# FLUTTER_PORT.md — SHJSDSC Taekwondo → Flutter

The cross-platform port of the SwiftUI app. Lives in `flutter_app/`, coexisting
with the Swift sources during migration. This file is the Flutter counterpart of
the root `CLAUDE.md`: read it before porting any module.

## Decisions (locked)
- **Sequencing:** vertical-slice-first. Port `Core` + ONE role end-to-end, then
  scale module-by-module. The **Athletes** slice is the validated reference.
- **State management:** `bloc` / Cubit. Pure `bloc` inside `lib/core` (keeps it
  Flutter-free); `flutter_bloc` glue only in `lib/features` + `lib/app`.
- **Pose analysis (`PoomsaeAnalysis`):** deferred. It is the only heavily
  native module (Vision 3D pose). Revisit with ML Kit or a platform channel.
- **Backend:** keep Supabase via `supabase_flutter`. `DemoRepository` (seed,
  in-memory) is the offline default; `SupabaseRepository` is fully implemented
  (opt-in via `--dart-define=USE_SUPABASE=true`).

## Layer map (Swift → Flutter)

| Swift | Flutter | Rule |
|---|---|---|
| `Core/Models` (Codable struct) | `lib/core/models` (class + `fromJson`/`toJson`) | No Flutter import. JSON keys MUST match Swift Codable keys / SQL columns. |
| `Core/Services` (enum of statics) | `lib/core/services` (class with statics, private ctor) | Pure functions. 1:1 port. |
| `Core/Repository` (protocol + actor) | `lib/core/repository` (abstract class + async impl) | One abstract class per Swift protocol, composed into `Repository`. |
| `Core/Stores` (`@Observable @MainActor`) | `lib/core/blocs` + per-feature cubits | Cubit + Equatable state. Pure `bloc` import only. |
| `App/AppSession` | `lib/core/blocs/session_cubit.dart` | Provided once above the router. |
| `App/RoleRouter` | `lib/app/role_router.dart` | Switches on `Role.experience`. |
| `Features/<X>` (SwiftUI) | `lib/features/<x>` (widgets) | May import Flutter. |
| `Resources/Localizable.xcstrings` | `lib/l10n/app_*.arb` → `flutter gen-l10n` | Every user-facing string. |
| `Assets.xcassets` colors | `lib/theme/app_theme.dart` tokens | One source of truth. |

## Hard rules (carried over from CLAUDE.md)
- **`lib/core` MUST NOT import `package:flutter/`.** Verify before commit:
  `grep -rn "package:flutter/" lib/core` → must be empty. (Pure `bloc`,
  `equatable`, `dart:*` are allowed — the analogue of Swift importing
  Observation/Foundation but never SwiftUI.)
- One primary type per file; filename = snake_case of the type.
- No hardcoded user-facing strings in widgets. Use the generated `L10n` getters.
  Model `labelKey` strings resolve to `L10n` via the extensions in
  `lib/features/common/localized_labels.dart` (keeps `Core` UI-free).
- Numbers stay LTR under Arabic: wrap number-only `Text` in
  `Directionality(textDirection: TextDirection.ltr, …)` (see `GradeRing`).
- RTL is automatic: `MaterialApp` flips layout from the active locale. Use
  logical insets (`EdgeInsets.symmetric(horizontal:)`), never hardcoded
  left/right — same rule as the Swift HStack/VStack auto-mirror discipline.
- IDs: `EntityID = String` (UUID v4 via `newEntityId()`), matching Swift `UUID`.
- Dates: `DateTime`, ISO-8601 in JSON. Format only at the widget layer.
- Repository swap is one line in `lib/app/locator.dart`.

## Workflow per module
1. Read this file + the Swift module's `CLAUDE.md` section.
2. Port models first (`fromJson`/`toJson`, keys match Swift), then any service,
   then the store→cubit, then the widgets.
3. Add `.arb` keys (both `app_en.arb` and `app_ar.arb`), run `flutter gen-l10n`.
4. `flutter analyze` (zero issues) + `grep -rn "package:flutter/" lib/core`
   (empty) + `flutter test`.
5. Commit `flutter: <module>`.

## Reference slice (Athletes) — file inventory
- Models: `entity_id`, `belt`, `performance_score`, `athlete`, `role`, `user`,
  `branch`.
- Service: `score_engine` (1:1 port; pinned by `test/score_engine_test.dart`).
- Repository: `repository` (interface), `demo_repository`, `seed_data`,
  `supabase_repository` (stub).
- Blocs: `session_cubit`, `features/athletes/athlete_list_cubit`
  (`AthleteIntel` view-model + filter/sort).
- UI: `features/common/design_system` (`GradeRing`, `StatusPill`,
  `SectionCard`), `localized_labels`, `athlete_list_screen`,
  `athlete_detail_screen`.

## Core layer — FULLY PORTED ✅
The entire `Core/` logic layer is ported and `lib/core` is Flutter-free
(`flutter analyze` → 0 issues; `flutter test` → green):
- **Models** — all 40 Swift files → `lib/core/models/*.dart` (46 files). Full
  `Athlete` dossier; embedded sub-types; `fromJson`/`toJson` keys match the
  Swift Codable keys / SQL columns. Non-Codable types (`Permission`,
  `PermissionMatrix`, `RoleMetadata`, `AppOwner`) ported without JSON.
- **Services** — all 12 → `lib/core/services/*.dart` (FNV seeds preserved for
  deterministic demo analytics). Platform-adjacent bits (`NotificationService`
  scheduling, `ReportExporter` PDF) are pure-logic + `// TODO(platform)` stubs.
- **Repository** — the full 21-protocol surface → `repository.dart` (interface),
  `demo_repository.dart` (in-memory, all methods), `supabase_repository.dart`
  fully implemented against the live schema), extended `seed_data.dart`. Dart
  can't overload → see the disambiguation convention below.
- **Stores** — all 16 `@Observable` stores → `lib/core/blocs/*_cubit.dart`
  (Cubit + Equatable state, pure `bloc`). `DrillTimerEngine` → ticker engine.

**Repository naming convention** (Swift overloads → Dart): suffix the variant —
`athletes()`/`athletesInBranch`/`athletesForCoach`; every `upsert(_:)` →
`upsert<Type>`; `x(branchID:)` → `xForBranch` / `xInBranch`. Follow this for
any new repository method.

## Feature modules shipped (UI)
- **Athletes** — list dashboard + detail (hero + Overview pillars). Files:
  `features/athletes/{athlete_list_cubit,athlete_list_screen,athlete_detail_screen}.dart`.
- **Coaches** — twin of Athletes: list dashboard + tabbed detail — **Overview**
  (hero + discipline competency 1–5 + cert summary), **Athletes** (assigned
  roster via `athletesForCoach(coach.id)` → athlete detail), **Certifications**
  (`certificationsForCoach` with derived valid/expiring/expired severity),
  **Competitions** (medal breakdown aggregated across the roster's tournament
  registrations). `CoachIntel` composite blends real competencies + dan rank.
  Files: `features/coaches/{coach_list_cubit,coach_list_screen,
  coach_detail_screen,coach_athletes_tab,coach_certifications_tab,
  coach_competitions_tab}.dart`, `features/common/coach_localized_labels.dart`.
- **Branches** — overview (hero KPI aggregate + dominant main-branch card +
  secondaries grid) + detail (header + operational-metrics console). Reuses
  `branches_cubit` (`BranchSummary`) + `branch_profile_cubit`
  (`BranchOperationalMetrics`). Files: `features/branches/{branches_overview_screen,
  branch_detail_screen}.dart`, `features/common/branch_localized_labels.dart`.
  3rd tab in `_ExperienceShell`. Seed expanded to 5 coaches (one per branch).
- **Schedule / Attendance** — day-view (Today/Tomorrow/+2 stepper, main branch)
  via `schedule_cubit`; tap a class → attendance roster (tap-to-cycle state,
  mark-all, batched save) via `live_class_cubit`. Files:
  `features/schedule/{schedule_screen,live_class_screen}.dart`,
  `features/common/schedule_localized_labels.dart`. 4th tab. Seed gained class
  sessions (today/+1/+2 per branch, enrolled rosters).
- **Grading** — session list across branches (`grading_cubit`) + candidate
  roster with eligibility (`GradingEngine` via repo). Files:
  `features/grading/grading_screen.dart`, `features/common/grading_localized_labels.dart`.
  Seed gained grading sessions. Lives under the **More** hub.
- **Athlete-detail tabs** — Athlete detail is tabbed: **Overview** (hero +
  pillars), **Performance** (physical/technical/wellness 0–100 trend lines via
  fl_chart from `performance_entry_cubit`), **Competitions** (medal KPI strip +
  per-event cards from `registrationsForAthlete` + tournament lookup),
  **Attendance** (rate/present/absent KPIs + recent records), **Medical**
  (vitals + allergy/condition/medication chips + injury log + weight history),
  **Notes** (pinned-first coach-notes feed), **Documents** (identity/medical/
  federation docs with derived valid/expiring/expired status), **More** (belt
  progression + emergency contacts + goals) — Medical/Notes/Documents/More read
  off the embedded `Athlete` fields (goals via the repo). Files:
  `athlete_{performance,competitions,attendance,medical,notes,documents,more}_tab.dart`,
  tabbed `athlete_detail_screen.dart`. Seed gained metric/skill/wellness series,
  tournament registrations with medals, **6 weeks of attendance history** per
  athlete (which also lit up branch `avgAttendancePct` + grading eligibility),
  blood types for all + full medical dossiers + coach notes + belt history +
  contacts + goals + documents on showcase athletes. **Full parity with the
  Swift athlete module's tab set (8 tabs).**
- **Operations** — three screens under the More hub: Announcements feed
  (`operations_cubit`), Certifications compliance dashboard with valid/expiring/
  expired buckets (`certifications_cubit`), Audit log timeline (`audit_cubit`).
  Files: `features/operations/{announcements_screen,certifications_screen,audit_screen}.dart`,
  `features/common/operations_localized_labels.dart`. Seed gained 4
  announcements, 8 certifications (mixed severities), 4 audit entries.
- **Tournaments** — Upcoming/Past list (`tournaments_cubit`) + detail (info +
  registrations with medal/position + per-registration weight-cut delta via
  `weight_cut_cubit`/`weightCutHistory`). Files:
  `features/tournaments/{tournaments_screen,tournament_detail_screen}.dart`,
  `features/common/tournament_localized_labels.dart`. Seed gained 3 tournaments,
  4 registrations (2 with medals), a 5-point weight-cut log. More hub tile.
  **Bracket viewer** (`features/tournaments/bracket_screen.dart`): single-elim
  rounds as horizontally-scrolling columns of match cards (winner bold + check),
  reached from the tournament detail when a bracket exists. Seed has an
  8-person juniorsUnder63 bracket for the UAE Junior Open (champion = Rashid).
- **Drill Timer** — interactive interval timer: preset picker (Tabata / Sparring
  Rounds / EMOM from `DrillTimerSession` factories) → live run screen driving
  `drill_timer_engine` (20 Hz ticker): phase-tinted canvas, countdown ring,
  round/drill context, transport (start/pause, skip ±, +10s, reset). Files:
  `features/drills/drill_timer_screen.dart`,
  `features/common/drill_timer_localized_labels.dart`. No seed needed. More hub
  tile. (Drill **Library** list deferred — needs a seeded `DrillLibraryEntry` set.)
- **Live Match scoring** — setup (pick athlete + opponent) → real-time PSS
  scoreboard via `live_match_cubit` (reuses `ScoringEngine`): chung/hong score
  boxes, per-side action buttons (head/body/turn/punch +pts, penalty awards
  opponent), 1 Hz round timer, undo, end/next round, finalize + winner banner.
  Files: `features/livematch/live_match_screen.dart`,
  `features/common/score_action_labels.dart`. No seed needed. More hub tile.
- **Supabase backend** — `SupabaseRepository` fully implemented against the
  live Postgres schema (mirrors Swift `SupabaseRepository.swift`). Key bridge:
  `supabase_key_codec.dart` converts camelCase model JSON ↔ snake_case columns
  (with the acronym-suffix rules + recursion into jsonb), so model
  `fromJson`/`toJson` work unchanged. Uses the pure `package:supabase` client
  (Core stays Flutter-free); `supabase_flutter` is used only in `main()` to
  initialise. Config in `app/supabase_config.dart` (committed anon key,
  overridable via `--dart-define`). **Opt-in**: `--dart-define=USE_SUPABASE=true`
  switches the locator from Demo to Supabase; default stays offline so tests +
  demo are untouched. **All methods implemented** — incl. storage uploads
  (`athletePhotos`/`userAvatars` buckets) and the realtime `scoreEventStream`
  (`.from('score_events').stream(...).eq('match_id', …)` → `ScoreEvent`s). These
  only exercise against the live backend; the demo path doesn't use them.
- **Auth (sign-in + sign-up)** — `AuthRepository` (mirrors Swift
  `AuthenticatingRepository`): `signInWithEmail` / `signOut`, implemented by both
  repos (Demo = friction-free user resolve; Supabase = real
  `auth.signInWithPassword`). `createAccount` implemented on both (Demo adds a
  User; Supabase `auth.signUp` + `user_profiles` insert). `SessionCubit` has
  `signIn` / `signUp` (parent self-registration) / `signOut` (+
  `authenticating`/`authError`). RoleRouter shows
  `features/auth/sign_in_screen.dart` when unauthenticated; it links to
  `sign_up_screen.dart`; More hub has Sign-out. On Supabase, no session →
  sign-in (the earlier `currentUser()` concession is retired). Demo
  auto-authenticates.

- **Coaching development** — the SSDC pathway: an assistant coach IS an
  `Athlete` carrying an `assistantCoach` dossier (`programRoles` +
  `AssistantCoachProfile`). `features/coaching/coaching_development_screen.dart`
  (More hub) lists assistant coaches with pipeline rung, mentor, branch,
  assisted sessions and `promotionReadiness` → athlete profile. Seed promotes
  Ahmed (assistant, under Yassin) + Khalifa (junior coach, under Salem) via a
  JSON round-trip that preserves all athlete fields.

## Navigation shell
`_ExperienceShell` (role_router.dart) mirrors the Swift `AdaptiveNavigationShell`
+ per-role TabViews: **role-aware** primary tabs driven by `Role.experience`
(`_tabsFor`). Federation roles (developer/admin/TD/branchManager/analyst) get the
full console — Athletes · Coaches · Branches · Schedule · More; a **coach** gets
Athletes · Schedule · More; **athlete/parent** get Schedule · More. The shell is
keyed by experience so switching role (More → Switch role) rebuilds it fresh.
The **More** hub (`features/more/more_hub_screen.dart`) holds overflow modules
(Grading, Tournaments, Drill Timer, Live Match, Announcements, Certifications,
Audit) + role switcher + sign-out. New non-primary features add a More tile, not
a 6th bottom tab. **Per-user scoping:** the athlete experience shows its own
profile tab (`linkedAthleteIds.first` → `AthleteDetailScreen`), parent shows a
children list (`features/family/my_children_screen.dart`) — not the full roster.
Seed has a parent account (Aisha Al Shamsi → Hessa + Sultan) + the athlete
account (Hamad → ath-3). **Branch scoping:** the branch-manager experience
scopes Athletes/Coaches/Schedule to `user.primaryBranchId` (the list cubits'
`branchScope`); coach/athlete/parent see their branch's Schedule; federation
sees everything (main-branch schedule). `AthleteListScreen` / `CoachListScreen`
/ `ScheduleScreen` take an optional `branchId`.

## Module porting roadmap (remaining)
1. **Drill Library** list (needs a seeded `DrillLibraryEntry` set) + the avatar
   pick-and-upload UI hook (the repo upload methods are done).
2. **PoomsaeAnalysis** (deferred native module — see below).

## What is intentionally NOT ported yet
- **PoomsaeAnalysis** — the Vision-based 3D-pose pipeline (video import → 3D
  pose extraction → movement segmentation → skeleton overlay). Deferred from
  the start (decision: defer). It is the only heavily-native module; the
  cross-platform path is Google ML Kit pose detection (2D, 33 landmarks) or a
  platform channel back to native Vision (iOS-only, full fidelity). Out of
  scope for a pure-Dart port without a dedicated native stage.
- **Avatar upload UI** — `uploadAthletePhoto`/`uploadUserAvatar` are implemented
  on the repository; the image-pick → upload → `avatarURL` write UI hook is a
  thin follow-up (only meaningful on the live backend).
- **`// TODO(platform)`** service stubs: local notifications, PDF export.

## Coach roster scoping — addressed
A coach's roster is shown in their **Coach profile → Athletes tab**
(`athletesForCoach(coach.id)`, gap-free). Scoping the *top-level* coach
experience to their own athletes would need a User↔Coach link (the coach
*User* id ≠ the coach *record* id), which the Swift schema doesn't model — so
it's intentionally left to a backend-schema decision rather than a fragile
client-side guess.

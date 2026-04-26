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
- `SeedData.build()` produces realistic SSDSC content: 4 branches (Al Ramtha,
  Al Jazzat, Al Khan, Shaghrafa), 5 coaches with real names from public
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

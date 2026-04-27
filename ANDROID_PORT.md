# ANDROID_PORT.md — SHJSDSC Android port reference

This is the canonical mapping doc the Android Claude Code session reads
alongside CLAUDE.md. The Android app is a **fresh native Kotlin + Jetpack
Compose codebase** that mirrors the iOS SwiftUI architecture 1:1. It is
**not** Kotlin Multiplatform — the iOS app stays Swift; the Android app
re-implements `Core/` in Kotlin and re-implements every view in Compose.

The architectural property that makes this mechanical: the iOS `Core/`
folder is pure `Codable` data + `actor` repos + pure-function services
with **zero SwiftUI imports**. Every type maps to a Kotlin equivalent
without behavioural change. Views map screen-for-screen because Compose
and SwiftUI share a declarative + state-driven model.

---

## Stack

| Concern | iOS | Android |
|---|---|---|
| Language | Swift 5.9+ | Kotlin 2.x |
| UI | SwiftUI | Jetpack Compose |
| Async | `async`/`await`, `actor` | `suspend fun`, `Mutex`-guarded class |
| State | `@Observable @MainActor` | `ViewModel` + `StateFlow` |
| DI | Manual (constructor inject + `@Environment`) | Hilt |
| Backend | supabase-swift 2.x | supabase-kt 3.x |
| Networking | URLSession | Ktor (bundled with supabase-kt) |
| Serialization | `Codable` | `kotlinx.serialization` |
| Charts | Apple Charts framework | Vico (`com.patrykandpatrick.vico:compose`) |
| Image loading | `AsyncImage` | Coil 3 (`io.coil-kt.coil3:coil-compose`) |
| Photo picker | `PhotosUI.PhotosPicker` | `ActivityResultContracts.PickVisualMedia` |
| Localization | `Localizable.xcstrings` (en + ar) | `res/values/strings.xml` + `res/values-ar/strings.xml` |
| Notifications | `UNUserNotificationCenter` | `NotificationCompat` + `AlarmManager` (foreground) / WorkManager (deferred) |
| Apple/Google sign-in | Sign in with Apple | Credential Manager API + Sign in with Google |

Min SDK 26 (Android 8.0) — matches iOS deployment cadence and gives access
to modern Material You theming under SDK 31+.

---

## Folder structure (mirrors iOS)

```
app/src/main/kotlin/studio/gulflens/shjsdsc/
├── core/
│   ├── models/          ← data classes (no Compose imports — Android port of "no SwiftUI in Core/")
│   ├── repository/      ← interfaces + Demo + Supabase implementations
│   ├── services/        ← pure functions (ScoreEngine, GradingEngine, BracketEngine, ScoringEngine)
│   └── stores/          ← ViewModels (note: kept here despite Android convention of feature/viewmodel,
│                          to mirror iOS Core/Stores)
├── features/
│   ├── athletes/        ← @Composable screens, one feature per folder
│   ├── coaches/
│   ├── branches/
│   ├── performance/
│   ├── schedule/
│   ├── tournaments/
│   ├── grading/
│   ├── operations/
│   ├── notifications/
│   ├── auth/
│   └── common/          ← Avatar, BeltStrip, KPITile, ExportButton, PhotoPicker
├── roles/               ← per-role NavHost graphs
├── app/                 ← Application class, Hilt modules, AppNavigation, theme
└── res/
    ├── values/strings.xml
    ├── values-ar/strings.xml
    └── drawable/
```

Hard rule: `core/` packages must not `import androidx.compose.*` or
`android.*` — same SwiftUI ban. Run before each commit:

```
grep -r "androidx.compose" app/src/main/kotlin/studio/gulflens/shjsdsc/core/  # must be empty
grep -r "import android\." app/src/main/kotlin/studio/gulflens/shjsdsc/core/  # must be empty
```

---

## Type mapping

### Primitives

| Swift | Kotlin |
|---|---|
| `String` | `String` |
| `Int` | `Int` |
| `Double` | `Double` |
| `Bool` | `Boolean` |
| `UUID` (aliased `EntityID`) | `java.util.UUID` (typealiased `EntityID`) |
| `Date` | `kotlinx.datetime.Instant` (preferred) or `java.time.Instant` |
| `[T]` | `List<T>` |
| `[K: V]` | `Map<K, V>` |
| `Set<T>` | `Set<T>` |
| `T?` | `T?` |

### Composite types

| Swift | Kotlin |
|---|---|
| `struct` (Codable) | `@Serializable data class` |
| `enum` (raw value) | `enum class` (with property for label key) |
| `enum` (associated values) | `sealed class` or `sealed interface` |
| `protocol` | `interface` |
| `protocol` with `Sendable` | `interface` (Kotlin doesn't enforce; default-thread-safe via coroutines) |
| `actor` | `class` with private `Mutex` guarding mutable state |
| `@Observable @MainActor class` | `class : ViewModel()` exposing `StateFlow<UiState>` |
| `typealias EntityID = UUID` | `typealias EntityID = UUID` (top-level in `core.models`) |
| `extension Type { ... }` | top-level extension functions or `companion object` |

### Function signatures

| Swift | Kotlin |
|---|---|
| `func name() async throws -> T` | `suspend fun name(): T` (throws on `Result`-returning conventions or just throws) |
| `func name(_ x: X)` | `fun name(x: X)` |
| `func name(label: X)` | `fun name(label: X)` |
| `func name(_ x: X, label: Y)` | `fun name(x: X, label: Y)` |
| `init(...)` | `constructor(...)` or primary constructor in class header |
| `Closure: (X) -> Y` | `(X) -> Y` |
| `@escaping closure` | every Kotlin lambda is escaping by default |

### Codable mapping

```swift
// iOS
public struct Athlete: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var fullName: String
    public var fullNameAr: String
    // ...
}
```

```kotlin
// Android
@Serializable
data class Athlete(
    val id: EntityID,
    val fullName: String,
    val fullNameAr: String,
    // ...
)
```

For snake_case ↔ camelCase against Supabase use `@SerialName("full_name")` on
each property OR install a global naming strategy on the `Json` instance:
```kotlin
val json = Json {
    namingStrategy = JsonNamingStrategy.SnakeCase
    ignoreUnknownKeys = true
}
```

---

## Architecture mapping

### Repository (the actor pattern)

```swift
// iOS
public actor DemoStore {
    public var athletes: [Athlete]
    public func upsertAthlete(_ a: Athlete) { ... }
}

public struct DemoRepository: Repository {
    private let store: DemoStore
    public func athletes() async throws -> [Athlete] { await store.athletes }
    public func upsert(_ athlete: Athlete) async throws { await store.upsertAthlete(athlete) }
}
```

```kotlin
// Android
class DemoStore(seed: SeedBundle) {
    private val mutex = Mutex()
    private val _athletes = mutableListOf<Athlete>().apply { addAll(seed.athletes) }

    suspend fun athletes(): List<Athlete> = mutex.withLock { _athletes.toList() }

    suspend fun upsertAthlete(a: Athlete) = mutex.withLock {
        val idx = _athletes.indexOfFirst { it.id == a.id }
        if (idx >= 0) _athletes[idx] = a else _athletes.add(a)
    }
}

class DemoRepository(private val store: DemoStore) : Repository {
    override suspend fun athletes(): List<Athlete> = store.athletes()
    override suspend fun upsert(athlete: Athlete) = store.upsertAthlete(athlete)
}
```

### Stores (the @Observable @MainActor pattern)

```swift
// iOS
@Observable @MainActor
public final class AthletesStore {
    public private(set) var athletes: [Athlete] = []
    public func load(branchID: EntityID) async {
        athletes = try await repository.athletes(branchID: branchID)
    }
}
```

```kotlin
// Android
@HiltViewModel
class AthletesViewModel @Inject constructor(
    private val repository: Repository,
) : ViewModel() {
    private val _athletes = MutableStateFlow<List<Athlete>>(emptyList())
    val athletes: StateFlow<List<Athlete>> = _athletes.asStateFlow()

    fun load(branchID: EntityID) {
        viewModelScope.launch {
            _athletes.value = repository.athletes(branchID)
        }
    }
}
```

In Compose:
```kotlin
@Composable
fun AthleteListScreen(viewModel: AthletesViewModel = hiltViewModel()) {
    val athletes by viewModel.athletes.collectAsStateWithLifecycle()
    LaunchedEffect(Unit) { viewModel.load(branchID) }
    LazyColumn { items(athletes) { athlete -> AthleteRow(athlete) } }
}
```

### Views (SwiftUI → Compose)

| SwiftUI | Compose |
|---|---|
| `View` | `@Composable` function |
| `VStack` | `Column` |
| `HStack` | `Row` |
| `ZStack` | `Box` |
| `LazyVStack` / `List` | `LazyColumn` |
| `LazyVGrid` | `LazyVerticalGrid` |
| `ScrollView` | `Modifier.verticalScroll(rememberScrollState())` (small) or `LazyColumn` (large) |
| `Text("key")` (auto-localised) | `Text(stringResource(R.string.key))` |
| `Text(verbatim: "X")` | `Text("X")` |
| `Image(systemName: "x")` | `Icon(Icons.Default.X, ...)` (Material Icons) |
| `Button { } label: { }` | `Button(onClick = {}) { ... }` |
| `Toggle` | `Switch` |
| `Picker` | `DropdownMenu` or `ExposedDropdownMenu` |
| `Slider` | `Slider` |
| `TextField` | `TextField` / `OutlinedTextField` |
| `NavigationStack` + `NavigationLink` | `NavHost` + `composable("route")` |
| `.sheet` | `ModalBottomSheet` or full-screen via nav route |
| `.task { ... }` | `LaunchedEffect(Unit) { ... }` |
| `@State` | `var x by remember { mutableStateOf(...) }` |
| `@AppStorage("k")` | `DataStore` Preferences (preferred) or `SharedPreferences` |
| `@Environment(...)` | `CompositionLocal` or Hilt-injected ViewModel |
| `.padding()` | `Modifier.padding(...)` |
| `Color.blue` | `Color.Blue` (or `MaterialTheme.colorScheme.primary` for theme-aware) |
| `Charts (LineMark, PointMark)` | Vico's `LineCartesianLayer` (or `MPAndroidChart` if you need older API support) |
| `AsyncImage(url:)` | `coil3.compose.AsyncImage(model = url, ...)` |
| `ShareLink(item:)` | `Intent.ACTION_SEND` + `Intent.createChooser` |
| `PhotosUI.PhotosPicker` | `rememberLauncherForActivityResult(PickVisualMedia())` |
| `.environment(\.layoutDirection, .leftToRight)` | `CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) { ... }` |
| `.environment(\.locale, ...)` | App-level `Locale` config + `AppCompatDelegate.setApplicationLocales(...)` |

### Hard rule for views

The same anti-hardcoded-English rule applies. Every user-facing string
must come from `strings.xml`. Run before each commit:

```
grep -rn 'Text("[A-Z]' app/src/main/kotlin/studio/gulflens/shjsdsc/features \
                       app/src/main/kotlin/studio/gulflens/shjsdsc/roles \
                       app/src/main/kotlin/studio/gulflens/shjsdsc/app
# any hits = hardcoded literal — replace with stringResource(R.string.key)
```

`Text("verbatim_data")` for runtime data is fine, but bind static UI to
`stringResource(R.string.X)`. Mirror the iOS xcstrings keys 1:1 — the
strings.xml entry for `tab.home` should look like:

```xml
<string name="tab_home">Home</string>
```

(Android replaces `.` with `_` in resource IDs but the source of truth for
the key name is still `tab.home`.)

---

## Localization parity

For every key in `Resources/Localizable.xcstrings` (iOS), there must be a
matching `<string name="..."/>` in BOTH `res/values/strings.xml` (English
source) AND `res/values-ar/strings.xml` (Arabic). The Android Claude Code
session can read the iOS xcstrings file via absolute path:

```
/Volumes/Storage/Coding/SHJSDSC-Taekwondo/Resources/Localizable.xcstrings
```

A small extraction script (drop in `tools/extract-strings.kts` if needed):

```bash
jq -r '.strings | to_entries[] | "<string name=\"\(.key | gsub("\\."; "_"))\">\(.value.localizations.en.stringUnit.value)</string>"' \
  /Volumes/Storage/Coding/SHJSDSC-Taekwondo/Resources/Localizable.xcstrings
```

(Substitute `.en` → `.ar` for the Arabic file.)

### RTL

Android's `LocaleList` + `LayoutDirection.Rtl` give the same automatic
mirroring SwiftUI does — `Row`/`Column` flip under RTL automatically.
Same hard rules:
- Use `start`/`end` paddings, never `left`/`right`
- Wrap number-heavy text in `CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr)` to keep digits LTR
- Vector drawables that should mirror need `android:autoMirrored="true"`

---

## Supabase parity

The same Supabase project, same SQL schema, same RLS policies. Just a
different client SDK.

```kotlin
val supabase = createSupabaseClient(
    supabaseUrl = SupabaseConfig.URL,
    supabaseKey = SupabaseConfig.ANON_KEY,
) {
    install(Postgrest)
    install(Auth) { scheme = "shjsdsc"; host = "login-callback" }
    install(Storage)
    install(Realtime)
}

class SupabaseRepository(private val client: SupabaseClient) : Repository {
    override suspend fun athletes(branchID: EntityID): List<Athlete> =
        client.postgrest["athletes"]
            .select { filter { eq("branch_id", branchID) } }
            .decodeList()
}
```

`SupabaseConfig.kt` mirrors `App/SupabaseConfig.swift` exactly:

```kotlin
object SupabaseConfig {
    const val URL = "https://khsmwnkitvutcuhypfcz.supabase.co"
    const val ANON_KEY = "eyJ..."
}
```

Real-time subscriptions on `score_events`:

```kotlin
val channel = client.channel("score-events-$matchId")
val flow = channel.postgresChangeFlow<PostgresAction.Insert>(schema = "public") {
    table = "score_events"
    filter = "match_id=eq.$matchId"
}
channel.subscribe()
flow.onEach { action -> store.applyEvent(action.decodeRecord<ScoreEvent>()) }.launchIn(scope)
```

---

## Stage-by-stage port plan

Each stage feeds the Android Claude Code session a prompt in the same
shape as the iOS stages, but with one key addition: **read the matching
iOS source file at the absolute path** before writing the Kotlin port.

### Stage 0 — Android shell
- Bootstrap project (manual via Android Studio)
- Write `CLAUDE.md` adapted for Android (read iOS `CLAUDE.md`, swap stack
  references)
- Add Gradle dependencies: Hilt, Compose, Supabase, kotlinx.serialization,
  Coil, Vico
- Create folder skeleton

### Stage 1 — foundation + bilingual + Phase 1 screens
- Read iOS `Core/Models/*.swift` → port to `core/models/*.kt` as
  `@Serializable data class`
- Read iOS `Core/Repository/Repository.swift` → port to `Repository`
  interface
- Read iOS `Core/Repository/DemoRepository.swift` → port `DemoStore` as
  Mutex-guarded class, `DemoRepository` as interface impl
- Read iOS `Core/Repository/SeedData.swift` → port to Kotlin
- Read iOS `Core/Services/ScoreEngine.swift` → port to top-level functions
- Read iOS `Core/Stores/*.swift` → port to `ViewModel` + `StateFlow`
- Read iOS `App/AppSession.swift` → port to `AppSessionViewModel`
- Read iOS `Roles/*TabView.swift` → port to `BottomNavigation` + `NavHost`
- Read iOS `Features/Common/*.swift` → port to Composables
- Read iOS Athletes/Coaches/Branches/Performance/Schedule features → port
  screens
- Extract iOS xcstrings into `strings.xml` (en + ar)

### Stage 2 — performance entry + belt grading + certificates
- Same pattern: read iOS files, port. The Charts framework usage maps to
  Vico.

### Stage 3 — tournaments + brackets + live match tagger
- The bracket Canvas usage maps to Compose `Canvas { drawLine(...) }`.
- Live match tagger timer: replace `Timer.scheduledTimer` with
  `flow { while (true) { delay(1000); emit(...) } }`.

### Stage 4 — operations + notifications + permissions + exports
- `UNUserNotificationCenter` → `NotificationCompat.Builder` + AlarmManager
  for scheduled notifs.
- CSV export: same string-building, write to `context.cacheDir`, share via
  `FileProvider` + `Intent.ACTION_SEND`.

### Stage 5 — Supabase backend swap
- Same SQL migrations, same RLS — already deployed.
- Port `SupabaseRepository.swift` → `SupabaseRepository.kt` using
  supabase-kt 3.x.
- Sign in with Apple → Sign in with Google (use Credential Manager API).
- Photo upload via `Storage` plugin.
- Real-time live match via `Realtime` plugin.

---

## Key gotchas

1. **Coroutine scope discipline.** Repository `suspend fun`s should never
   launch their own scopes; let callers (ViewModels) own the scope.
2. **StateFlow vs SharedFlow.** Use StateFlow for UI state (latest value
   replay), SharedFlow for one-shot events (e.g. "show toast").
3. **`stringResource()` only works inside `@Composable`.** For ViewModel
   error messages, store the resource ID and resolve at the view layer.
4. **Hilt injection in non-Activity entrypoints.** Use `@HiltAndroidApp`
   on Application, `@AndroidEntryPoint` on Activity, `@HiltViewModel` on
   VM. Composables get VMs via `hiltViewModel()`.
5. **Compose recomposition.** Avoid creating new lambdas/objects inside
   composables — wrap in `remember { }` or hoist.
6. **RTL gotcha:** SF Symbol arrows had `.flipsForRightToLeftLayoutDirection`;
   on Android use `Modifier.scale(-1f, 1f)` or `android:autoMirrored="true"`
   on the drawable.
7. **No `@MainActor` enforcement.** Compose runs the recomposition phase on
   main; ViewModel state mutations must happen on main. Use
   `withContext(Dispatchers.Main)` or just `viewModelScope.launch` (which
   defaults to immediate Main dispatcher).
8. **Localization fallback.** Android falls back to `values/` if
   `values-ar/` is missing a key. Same as iOS — but log missing keys.

---

## Workflow per stage (Android)

1. Read this file + the matching iOS source files.
2. Write Kotlin port.
3. Run `./gradlew :app:assembleDebug` after each batch — the Kotlin
   compiler is stricter than Swift's about exhaustiveness, so errors
   surface fast.
4. Run the grep checks: no `androidx.compose` in `core/`, no hardcoded
   `Text("Capital...")` in features.
5. Commit with `Stage N: <summary>` matching the iOS commit message.

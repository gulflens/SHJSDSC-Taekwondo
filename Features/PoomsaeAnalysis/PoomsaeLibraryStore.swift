import Foundation
import Observation

// MARK: - PoomsaeLibraryStore
//
// Stage 2.6.a — view-facing state for the recording list screen.
//
// `@Observable @MainActor` store (per the app's store convention). Owns the
// `[PoomsaeRecording]` collection, sorted by `importedAt` descending, and
// exposes async actions backed by `PoomsaeFileStore` + `PoomsaeVideoImporter`.

// MARK: - State
//   recordings · isImporting · importError

// MARK: - Actions
//   load() · importVideo(from:) · delete(_:)

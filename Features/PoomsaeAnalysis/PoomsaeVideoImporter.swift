import Foundation
import AVFoundation

// MARK: - PoomsaeVideoImporter
//
// Stage 2.6.a — turns a movie picked from the Photos library into a persisted
// `PoomsaeRecording`.
//
// Steps:
//   1. Receive a movie file URL (from a PhotosPicker `Transferable`).
//   2. Validate it as a readable `AVURLAsset` with a video track; read
//      duration and natural video size.
//   3. Copy it into the sandbox via `PoomsaeFileStore`.
//   4. Build and return a `PoomsaeRecording`.
//
// On any failure the partial copy is cleaned up and an error is thrown for
// the UI to surface.

// MARK: - ImportedMovie (Transferable movie-file helper for PhotosPicker)

// MARK: - PoomsaeVideoImporter

// MARK: - PoomsaeImportError
//   unreadableAsset · noVideoTrack · copyFailed

import Foundation

// MARK: - PoomsaeRecording
//
// Stage 2.6.a — Poomsae Pose Extraction & Movement Segmentation.
//
// Top-level record for one imported poomsae video. Pure `Codable` struct
// (no SwiftData — honours the CLAUDE.md "models are pure Codable structs"
// hard rule). Persisted in the `recordings.json` index by `PoomsaeFileStore`.
//
// Per-frame pose data is NOT stored here — it lives in a separate binary
// cache file referenced by `poseCacheFilename`. The segmented movements ARE
// embedded (`segments`), following the app's embedded-dossier pattern: they
// are few, small, and always queried alongside their parent recording.

// MARK: - Stored fields
//   id · originalFilename · storedFilename · importedAt
//   durationSeconds · videoSize · poseCacheFilename? · segments

// MARK: - Codable
//   Backward-compatible decoding via defaulted properties.

import Foundation

// MARK: - PoomsaeFileStore
//
// Stage 2.6.a — the feature-local persistence actor (the Repository-pattern
// equivalent for this module; the global `Repository` protocol in Core/ is
// intentionally left untouched).
//
// Owns the sandbox layout:
//
//   Documents/PoomsaeAnalysis/
//     recordings.json            index { version, recordings: [PoomsaeRecording] }
//     Videos/<uuid>.mov          copied source videos (excluded from backup)
//     PoseCache/<uuid>.poses     binary pose cache (see PoseCacheCodec)
//
// `actor` for safe concurrent access; all I/O is async off the main actor.

// MARK: - Directory layout
//   rootDirectory · videosDirectory · poseCacheDirectory · indexURL
//   videoURL(for:) · poseCacheURL(for:)

// MARK: - Index
//   loadRecordings() · save(_:) · delete(id:)

// MARK: - Video files
//   importVideo(from:as:) — copy a movie into Videos/, return stored filename

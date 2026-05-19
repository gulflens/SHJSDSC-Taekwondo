import Foundation
import CoreMedia

// MARK: - MovementSegment
//
// Stage 2.6.a — one discrete movement carved out of a poomsae performance by
// `PoomsaeMovementSegmenter`. Pure `Codable` struct, embedded on
// `PoomsaeRecording`.
//
// `CMTime` is not `Codable`, so the boundary times are stored as `Double`
// seconds and re-exposed as computed `CMTime` accessors to match the
// brief-facing API (`startTime` / `endTime` / `peakMotionTime`).

// MARK: - Stored fields
//   index · startSeconds · endSeconds · peakMotionSeconds · peakMotionValue

// MARK: - CMTime accessors
//   startTime · endTime · peakMotionTime (computed from the stored seconds)

import Foundation
import Observation

// MARK: - PoomsaeAnalysisStore
//
// Stage 2.6.a — view-facing state for the analysis screen, scoped to one
// `PoomsaeRecording`.
//
// `@Observable @MainActor` store. On open it either loads the cached
// `[PoseFrame]` (cache hit -> instant) or drives `PoomsaePoseExtractor`
// (cache miss -> progress bar), then runs `PoomsaeMovementSegmenter`, persists
// the segments back onto the recording, and publishes everything the analysis
// view binds to.

// MARK: - State
//   recording · poseFrames · motionEnergy · segments
//   extractionProgress · phase (idle/extracting/segmenting/ready/failed)
//   playerTime

// MARK: - Actions
//   prepare() · cancel()

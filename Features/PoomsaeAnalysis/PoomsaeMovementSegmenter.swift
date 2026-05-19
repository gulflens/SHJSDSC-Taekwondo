import Foundation
import CoreMedia

// MARK: - PoomsaeMovementSegmenter
//
// Stage 2.6.a — segments a `[PoseFrame]` sequence into discrete movements.
//
// Pure value-level logic (Foundation + CoreMedia + simd only — no Vision, no
// AVFoundation), so it is fully unit-testable against synthetic pose data.
//
// Pipeline:
//   1. Motion energy E(t) — confidence-weighted sum of per-joint Euclidean
//      displacement between consecutive frames.
//   2. Smooth E with a centred rolling mean (smoothingWindow).
//   3. Adaptive pause threshold = floor + pauseFraction * (peak - floor),
//      floor/peak from the 5th / 95th percentile of the smoothed curve.
//   4. Coalesce sub-threshold runs into pauses (>= minPauseDuration); each
//      pause's argmin is a boundary. Movements are the active spans between.
//   5. Merge any segment shorter than minSegmentDuration into the next.

// MARK: - motionEnergy(frames:) -> [Float]            (exposed for tests)

// MARK: - smooth(_:window:) -> [Float]

// MARK: - segment(frames:parameters:) -> [MovementSegment]

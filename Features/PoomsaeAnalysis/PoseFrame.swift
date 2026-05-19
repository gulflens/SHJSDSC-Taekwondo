import Foundation
import CoreMedia
import simd

// MARK: - PoseFrame
//
// Stage 2.6.a — one sampled video frame's 3D body pose.
//
//   timestamp   — frame presentation time
//   joints      — per-joint 3D position; nil when the joint is unresolved
//   confidences — per-joint confidence (3D-only pipeline: 1.0 when resolved)
//
// Keyed on `PoomsaeJoint` (a stable, Codable enum) rather than Vision's
// `VNHumanBodyPose3DObservation.JointName`, which is neither Codable nor
// stable — see `PoomsaeJoint`. A no-person-detected frame is still emitted
// with its timestamp and empty joints so the timeline stays continuous.

// MARK: - PoseFrame (in-memory, CMTime timestamp)

// MARK: - PoseFrameRecord (on-disk Codable representation)
//   timestamp persisted as Double seconds; positions as [Float] triples.

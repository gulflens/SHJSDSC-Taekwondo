import Foundation
import CoreMedia
import simd

// MARK: - PoseFrame
//
// Stage 2.6.a — one sampled video frame's 3D body pose.
//
//   timestamp   — frame presentation time
//   joints      — per-joint 3D position; the value is `nil` when the joint
//                 is unresolved, but the KEY is kept (per the brief), so the
//                 value type is `SIMD3<Float>?` and every joint key is always
//                 present
//   confidences — per-joint confidence. The 3D-only pipeline has no real
//                 per-joint confidence, so this is 1.0 for a resolved joint
//                 and 0.0 for an unresolved one
//
// Keyed on `PoomsaeJoint` rather than Vision's joint-name type, which is
// neither Codable nor stable. A no-person-detected frame is still emitted via
// `empty(at:)` so the pose timeline stays continuous.

// `nonisolated` — produced and consumed by the off-main extraction pipeline
// and the pure segmenter (project default isolation is MainActor).
public nonisolated struct PoseFrame: Sendable {

    public let timestamp: CMTime
    public let joints: [PoomsaeJoint: SIMD3<Float>?]
    public let confidences: [PoomsaeJoint: Float]

    public init(
        timestamp: CMTime,
        joints: [PoomsaeJoint: SIMD3<Float>?],
        confidences: [PoomsaeJoint: Float]
    ) {
        self.timestamp = timestamp
        self.joints = joints
        self.confidences = confidences
    }

    /// A no-person-detected frame: every joint key present with a `nil` value
    /// and zero confidence, so the pose timeline stays time-continuous.
    public static func empty(at timestamp: CMTime) -> PoseFrame {
        var joints: [PoomsaeJoint: SIMD3<Float>?] = [:]
        var confidences: [PoomsaeJoint: Float] = [:]
        for joint in PoomsaeJoint.allCases {
            joints.updateValue(nil, forKey: joint)   // keeps the key, value nil
            confidences[joint] = 0
        }
        return PoseFrame(timestamp: timestamp, joints: joints, confidences: confidences)
    }

    /// Resolved 3D position of a joint, or `nil` when unresolved / absent.
    public func position(for joint: PoomsaeJoint) -> SIMD3<Float>? {
        joints[joint] ?? nil
    }

    /// Confidence for a joint (0 when absent).
    public func confidence(for joint: PoomsaeJoint) -> Float {
        confidences[joint] ?? 0
    }

    /// Number of joints resolved in this frame.
    public var detectedJointCount: Int {
        PoomsaeJoint.allCases.reduce(0) { $0 + (position(for: $1) != nil ? 1 : 0) }
    }

    /// `true` when at least one joint was resolved.
    public var hasDetection: Bool { detectedJointCount > 0 }
}

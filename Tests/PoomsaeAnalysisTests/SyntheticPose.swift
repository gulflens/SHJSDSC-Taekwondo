import Foundation
import CoreMedia
import simd
@testable import SHJSDSC

// MARK: - SyntheticPose
//
// Stage 2.6.a — deterministic synthetic `[PoseFrame]` builders for the
// movement-segmentation unit tests. No Vision, no video — pure value data.
//
// Frames are built from a per-frame scalar x-displacement trajectory: every
// joint sits at a fixed base position plus `(x, 0, 0)` at full confidence.
// A "still" span repeats the same x (zero motion energy); a "pulse" advances
// x by a constant step each frame (constant non-zero motion energy).

enum SyntheticPose {

    /// Sampling rate used to time the synthetic frames.
    static let fps: Double = 15

    /// Distinct fixed base position per joint.
    static func basePositions() -> [PoomsaeJoint: SIMD3<Float>] {
        var result: [PoomsaeJoint: SIMD3<Float>] = [:]
        for (i, joint) in PoomsaeJoint.allCases.enumerated() {
            result[joint] = SIMD3(Float(i) * 0.10, Float(i) * 0.05, 0)
        }
        return result
    }

    /// Builds frames from a per-frame x-displacement trajectory.
    static func frames(displacements: [Float]) -> [PoseFrame] {
        let base = basePositions()
        return displacements.enumerated().map { index, x in
            var joints: [PoomsaeJoint: SIMD3<Float>?] = [:]
            var confidences: [PoomsaeJoint: Float] = [:]
            for joint in PoomsaeJoint.allCases {
                let b = base[joint] ?? .zero
                joints.updateValue(SIMD3(b.x + x, b.y, b.z), forKey: joint)
                confidences[joint] = 1
            }
            let time = CMTime(seconds: Double(index) / fps, preferredTimescale: 600)
            return PoseFrame(timestamp: time, joints: joints, confidences: confidences)
        }
    }

    /// A displacement trajectory with `pulses` motion pulses separated by
    /// still spans: a leading still, then each pulse followed by a still —
    /// except the last pulse, so the clip ends on a movement and segments
    /// to exactly `pulses` movements.
    static func pulseTrajectory(
        stillFrames: Int,
        pulseFrames: Int,
        pulses: Int,
        step: Float
    ) -> [Float] {
        var xs: [Float] = []
        var x: Float = 0
        xs.append(contentsOf: Array(repeating: x, count: stillFrames))
        for pulse in 0..<pulses {
            for _ in 0..<pulseFrames {
                x += step
                xs.append(x)
            }
            if pulse < pulses - 1 {
                xs.append(contentsOf: Array(repeating: x, count: stillFrames))
            }
        }
        return xs
    }
}

import Foundation

// MARK: - PoomsaeJoint
//
// Stage 2.6.a — a stable, `Codable`, `CaseIterable` joint identifier mirroring
// `VNHumanBodyPose3DObservation.JointName`.
//
// Vision's joint-name type is not `Codable` and is not guaranteed stable for
// on-disk storage, and pulling it into the pure segmentation logic would drag
// the `Vision` framework into unit tests. `PoomsaeJoint` is the project-owned
// vocabulary: the extractor maps Vision joints into it, the cache stores it,
// and the segmenter / tests work purely against it.

// MARK: - Cases
//   head · neck · spine joints · shoulders · elbows · wrists
//   hips · knees · ankles · root

// MARK: - Vision bridging
//   init?(visionJointName:) — maps a VNHumanBodyPose3DObservation.JointName

import Foundation

// MARK: - PoomsaeJoint
//
// Stage 2.6.a — a stable, `Codable`, `CaseIterable` joint identifier mirroring
// the 17 joints of `VNHumanBodyPose3DObservation`.
//
// Vision's joint-name type is not `Codable` and is not guaranteed stable for
// on-disk storage, and pulling it into the pure segmentation logic would drag
// the `Vision` framework into unit tests. `PoomsaeJoint` is the project-owned
// vocabulary: the extractor maps Vision joints into it, the cache stores it,
// and the segmenter / tests work purely against it.
//
// The Vision bridging itself lives in `PoomsaePoseExtractor` — the one file
// that imports `Vision` — so this type stays framework-free.

// `nonisolated` — the project builds with SWIFT_DEFAULT_ACTOR_ISOLATION =
// MainActor; this enum is used inside the off-main extraction pipeline and
// the pure (testable) segmenter, so it must opt out of main-actor isolation.
public nonisolated enum PoomsaeJoint: String, Codable, CaseIterable, Sendable, Hashable {
    case topHead
    case centerHead
    case centerShoulder
    case leftShoulder
    case rightShoulder
    case leftElbow
    case rightElbow
    case leftWrist
    case rightWrist
    case spine
    case root
    case leftHip
    case rightHip
    case leftKnee
    case rightKnee
    case leftAnkle
    case rightAnkle
}

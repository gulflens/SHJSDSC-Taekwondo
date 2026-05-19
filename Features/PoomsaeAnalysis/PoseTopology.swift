import Foundation

// MARK: - PoseTopology
//
// Stage 2.6.a — the standard human-body bone graph used to draw the skeleton
// overlay. Pure constant data: an ordered list of `PoomsaeJoint` pairs
// (shoulders -> elbows -> wrists, hips -> knees -> ankles, spine, head).

public nonisolated enum PoseTopology {

    /// Every drawable limb segment, as ordered joint pairs.
    public static let bones: [(PoomsaeJoint, PoomsaeJoint)] = [
        // Head and spine.
        (.topHead, .centerHead),
        (.centerHead, .centerShoulder),
        (.centerShoulder, .spine),
        (.spine, .root),
        // Arms.
        (.centerShoulder, .leftShoulder),
        (.centerShoulder, .rightShoulder),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        // Legs.
        (.root, .leftHip),
        (.root, .rightHip),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle),
    ]
}

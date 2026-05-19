import Foundation

// MARK: - PoseTopology
//
// Stage 2.6.a — the standard human-body bone graph used to draw the skeleton
// overlay. Pure constant data: an ordered list of `PoomsaeJoint` pairs
// (shoulders -> elbows -> wrists, hips -> knees -> ankles, spine, head).
//
// Kept separate from `PoseFrame` so both the overlay renderer and any future
// reference-comparison code share one definition of "which joints connect".

// MARK: - bones
//   [(PoomsaeJoint, PoomsaeJoint)] — every drawable limb segment

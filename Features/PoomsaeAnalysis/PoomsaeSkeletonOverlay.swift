#if os(iOS)
import SwiftUI

// MARK: - PoomsaeSkeletonOverlay
//
// Stage 2.6.a — a `Canvas` overlay drawing the 3D body pose for the frame at
// the player's current time.
//
// Joints are projected to 2D using the pose's image-space projection when
// available, otherwise a simple orthographic projection of the 3D X/Y.
// Bones are drawn per `PoseTopology`. Resolved joints render solid; unresolved
// joints are omitted (the 3D-only pipeline has no confidence gradient).

// MARK: - PoomsaeSkeletonOverlay

// MARK: - Joint projection

// MARK: - Bone drawing
#endif

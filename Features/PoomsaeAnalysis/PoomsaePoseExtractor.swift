import Foundation
import AVFoundation
import Vision

// MARK: - PoomsaePoseExtractor
//
// Stage 2.6.a — the 3D pose extraction pipeline.
//
//   Input:  an AVURLAsset for a stored poomsae video.
//   Output: AsyncStream<PoseFrame>, one element per sampled frame.
//
// Pulls frames with AVAssetReader + AVAssetReaderTrackOutput, samples down to
// 15 fps (intermediate frames decoded and dropped), and runs
// VNDetectHumanBodyPose3DRequest on each sampled frame via a
// VNImageRequestHandler. Joints below the confidence threshold are set to nil
// (key kept). No-person frames yield an empty PoseFrame with the timestamp.
//
// Runs in a detached Task off the main actor; reports progress through a
// (Double) -> Void callback.

// MARK: - extractPoses(asset:parameters:progress:) -> AsyncStream<PoseFrame>

// MARK: - Frame sampling
//   stride computed from the track's nominal frame rate

// MARK: - Vision request handling
//   VNDetectHumanBodyPose3DRequest -> PoomsaeJoint-keyed PoseFrame

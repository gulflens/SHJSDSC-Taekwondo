import Foundation
import AVFoundation
import Vision
import CoreMedia
import simd

// MARK: - PoomsaePoseExtractor
//
// Stage 2.6.a — the 3D pose extraction pipeline.
//
//   Input:  an AVURLAsset for a stored poomsae video.
//   Output: AsyncStream<PoseFrame>, one element per sampled frame.
//
// Pulls frames with AVAssetReader + AVAssetReaderTrackOutput, samples down to
// the configured rate (intermediate frames decoded and dropped), and runs
// VNDetectHumanBodyPose3DRequest on each sampled frame. Joints below the
// confidence threshold become nil (the key is kept). No-person frames yield
// an empty PoseFrame carrying the timestamp.
//
// Runs in a detached Task off the main actor; reports progress through a
// @Sendable (Double) -> Void callback. Only the asset URL crosses into the
// detached task, so there is no AVURLAsset Sendability concern.

// `nonisolated` — the extraction loop MUST run off the main actor (project
// default isolation is MainActor; without this the detached task would hop
// back to the main thread and block the UI during extraction).
public nonisolated struct PoomsaePoseExtractor: Sendable {

    public init() {}

    // MARK: - Public entry

    public func extractPoses(
        asset: AVURLAsset,
        parameters: SegmentationParameters = .default,
        progress: @escaping @Sendable (Double) -> Void
    ) -> AsyncStream<PoseFrame> {
        let url = asset.url
        let parameters = parameters
        return AsyncStream<PoseFrame> { continuation in
            let task = Task.detached(priority: .userInitiated) {
                await Self.run(
                    url: url,
                    parameters: parameters,
                    progress: progress,
                    continuation: continuation
                )
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Pipeline

    private static func run(
        url: URL,
        parameters: SegmentationParameters,
        progress: @Sendable (Double) -> Void,
        continuation: AsyncStream<PoseFrame>.Continuation
    ) async {
        let asset = AVURLAsset(url: url)

        guard let track = try? await asset.loadTracks(withMediaType: .video).first else {
            continuation.finish()
            return
        }
        let nominalFPS = (try? await track.load(.nominalFrameRate)) ?? 30
        let durationSeconds = (try? await asset.load(.duration))?.seconds ?? 0
        let transform = (try? await track.load(.preferredTransform)) ?? .identity
        let imageOrientation = orientation(from: transform)

        let targetFPS = max(1.0, parameters.sampleRate)
        let frameStride = max(1, Int((Double(nominalFPS) / targetFPS).rounded()))
        let estimatedSamples = max(1, Int((durationSeconds * targetFPS).rounded()))

        guard let reader = try? AVAssetReader(asset: asset) else {
            continuation.finish()
            return
        }
        let output = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        )
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else {
            continuation.finish()
            return
        }
        reader.add(output)
        guard reader.startReading() else {
            continuation.finish()
            return
        }

        let request = VNDetectHumanBodyPose3DRequest()
        var frameIndex = 0
        var sampledCount = 0

        while !Task.isCancelled,
              reader.status == .reading,
              let sample = output.copyNextSampleBuffer() {
            defer { frameIndex += 1 }
            guard frameIndex % frameStride == 0 else { continue }

            let time = CMSampleBufferGetPresentationTimeStamp(sample)
            let frame: PoseFrame
            if let pixelBuffer = CMSampleBufferGetImageBuffer(sample) {
                frame = poseFrame(
                    from: pixelBuffer,
                    orientation: imageOrientation,
                    time: time,
                    request: request,
                    parameters: parameters
                )
            } else {
                frame = PoseFrame.empty(at: time)
            }
            continuation.yield(frame)
            sampledCount += 1
            progress(min(1.0, Double(sampledCount) / Double(estimatedSamples)))
        }

        if reader.status == .reading { reader.cancelReading() }
        progress(1.0)
        continuation.finish()
    }

    // MARK: - Vision

    private static func poseFrame(
        from pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation,
        time: CMTime,
        request: VNDetectHumanBodyPose3DRequest,
        parameters: SegmentationParameters
    ) -> PoseFrame {
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [:]
        )
        do {
            try handler.perform([request])
        } catch {
            print("PoomsaePoseExtractor: Vision request failed —", error)
            return PoseFrame.empty(at: time)
        }
        guard let observation = request.results?.first else {
            return PoseFrame.empty(at: time)
        }

        var joints: [PoomsaeJoint: SIMD3<Float>?] = [:]
        var confidences: [PoomsaeJoint: Float] = [:]
        for joint in PoomsaeJoint.allCases {
            guard let visionJoint = joint.visionJointName,
                  let point = try? observation.recognizedPoint(visionJoint) else {
                joints.updateValue(nil, forKey: joint)
                confidences[joint] = 0
                continue
            }
            // VNDetectHumanBodyPose3DRequest exposes no per-joint confidence:
            // a resolved joint is treated as full confidence.
            let confidence: Float = 1.0
            if confidence >= parameters.jointConfidenceThreshold {
                let translation = point.position.columns.3
                joints.updateValue(
                    SIMD3<Float>(translation.x, translation.y, translation.z),
                    forKey: joint
                )
            } else {
                joints.updateValue(nil, forKey: joint)
            }
            confidences[joint] = confidence
        }
        return PoseFrame(timestamp: time, joints: joints, confidences: confidences)
    }

    // MARK: - Orientation

    /// Maps a video track's preferred transform to the image orientation Vision
    /// should analyse, covering the four right-angle rotations.
    private static func orientation(from t: CGAffineTransform) -> CGImagePropertyOrientation {
        switch (t.a.rounded(), t.b.rounded(), t.c.rounded(), t.d.rounded()) {
        case (0, 1, -1, 0):  return .right
        case (0, -1, 1, 0):  return .left
        case (-1, 0, 0, -1): return .down
        default:             return .up
        }
    }
}

// MARK: - PoomsaeJoint <-> Vision bridging
//
// Kept here, in the only Vision-importing file, so `PoomsaeJoint` itself stays
// framework-free and the pure segmenter / unit tests never link Vision types.

private extension PoomsaeJoint {
    // `nonisolated` — referenced from the off-main `poseFrame` builder
    // (extension members default to MainActor isolation in this project).
    nonisolated var visionJointName: VNHumanBodyPose3DObservation.JointName? {
        switch self {
        case .topHead:        return .topHead
        case .centerHead:     return .centerHead
        case .centerShoulder: return .centerShoulder
        case .leftShoulder:   return .leftShoulder
        case .rightShoulder:  return .rightShoulder
        case .leftElbow:      return .leftElbow
        case .rightElbow:     return .rightElbow
        case .leftWrist:      return .leftWrist
        case .rightWrist:     return .rightWrist
        case .spine:          return .spine
        case .root:           return .root
        case .leftHip:        return .leftHip
        case .rightHip:       return .rightHip
        case .leftKnee:       return .leftKnee
        case .rightKnee:      return .rightKnee
        case .leftAnkle:      return .leftAnkle
        case .rightAnkle:     return .rightAnkle
        }
    }
}

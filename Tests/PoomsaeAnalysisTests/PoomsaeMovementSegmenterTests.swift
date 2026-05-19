import Testing
import Foundation
@testable import SHJSDSC

// MARK: - PoomsaeMovementSegmenterTests
//
// Stage 2.6.a — the three required unit tests for the segmentation pipeline,
// run against deterministic synthetic pose data (see `SyntheticPose`).

@Suite("Poomsae movement segmentation")
struct PoomsaeMovementSegmenterTests {

    @Test("Motion energy is ~0 across an unchanging pose sequence")
    func motionEnergyOnStaticSequence() {
        let frames = SyntheticPose.frames(displacements: Array(repeating: 0, count: 30))
        let energy = PoomsaeMovementSegmenter.motionEnergy(frames: frames)

        #expect(energy.count == 30)
        for value in energy {
            #expect(abs(value) < 1e-4)
        }
    }

    @Test("Three synthetic motion pulses produce three segments")
    func segmentationOnSyntheticPulses() {
        let trajectory = SyntheticPose.pulseTrajectory(
            stillFrames: 15, pulseFrames: 15, pulses: 3, step: 0.1
        )
        let frames = SyntheticPose.frames(displacements: trajectory)
        let segments = PoomsaeMovementSegmenter.segment(frames: frames, parameters: .default)

        #expect(segments.count == 3)
        for (i, segment) in segments.enumerated() {
            #expect(segment.index == i)
            #expect(segment.endSeconds > segment.startSeconds)
            #expect(segment.peakMotionValue > 0)
            #expect(segment.peakMotionSeconds >= segment.startSeconds)
            #expect(segment.peakMotionSeconds <= segment.endSeconds)
        }
    }

    @Test("Segments shorter than the minimum duration are merged")
    func minimumDurationMerging() {
        let trajectory = SyntheticPose.pulseTrajectory(
            stillFrames: 15, pulseFrames: 15, pulses: 3, step: 0.1
        )
        let frames = SyntheticPose.frames(displacements: trajectory)

        // Default parameters keep the three pulses as three segments.
        let normal = PoomsaeMovementSegmenter.segment(frames: frames, parameters: .default)
        #expect(normal.count == 3)

        // A minimum-segment duration longer than the whole clip forces every
        // segment to merge into a single one.
        var collapsing = SegmentationParameters.default
        collapsing.minSegmentDuration = 100_000
        let collapsed = PoomsaeMovementSegmenter.segment(frames: frames, parameters: collapsing)
        #expect(collapsed.count == 1)
    }
}

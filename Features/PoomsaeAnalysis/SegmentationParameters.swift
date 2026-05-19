import Foundation

// MARK: - SegmentationParameters
//
// Stage 2.6.a — every tunable constant of the pose + segmentation pipeline,
// gathered in one struct with a `.default` instance so tuning happens in a
// single place and unit tests can inject variants.

// `nonisolated` — read inside the off-main extraction pipeline and the pure
// segmenter (project default isolation is MainActor).
public nonisolated struct SegmentationParameters: Sendable, Equatable {

    /// Frames analysed per second. Poomsae techniques are deliberate
    /// (~1-3 s each), so 15 fps captures each technique's onset, peak and
    /// settle at roughly half the Vision cost of 30 fps.
    public var sampleRate: Double

    /// Joint inclusion cutoff. The 3D-only pipeline yields confidence 1.0 for
    /// resolved joints and 0.0 otherwise, so this admits resolved joints and
    /// rejects unresolved ones.
    public var jointConfidenceThreshold: Float

    /// Width (in samples, odd) of the centred rolling-mean applied to the
    /// motion-energy curve. 5 samples is ~0.33 s at 15 fps.
    public var smoothingWindow: Int

    /// Pause threshold expressed as a fraction of the per-clip energy range:
    /// `threshold = floor + pauseFraction * (peak - floor)`. Relative rather
    /// than absolute so it is robust to performer size / camera distance.
    public var pauseFraction: Double

    /// Minimum duration (seconds) of a sub-threshold dip for it to count as a
    /// pause boundary — shorter dips are treated as noise.
    public var minPauseDuration: Double

    /// Minimum movement duration (seconds). Shorter segments are merged into
    /// the following segment.
    public var minSegmentDuration: Double

    public init(
        sampleRate: Double = 15,
        jointConfidenceThreshold: Float = 0.3,
        smoothingWindow: Int = 5,
        pauseFraction: Double = 0.15,
        minPauseDuration: Double = 0.20,
        minSegmentDuration: Double = 0.40
    ) {
        self.sampleRate = sampleRate
        self.jointConfidenceThreshold = jointConfidenceThreshold
        self.smoothingWindow = smoothingWindow
        self.pauseFraction = pauseFraction
        self.minPauseDuration = minPauseDuration
        self.minSegmentDuration = minSegmentDuration
    }

    /// The shipped defaults — the single place to tune the pipeline.
    public static let `default` = SegmentationParameters()
}

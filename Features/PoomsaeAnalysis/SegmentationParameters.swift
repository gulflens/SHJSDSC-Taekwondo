import Foundation

// MARK: - SegmentationParameters
//
// Stage 2.6.a — every tunable constant of the pose + segmentation pipeline,
// gathered in one struct with a `.default` instance so tuning happens in a
// single place and unit tests can inject variants.
//
//   sampleRate               15 fps   — frames analysed per second
//   jointConfidenceThreshold 0.3      — joint inclusion cutoff
//   smoothingWindow          5        — centred rolling-mean width (odd)
//   pauseFraction            0.15     — pause threshold as a fraction of the
//                                       per-clip energy range
//   minPauseDuration         0.20 s   — shorter dips are not boundaries
//   minSegmentDuration       0.40 s   — shorter segments merge into the next

// MARK: - SegmentationParameters

// MARK: - .default

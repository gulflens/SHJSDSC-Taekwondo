import Foundation
import CoreMedia
import simd

// MARK: - PoomsaeMovementSegmenter
//
// Stage 2.6.a — segments a `[PoseFrame]` sequence into discrete movements.
//
// Pure value-level logic (Foundation + CoreMedia + simd only — no Vision, no
// AVFoundation), so it is fully unit-testable against synthetic pose data.
// `nonisolated` so it runs off the main actor and is callable from tests
// under the project's MainActor default isolation.
//
// Pipeline:
//   1. Motion energy E(t) — confidence-weighted sum of per-joint Euclidean
//      displacement between consecutive frames.
//   2. Smooth E with a centred rolling mean (smoothingWindow).
//   3. Adaptive pause threshold = floor + pauseFraction * (peak - floor),
//      floor/peak from the 5th / 95th percentile of the smoothed curve.
//   4. Coalesce sub-threshold runs into pauses (>= minPauseDuration); each
//      pause's argmin is a boundary. Movements are the spans between
//      consecutive boundaries (clip start and end are implicit boundaries).
//   5. Merge any segment shorter than minSegmentDuration into the next.

public nonisolated enum PoomsaeMovementSegmenter {

    // MARK: - Motion energy

    /// Per-frame motion energy. `energy[0]` is 0 (no predecessor); `energy[i]`
    /// is the confidence-weighted joint displacement from frame `i-1` to `i`.
    public static func motionEnergy(frames: [PoseFrame]) -> [Float] {
        guard frames.count > 1 else { return frames.isEmpty ? [] : [0] }
        var energy = [Float](repeating: 0, count: frames.count)
        for i in 1..<frames.count {
            energy[i] = frameEnergy(from: frames[i - 1], to: frames[i])
        }
        return energy
    }

    /// Confidence-weighted sum of per-joint displacement between two frames.
    /// Joints unresolved (nil) in either frame are skipped.
    private static func frameEnergy(from previous: PoseFrame, to current: PoseFrame) -> Float {
        var sum: Float = 0
        for joint in PoomsaeJoint.allCases {
            guard let p0 = previous.position(for: joint),
                  let p1 = current.position(for: joint) else { continue }
            let weight = (previous.confidence(for: joint) + current.confidence(for: joint)) / 2
            sum += weight * simd_distance(p0, p1)
        }
        return sum
    }

    // MARK: - Smoothing

    /// Centred rolling mean over `window` samples (clamped, edges use a
    /// shrinking symmetric window). A window of 1 or less passes through.
    public static func smooth(_ values: [Float], window: Int) -> [Float] {
        guard !values.isEmpty else { return [] }
        let half = max(0, window / 2)
        guard half >= 1 else { return values }
        var out = [Float](repeating: 0, count: values.count)
        for i in values.indices {
            let lo = max(0, i - half)
            let hi = min(values.count - 1, i + half)
            var sum: Float = 0
            for j in lo...hi { sum += values[j] }
            out[i] = sum / Float(hi - lo + 1)
        }
        return out
    }

    // MARK: - Segmentation

    /// Segments a pose sequence into movements. Returns an empty array for
    /// fewer than two frames.
    public static func segment(
        frames: [PoseFrame],
        parameters: SegmentationParameters = .default
    ) -> [MovementSegment] {
        guard frames.count > 1 else { return [] }

        let times = frames.map { $0.timestamp.seconds.isFinite ? $0.timestamp.seconds : 0 }
        let rawEnergy = motionEnergy(frames: frames)
        let smoothed = smooth(rawEnergy, window: parameters.smoothingWindow)
        let threshold = pauseThreshold(for: smoothed, fraction: parameters.pauseFraction)

        let boundaries = boundaryIndices(
            smoothed: smoothed,
            times: times,
            threshold: threshold,
            minPauseDuration: parameters.minPauseDuration
        )

        var ranges: [(start: Int, end: Int)] = []
        for k in 0..<(boundaries.count - 1) {
            ranges.append((boundaries[k], boundaries[k + 1]))
        }
        guard !ranges.isEmpty else { return [] }

        let merged = mergeShortRanges(ranges, times: times, minDuration: parameters.minSegmentDuration)

        return merged.enumerated().map { index, range in
            let peak = peakEnergy(in: rawEnergy, start: range.start, end: range.end)
            return MovementSegment(
                index: index,
                startSeconds: times[range.start],
                endSeconds: times[range.end],
                peakMotionSeconds: times[peak.index],
                peakMotionValue: peak.value
            )
        }
    }

    // MARK: - Threshold

    /// Adaptive pause threshold, relative to the per-clip energy range so it
    /// is robust to performer size / camera distance.
    private static func pauseThreshold(for smoothed: [Float], fraction: Double) -> Float {
        guard !smoothed.isEmpty else { return 0 }
        let sorted = smoothed.sorted()
        let floor = percentile(sorted, 0.05)
        let peak = percentile(sorted, 0.95)
        return floor + Float(fraction) * (peak - floor)
    }

    private static func percentile(_ sorted: [Float], _ p: Double) -> Float {
        guard !sorted.isEmpty else { return 0 }
        let idx = Int((Double(sorted.count - 1) * p).rounded())
        return sorted[min(max(0, idx), sorted.count - 1)]
    }

    // MARK: - Boundaries

    /// Clip start (0), clip end (n-1) and the argmin of every qualifying
    /// pause run — sorted and de-duplicated.
    private static func boundaryIndices(
        smoothed: [Float],
        times: [Double],
        threshold: Float,
        minPauseDuration: Double
    ) -> [Int] {
        let n = smoothed.count
        var boundaries: [Int] = [0, n - 1]
        var runStart: Int?

        func closeRun(endingAt end: Int) {
            guard let start = runStart else { return }
            runStart = nil
            guard times[end] - times[start] >= minPauseDuration else { return }
            var minIndex = start
            for j in start...end where smoothed[j] < smoothed[minIndex] { minIndex = j }
            boundaries.append(minIndex)
        }

        for i in 0..<n {
            if smoothed[i] < threshold {
                if runStart == nil { runStart = i }
            } else if runStart != nil {
                closeRun(endingAt: i - 1)
            }
        }
        if runStart != nil { closeRun(endingAt: n - 1) }

        return Array(Set(boundaries)).sorted()
    }

    // MARK: - Merge

    /// Merges any range shorter than `minDuration` into the following range
    /// (a trailing short range merges into the previous one).
    private static func mergeShortRanges(
        _ ranges: [(start: Int, end: Int)],
        times: [Double],
        minDuration: Double
    ) -> [(start: Int, end: Int)] {
        func duration(_ r: (start: Int, end: Int)) -> Double { times[r.end] - times[r.start] }

        var result: [(start: Int, end: Int)] = []
        var pending: (start: Int, end: Int)?

        for r in ranges {
            if var carried = pending {
                carried.end = r.end
                if duration(carried) >= minDuration {
                    result.append(carried)
                    pending = nil
                } else {
                    pending = carried
                }
            } else if duration(r) < minDuration {
                pending = r
            } else {
                result.append(r)
            }
        }
        if let carried = pending {
            if result.isEmpty {
                result.append(carried)
            } else {
                result[result.count - 1].end = carried.end
            }
        }
        return result
    }

    // MARK: - Peak

    /// Index and value of the maximum raw energy within `[start, end]`.
    private static func peakEnergy(in energy: [Float], start: Int, end: Int) -> (index: Int, value: Float) {
        var bestIndex = start
        var bestValue = energy[start]
        if start <= end {
            for j in start...end where energy[j] > bestValue {
                bestValue = energy[j]
                bestIndex = j
            }
        }
        return (bestIndex, bestValue)
    }
}

#if os(iOS)
import SwiftUI
import CoreMedia

// MARK: - PoomsaeAnalysisKit
//
// Stage 2.6.a — small shared UI for the Poomsae Analysis module, following
// the app's `*Kit.swift` convention. Reuses the existing colour and
// typography tokens — no new design primitives.

// MARK: - ExtractionProgressView
//
// Overlaid on the player while poses are being extracted / segmented, or to
// surface an extraction failure.

struct ExtractionProgressView: View {

    let phase: PoomsaeAnalysisStore.Phase
    let progress: Double

    var body: some View {
        VStack(spacing: 12) {
            switch phase {
            case .extracting:
                ProgressView(value: progress) {
                    Text("Extracting poses")
                }
                .frame(width: 220)
                .tint(.accentColor)
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            case .segmenting:
                ProgressView {
                    Text("Detecting movements")
                }
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .idle, .ready:
                EmptyView()
            }
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - SegmentDebugMetrics
//
// Raw per-segment metrics shown in the long-press debug popover (Task 6).

struct SegmentDebugMetrics {
    let durationSeconds: Double
    let peakMotionValue: Float
    let frameCount: Int
    let averageJointCount: Double
    let meanConfidence: Double

    /// Computes the metrics for a segment from the pose frames that fall
    /// within its time span.
    static func compute(for segment: MovementSegment, frames: [PoseFrame]) -> SegmentDebugMetrics {
        let inSegment = frames.filter { frame in
            let t = frame.timestamp.seconds
            return t >= segment.startSeconds && t <= segment.endSeconds
        }
        let jointTotal = inSegment.reduce(0) { $0 + $1.detectedJointCount }
        var confidenceSum = 0.0
        var confidenceCount = 0
        for frame in inSegment {
            for joint in PoomsaeJoint.allCases {
                confidenceSum += Double(frame.confidence(for: joint))
                confidenceCount += 1
            }
        }
        return SegmentDebugMetrics(
            durationSeconds: segment.durationSeconds,
            peakMotionValue: segment.peakMotionValue,
            frameCount: inSegment.count,
            averageJointCount: inSegment.isEmpty ? 0 : Double(jointTotal) / Double(inSegment.count),
            meanConfidence: confidenceCount == 0 ? 0 : confidenceSum / Double(confidenceCount)
        )
    }
}

// MARK: - SegmentDebugPopover

struct SegmentDebugPopover: View {

    let segment: MovementSegment
    let metrics: SegmentDebugMetrics?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Movement \(segment.index + 1) — debug")
                .font(.headline)
            Divider()
            metricRow("Duration", String(format: "%.2f s", segment.durationSeconds))
            metricRow("Peak motion", String(format: "%.3f", segment.peakMotionValue))
            metricRow("Peak at", analysisTimecode(segment.peakMotionSeconds))
            if let metrics {
                metricRow("Frames", "\(metrics.frameCount)")
                metricRow("Avg joints", String(format: "%.1f / 17", metrics.averageJointCount))
                metricRow("Mean confidence", String(format: "%.2f", metrics.meanConfidence))
            }
        }
        .padding(16)
        .frame(minWidth: 250)
    }

    private func metricRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value).monospacedDigit()
        }
        .font(.subheadline)
    }
}

// MARK: - Formatting

/// Formats a duration in seconds as `m:ss` (numbers stay LTR-safe).
func analysisTimecode(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "0:00" }
    let total = Int(seconds.rounded())
    return String(format: "%d:%02d", total / 60, total % 60)
}
#endif

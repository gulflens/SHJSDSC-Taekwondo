#if os(iOS)
import SwiftUI

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

// MARK: - Formatting

/// Formats a duration in seconds as `m:ss` (numbers stay LTR-safe).
func analysisTimecode(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "0:00" }
    let total = Int(seconds.rounded())
    return String(format: "%d:%02d", total / 60, total % 60)
}
#endif

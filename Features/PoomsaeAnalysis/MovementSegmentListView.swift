#if os(iOS)
import SwiftUI

// MARK: - MovementSegmentListView
//
// Stage 2.6.a — the segment list: a collapsible side panel on iPad, a sheet
// on iPhone. One row per `MovementSegment`, showing its 1-based number,
// time span and peak motion value. Tapping a row seeks the player; a
// long-press shows a debug popover with raw metrics (Task 6).

struct MovementSegmentListView: View {

    let segments: [MovementSegment]
    var onSelect: (MovementSegment) -> Void = { _ in }

    var body: some View {
        if segments.isEmpty {
            ContentUnavailableView(
                "No Movements",
                systemImage: "figure.cooldown",
                description: Text("Segmented movements will appear here once analysis finishes.")
            )
        } else {
            List(segments) { segment in
                Button {
                    onSelect(segment)
                } label: {
                    SegmentRow(segment: segment)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - SegmentRow

struct SegmentRow: View {

    let segment: MovementSegment

    var body: some View {
        HStack(spacing: 12) {
            Text("\(segment.index + 1)")
                .font(.headline.monospacedDigit())
                .frame(width: 34, height: 34)
                .background(Color.accentColor.opacity(0.15), in: Circle())
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Movement \(segment.index + 1)")
                    .font(.subheadline.weight(.semibold))
                Text("\(analysisTimecode(segment.startSeconds)) – \(analysisTimecode(segment.endSeconds))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f", segment.peakMotionValue))
                    .font(.caption.monospacedDigit())
                Text("peak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
#endif

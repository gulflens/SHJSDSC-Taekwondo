#if os(iOS)
import SwiftUI
import CoreMedia

// MARK: - MotionEnergyTimelineView
//
// Stage 2.6.a — the horizontal timeline beneath the video player.
//
// Draws the smoothed motion-energy curve, vertical dividers at each
// `MovementSegment` boundary, a peak-motion dot above each segment, and a
// movable playhead bound to the player's current time.
//
// `onSeek` / `onSeekToPeak` are wired by the analysis view for tap-to-seek
// (Task 6); the divider / peak hit-targets are computed here.

struct MotionEnergyTimelineView: View {

    let frames: [PoseFrame]
    let energy: [Float]
    let segments: [MovementSegment]
    let duration: Double
    let currentTime: Double
    var onSeek: (Double) -> Void = { _ in }
    var onSeekToPeak: (MovementSegment) -> Void = { _ in }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    draw(in: context, size: size)
                }
                // Peak-motion tap targets (small dots above each segment).
                ForEach(segments) { segment in
                    Circle()
                        .fill(Color.secondaryAccent)
                        .frame(width: 12, height: 12)
                        .contentShape(Rectangle().size(width: 28, height: 28))
                        .position(x: x(segment.peakMotionSeconds, width: width), y: 7)
                        .onTapGesture { onSeekToPeak(segment) }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                guard duration > 0, width > 0 else { return }
                let tapped = Double(location.x / width) * duration
                // Snap to a segment boundary when the tap lands near one
                // (tapping a divider seeks to that segment's start).
                var boundaries = segments.map(\.startSeconds)
                if let last = segments.last { boundaries.append(last.endSeconds) }
                let snapWindow = duration * 0.02
                if let nearest = boundaries.min(by: { abs($0 - tapped) < abs($1 - tapped) }),
                   abs(nearest - tapped) <= snapWindow {
                    onSeek(nearest)
                } else {
                    onSeek(tapped)
                }
            }
            .frame(height: height)
        }
        .frame(height: 96)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Geometry

    private func x(_ time: Double, width: CGFloat) -> CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(min(1, max(0, time / duration))) * width
    }

    // MARK: - Drawing

    private func draw(in context: GraphicsContext, size: CGSize) {
        guard duration > 0 else { return }
        let maxEnergy = max(0.0001, Double(energy.max() ?? 0))

        // Smoothed motion-energy curve.
        var curve = Path()
        var started = false
        for (i, value) in energy.enumerated() where i < frames.count {
            let px = x(frames[i].timestamp.seconds, width: size.width)
            let py = size.height - CGFloat(Double(value) / maxEnergy) * (size.height - 16) - 8
            if started {
                curve.addLine(to: CGPoint(x: px, y: py))
            } else {
                curve.move(to: CGPoint(x: px, y: py))
                started = true
            }
        }
        context.stroke(curve, with: .color(.accentColor), lineWidth: 2)

        // Segment boundary dividers (each segment start, plus the final end).
        var boundaries = segments.map(\.startSeconds)
        if let last = segments.last { boundaries.append(last.endSeconds) }
        for boundary in boundaries {
            let bx = x(boundary, width: size.width)
            var divider = Path()
            divider.move(to: CGPoint(x: bx, y: 0))
            divider.addLine(to: CGPoint(x: bx, y: size.height))
            context.stroke(
                divider,
                with: .color(.secondary.opacity(0.55)),
                style: StrokeStyle(lineWidth: 1, dash: [3, 3])
            )
        }

        // Playhead.
        let phx = x(currentTime, width: size.width)
        var playhead = Path()
        playhead.move(to: CGPoint(x: phx, y: 0))
        playhead.addLine(to: CGPoint(x: phx, y: size.height))
        context.stroke(playhead, with: .color(.primary), lineWidth: 2)
    }
}
#endif

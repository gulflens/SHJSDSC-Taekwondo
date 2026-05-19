#if os(iOS)
import SwiftUI
import simd
import CoreMedia

// MARK: - PoseProjection
//
// Stage 2.6.a — an orthographic projection of 3D joint positions onto the
// overlay canvas. The 3D-only pipeline carries no real image-space points, so
// joints are projected by their X/Y (Vision Y is up; screen Y is down). A
// single bound is computed across the whole clip so the skeleton does not
// rescale frame to frame.

struct PoseProjection {

    let minX: Float
    let maxX: Float
    let minY: Float
    let maxY: Float

    /// Whole-clip XY bounds of every resolved joint, or `nil` if no joint was
    /// ever resolved.
    static func bounds(of frames: [PoseFrame]) -> PoseProjection? {
        var minX = Float.greatestFiniteMagnitude
        var maxX = -Float.greatestFiniteMagnitude
        var minY = Float.greatestFiniteMagnitude
        var maxY = -Float.greatestFiniteMagnitude
        var found = false
        for frame in frames {
            for joint in PoomsaeJoint.allCases {
                guard let p = frame.position(for: joint) else { continue }
                found = true
                minX = min(minX, p.x); maxX = max(maxX, p.x)
                minY = min(minY, p.y); maxY = max(maxY, p.y)
            }
        }
        guard found else { return nil }
        return PoseProjection(minX: minX, maxX: maxX, minY: minY, maxY: maxY)
    }

    /// Projects a 3D joint position into `rect`, preserving aspect ratio and
    /// centring the skeleton.
    func point(_ p: SIMD3<Float>, in rect: CGRect) -> CGPoint {
        let spanX = max(0.001, maxX - minX)
        let spanY = max(0.001, maxY - minY)
        let scale = min(rect.width / CGFloat(spanX), rect.height / CGFloat(spanY))
        let drawW = CGFloat(spanX) * scale
        let drawH = CGFloat(spanY) * scale
        let originX = rect.midX - drawW / 2
        let originY = rect.midY - drawH / 2
        let nx = CGFloat(p.x - minX) * scale
        let ny = drawH - CGFloat(p.y - minY) * scale   // flip: Vision Y is up
        return CGPoint(x: originX + nx, y: originY + ny)
    }
}

// MARK: - PoomsaeSkeletonOverlay
//
// Stage 2.6.a — a `Canvas` overlay drawing the 3D body pose for the frame at
// the player's current time. Bones follow `PoseTopology`; resolved joints
// render solid, unresolved joints are omitted.

struct PoomsaeSkeletonOverlay: View {

    let frames: [PoseFrame]
    let projection: PoseProjection?
    let currentTime: Double

    var body: some View {
        Canvas { context, size in
            guard let projection, let frame = nearestFrame(to: currentTime) else { return }
            let rect = CGRect(origin: .zero, size: size)
                .insetBy(dx: size.width * 0.12, dy: size.height * 0.08)

            for (jointA, jointB) in PoseTopology.bones {
                guard let a = frame.position(for: jointA),
                      let b = frame.position(for: jointB) else { continue }
                var bone = Path()
                bone.move(to: projection.point(a, in: rect))
                bone.addLine(to: projection.point(b, in: rect))
                context.stroke(
                    bone,
                    with: .color(.accentColor),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
            }

            for joint in PoomsaeJoint.allCases {
                guard let p = frame.position(for: joint) else { continue }
                let centre = projection.point(p, in: rect)
                let dot = Path(ellipseIn: CGRect(x: centre.x - 4, y: centre.y - 4, width: 8, height: 8))
                context.fill(dot, with: .color(.white))
                context.stroke(dot, with: .color(.accentColor), lineWidth: 2)
            }
        }
        .allowsHitTesting(false)
    }

    /// Binary-searches the pose frame nearest `time` (frames are time-ordered).
    private func nearestFrame(to time: Double) -> PoseFrame? {
        guard !frames.isEmpty else { return nil }
        var low = 0
        var high = frames.count - 1
        while low < high {
            let mid = (low + high) / 2
            if frames[mid].timestamp.seconds < time {
                low = mid + 1
            } else {
                high = mid
            }
        }
        if low > 0 {
            let previous = frames[low - 1].timestamp.seconds
            let current = frames[low].timestamp.seconds
            if abs(previous - time) <= abs(current - time) { return frames[low - 1] }
        }
        return frames[low]
    }
}
#endif

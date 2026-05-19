import Foundation
import CoreMedia

// MARK: - MovementSegment
//
// Stage 2.6.a — one discrete movement carved out of a poomsae performance by
// `PoomsaeMovementSegmenter`. Pure `Codable` struct, embedded on
// `PoomsaeRecording`.
//
// `CMTime` is not `Codable`, so the boundary times are stored as `Double`
// seconds and re-exposed as computed `CMTime` accessors to match the
// brief-facing API (`startTime` / `endTime` / `peakMotionTime`).

public struct MovementSegment: Codable, Identifiable, Hashable, Sendable {

    // MARK: - Stored fields

    /// 0-based position of this movement within the performance.
    public var index: Int
    /// Segment start, in seconds from the start of the video.
    public var startSeconds: Double
    /// Segment end, in seconds from the start of the video.
    public var endSeconds: Double
    /// Time of maximum motion energy within the segment, in seconds.
    public var peakMotionSeconds: Double
    /// The motion-energy value at `peakMotionSeconds`.
    public var peakMotionValue: Float

    public var id: Int { index }

    public init(
        index: Int,
        startSeconds: Double,
        endSeconds: Double,
        peakMotionSeconds: Double,
        peakMotionValue: Float
    ) {
        self.index = index
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
        self.peakMotionSeconds = peakMotionSeconds
        self.peakMotionValue = peakMotionValue
    }

    // MARK: - CMTime accessors

    private static let timescale: CMTimeScale = 600

    /// Segment start as `CMTime` — convenient for `AVPlayer` seeking.
    public var startTime: CMTime {
        CMTime(seconds: startSeconds, preferredTimescale: Self.timescale)
    }

    /// Segment end as `CMTime`.
    public var endTime: CMTime {
        CMTime(seconds: endSeconds, preferredTimescale: Self.timescale)
    }

    /// Time of peak motion as `CMTime`.
    public var peakMotionTime: CMTime {
        CMTime(seconds: peakMotionSeconds, preferredTimescale: Self.timescale)
    }

    /// Segment length in seconds.
    public var durationSeconds: Double { max(0, endSeconds - startSeconds) }
}

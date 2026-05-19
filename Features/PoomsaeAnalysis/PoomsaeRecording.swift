import Foundation
import CoreGraphics

// MARK: - PoomsaeRecording
//
// Stage 2.6.a — Poomsae Pose Extraction & Movement Segmentation.
//
// Top-level record for one imported poomsae video. Pure `Codable` struct
// (no SwiftData — honours the CLAUDE.md "models are pure Codable structs"
// hard rule). Persisted in the `recordings.json` index by `PoomsaeFileStore`.
//
// Per-frame pose data is NOT stored here — it lives in a separate binary
// cache file referenced by `poseCacheFilename`. The segmented movements ARE
// embedded (`segments`), following the app's embedded-dossier pattern: they
// are few, small, and always queried alongside their parent recording.

public struct PoomsaeRecording: Codable, Identifiable, Hashable, Sendable {

    // MARK: - Stored fields

    public let id: UUID
    /// The filename the video had in the Photos library, shown to the user.
    public var originalFilename: String
    /// The UUID-based filename of the copy inside the app sandbox.
    public var storedFilename: String
    public var importedAt: Date
    public var durationSeconds: Double
    /// Display size of the video (natural size with the preferred transform
    /// applied), in pixels.
    public var videoSize: CGSize
    /// Filename of the binary pose cache, once extraction has run. `nil`
    /// before the first extraction.
    public var poseCacheFilename: String?
    /// Movements segmented from the performance. Empty before segmentation.
    public var segments: [MovementSegment]

    public init(
        id: UUID = UUID(),
        originalFilename: String,
        storedFilename: String,
        importedAt: Date = Date(),
        durationSeconds: Double,
        videoSize: CGSize,
        poseCacheFilename: String? = nil,
        segments: [MovementSegment] = []
    ) {
        self.id = id
        self.originalFilename = originalFilename
        self.storedFilename = storedFilename
        self.importedAt = importedAt
        self.durationSeconds = durationSeconds
        self.videoSize = videoSize
        self.poseCacheFilename = poseCacheFilename
        self.segments = segments
    }

    /// `true` once a pose cache has been written for this recording.
    public var hasPoseCache: Bool { poseCacheFilename != nil }

    // MARK: - Codable
    //
    // Custom decoder so newly added fields (`poseCacheFilename`, `segments`)
    // stay backward-compatible with any index written before they existed —
    // the app's embedded-dossier pattern. `encode(to:)` is synthesised.

    private enum CodingKeys: String, CodingKey {
        case id, originalFilename, storedFilename, importedAt
        case durationSeconds, videoSize, poseCacheFilename, segments
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        originalFilename = try c.decode(String.self, forKey: .originalFilename)
        storedFilename = try c.decode(String.self, forKey: .storedFilename)
        importedAt = try c.decode(Date.self, forKey: .importedAt)
        durationSeconds = try c.decode(Double.self, forKey: .durationSeconds)
        videoSize = try c.decode(CGSize.self, forKey: .videoSize)
        poseCacheFilename = try c.decodeIfPresent(String.self, forKey: .poseCacheFilename)
        segments = try c.decodeIfPresent([MovementSegment].self, forKey: .segments) ?? []
    }
}

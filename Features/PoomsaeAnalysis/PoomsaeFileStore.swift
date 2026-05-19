import Foundation

// MARK: - PoomsaeFileStore
//
// Stage 2.6.a — the feature-local persistence actor (the Repository-pattern
// equivalent for this module; the global `Repository` protocol in Core/ is
// intentionally left untouched).
//
// Owns the sandbox layout:
//
//   Documents/PoomsaeAnalysis/
//     recordings.json            index { version, recordings: [PoomsaeRecording] }
//     Videos/<uuid>.mov          copied source videos (excluded from backup)
//     PoseCache/<uuid>.poses     binary pose cache (see PoseCacheCodec)
//
// `actor` for safe concurrent access; all I/O is async off the main actor.

public actor PoomsaeFileStore {

    /// Versioned index file payload — the lightweight forward-migration hook
    /// that stands in for a SwiftData schema version.
    private struct RecordingIndex: Codable {
        var version: Int
        var recordings: [PoomsaeRecording]
    }

    private static let currentIndexVersion = 1

    private let fileManager = FileManager.default

    public init() {}

    // MARK: - Directory layout

    private func rootDirectory() throws -> URL {
        let documents = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return documents.appendingPathComponent("PoomsaeAnalysis", isDirectory: true)
    }

    private func videosDirectory() throws -> URL {
        try rootDirectory().appendingPathComponent("Videos", isDirectory: true)
    }

    private func poseCacheDirectory() throws -> URL {
        try rootDirectory().appendingPathComponent("PoseCache", isDirectory: true)
    }

    private func indexURL() throws -> URL {
        try rootDirectory().appendingPathComponent("recordings.json")
    }

    /// Creates the module's directories on first use. `Videos/` is flagged
    /// excluded-from-backup so imported clips do not bloat iCloud backups.
    private func ensureDirectories() throws {
        try fileManager.createDirectory(at: rootDirectory(), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: poseCacheDirectory(), withIntermediateDirectories: true)

        var videos = try videosDirectory()
        try fileManager.createDirectory(at: videos, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? videos.setResourceValues(values)
    }

    // MARK: - URL resolution

    /// Absolute URL of a recording's stored video file.
    public func videoURL(for recording: PoomsaeRecording) throws -> URL {
        try videosDirectory().appendingPathComponent(recording.storedFilename)
    }

    /// Absolute URL of a pose-cache file by filename.
    public func poseCacheURL(filename: String) throws -> URL {
        try poseCacheDirectory().appendingPathComponent(filename)
    }

    // MARK: - Index

    /// Loads the recording index. Returns an empty array when no index has
    /// been written yet, or when the existing index cannot be decoded.
    public func loadRecordings() throws -> [PoomsaeRecording] {
        let url = try indexURL()
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            let index = try JSONDecoder().decode(RecordingIndex.self, from: data)
            return index.recordings
        } catch {
            print("PoomsaeFileStore.loadRecordings: corrupt index —", error)
            return []
        }
    }

    /// Inserts or replaces a recording in the index (matched by `id`).
    public func upsert(_ recording: PoomsaeRecording) throws {
        try ensureDirectories()
        var recordings = try loadRecordings()
        if let idx = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[idx] = recording
        } else {
            recordings.append(recording)
        }
        try writeIndex(recordings)
    }

    /// Removes a recording from the index and deletes its video + pose cache.
    public func delete(id: UUID) throws {
        var recordings = try loadRecordings()
        guard let idx = recordings.firstIndex(where: { $0.id == id }) else { return }
        let recording = recordings.remove(at: idx)

        let video = try videosDirectory().appendingPathComponent(recording.storedFilename)
        try? fileManager.removeItem(at: video)
        if let cache = recording.poseCacheFilename {
            try? fileManager.removeItem(at: poseCacheURL(filename: cache))
        }
        try writeIndex(recordings)
    }

    private func writeIndex(_ recordings: [PoomsaeRecording]) throws {
        try ensureDirectories()
        let index = RecordingIndex(version: Self.currentIndexVersion, recordings: recordings)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(index)
        try data.write(to: indexURL(), options: .atomic)
    }

    // MARK: - Video files

    /// Copies an imported movie into `Videos/` under its stored filename,
    /// replacing any existing file with that name.
    public func importVideoFile(from source: URL, storedFilename: String) throws {
        try ensureDirectories()
        let dest = try videosDirectory().appendingPathComponent(storedFilename)
        if fileManager.fileExists(atPath: dest.path) {
            try fileManager.removeItem(at: dest)
        }
        try fileManager.copyItem(at: source, to: dest)
    }

    /// Deletes a stored video file — used to roll back a failed import.
    public func deleteVideoFile(storedFilename: String) throws {
        let url = try videosDirectory().appendingPathComponent(storedFilename)
        try? fileManager.removeItem(at: url)
    }

    // MARK: - Pose cache
    //
    // Read/write of the binary pose cache. Encoding/decoding of the
    // `[PoseFrame]` payload itself lives in `PoseCacheCodec`.

    /// Writes pose-cache bytes for a recording, returning the filename to
    /// store on `PoomsaeRecording.poseCacheFilename`.
    public func writePoseCache(_ data: Data, recordingID: UUID) throws -> String {
        try ensureDirectories()
        let filename = "\(recordingID.uuidString).poses"
        try data.write(to: poseCacheURL(filename: filename), options: .atomic)
        return filename
    }

    /// Reads pose-cache bytes by filename, or `nil` when the file is absent.
    public func readPoseCache(filename: String) throws -> Data? {
        let url = try poseCacheURL(filename: filename)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }
}

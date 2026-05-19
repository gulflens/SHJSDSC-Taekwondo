import Foundation
import AVFoundation
import CoreTransferable
import UniformTypeIdentifiers

// MARK: - PoomsaeVideoImporter
//
// Stage 2.6.a — turns a movie picked from the Photos library into a persisted
// `PoomsaeRecording`.
//
// Steps:
//   1. Receive a movie file URL (from a PhotosPicker `Transferable`).
//   2. Validate it as a readable `AVURLAsset` with a video track; read
//      duration and natural video size.
//   3. Copy it into the sandbox via `PoomsaeFileStore`.
//   4. Build, persist and return a `PoomsaeRecording`.
//
// On any failure the partial copy is cleaned up and an error is thrown for
// the UI to surface.

// MARK: - ImportedMovie
//
// `Transferable` movie-file helper for `PhotosPicker`. The file handed to the
// `importing` closure is only valid for the duration of that closure, so it is
// copied into our own temporary location; the importer cleans that up once
// the video is safely inside the sandbox.

public struct ImportedMovie: Transferable, Sendable {

    public let url: URL
    public let originalFilename: String

    public init(url: URL, originalFilename: String) {
        self.url = url
        self.originalFilename = originalFilename
    }

    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let original = received.file.lastPathComponent
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(ext)
            try FileManager.default.copyItem(at: received.file, to: temp)
            return ImportedMovie(url: temp, originalFilename: original)
        }
    }
}

// MARK: - PoomsaeImportError

public enum PoomsaeImportError: LocalizedError {
    case unreadableAsset
    case noVideoTrack
    case copyFailed

    public var errorDescription: String? {
        switch self {
        case .unreadableAsset: "This video could not be read."
        case .noVideoTrack:    "The selected file has no video track."
        case .copyFailed:      "The video could not be saved to the app."
        }
    }
}

// MARK: - PoomsaeVideoImporter

public struct PoomsaeVideoImporter: Sendable {

    private let fileStore: PoomsaeFileStore

    public init(fileStore: PoomsaeFileStore) {
        self.fileStore = fileStore
    }

    /// Validates, copies and persists a picked movie. Throws
    /// `PoomsaeImportError` on failure, leaving no partial files behind.
    public func importMovie(_ movie: ImportedMovie) async throws -> PoomsaeRecording {
        // Always clear the picker's temporary copy once we are done with it.
        defer { try? FileManager.default.removeItem(at: movie.url) }

        let asset = AVURLAsset(url: movie.url)

        // 1. Readability.
        let isReadable = (try? await asset.load(.isReadable)) ?? false
        guard isReadable else { throw PoomsaeImportError.unreadableAsset }

        // 2. Video track.
        let videoTracks = (try? await asset.loadTracks(withMediaType: .video)) ?? []
        guard let track = videoTracks.first else { throw PoomsaeImportError.noVideoTrack }

        // 3. Duration.
        let duration = (try? await asset.load(.duration)) ?? .zero
        let durationSeconds = duration.seconds.isFinite ? duration.seconds : 0
        guard durationSeconds > 0 else { throw PoomsaeImportError.unreadableAsset }

        // 4. Display size — natural size with the preferred transform applied.
        let sizeAndTransform = try? await track.load(.naturalSize, .preferredTransform)
        let naturalSize = sizeAndTransform?.0 ?? .zero
        let transform = sizeAndTransform?.1 ?? .identity
        let oriented = naturalSize.applying(transform)
        let videoSize = CGSize(width: abs(oriented.width), height: abs(oriented.height))

        // 5. Copy into the sandbox.
        let id = UUID()
        let ext = movie.url.pathExtension.isEmpty ? "mov" : movie.url.pathExtension.lowercased()
        let storedFilename = "\(id.uuidString).\(ext)"
        do {
            try await fileStore.importVideoFile(from: movie.url, storedFilename: storedFilename)
        } catch {
            print("PoomsaeVideoImporter.importMovie copy:", error)
            throw PoomsaeImportError.copyFailed
        }

        // 6. Persist the recording; roll back the copy on failure.
        let recording = PoomsaeRecording(
            id: id,
            originalFilename: movie.originalFilename,
            storedFilename: storedFilename,
            durationSeconds: durationSeconds,
            videoSize: videoSize
        )
        do {
            try await fileStore.upsert(recording)
        } catch {
            try? await fileStore.deleteVideoFile(storedFilename: storedFilename)
            print("PoomsaeVideoImporter.importMovie persist:", error)
            throw PoomsaeImportError.copyFailed
        }
        return recording
    }
}

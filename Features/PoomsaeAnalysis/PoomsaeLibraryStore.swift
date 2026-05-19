import Foundation
import Observation

// MARK: - PoomsaeLibraryStore
//
// Stage 2.6.a — view-facing state for the recording list screen.
//
// `@Observable @MainActor` store (per the app's store convention). Owns the
// `[PoomsaeRecording]` collection, sorted by `importedAt` descending, and
// exposes async actions backed by `PoomsaeFileStore` + `PoomsaeVideoImporter`.

@Observable @MainActor
public final class PoomsaeLibraryStore {

    // MARK: - State

    public private(set) var recordings: [PoomsaeRecording] = []
    public private(set) var isLoaded = false
    public private(set) var isImporting = false
    /// User-facing import error message; non-nil drives an alert.
    public var importError: String?

    // MARK: - Dependencies

    private let fileStore: PoomsaeFileStore
    private let importer: PoomsaeVideoImporter

    public init(fileStore: PoomsaeFileStore = PoomsaeFileStore()) {
        self.fileStore = fileStore
        self.importer = PoomsaeVideoImporter(fileStore: fileStore)
    }

    /// The shared file store, so the analysis screen can reuse one instance.
    public var store: PoomsaeFileStore { fileStore }

    // MARK: - Actions

    /// Loads the persisted recordings, newest first.
    public func load() async {
        do {
            let loaded = try await fileStore.loadRecordings()
            recordings = loaded.sorted { $0.importedAt > $1.importedAt }
        } catch {
            print("PoomsaeLibraryStore.load:", error)
        }
        isLoaded = true
    }

    /// Imports a movie picked from the Photos library and inserts it at the
    /// top of the list. Surfaces any failure via `importError`.
    public func importMovie(_ movie: ImportedMovie) async {
        isImporting = true
        importError = nil
        defer { isImporting = false }
        do {
            let recording = try await importer.importMovie(movie)
            recordings.insert(recording, at: 0)
            recordings.sort { $0.importedAt > $1.importedAt }
        } catch {
            importError = (error as? LocalizedError)?.errorDescription
                ?? "The video could not be imported."
            print("PoomsaeLibraryStore.importMovie:", error)
        }
    }

    /// Deletes a recording and its files.
    public func delete(_ recording: PoomsaeRecording) async {
        do {
            try await fileStore.delete(id: recording.id)
            recordings.removeAll { $0.id == recording.id }
        } catch {
            print("PoomsaeLibraryStore.delete:", error)
        }
    }
}

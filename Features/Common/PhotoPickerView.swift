import SwiftUI
import PhotosUI

/// Lightweight photo picker that hands off the raw bytes to a caller-provided
/// uploader. In demo mode the uploader writes to the app's tmp directory and
/// returns a `file://` URL; in Supabase mode the uploader uses Storage.
public struct PhotoPickerView: View {
    public let athleteID: EntityID
    public let onUploaded: (String) -> Void

    @State private var selectedItem: PhotosPickerItem?
    @State private var status: Status = .idle

    public enum Status: Equatable {
        case idle
        case uploading
        case ready(String)
        case failed(String)
    }

    public init(athleteID: EntityID, onUploaded: @escaping (String) -> Void) {
        self.athleteID = athleteID
        self.onUploaded = onUploaded
    }

    public var body: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                Label("photo.pick", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.bordered)

            switch status {
            case .idle:
                Text("photo.idle").font(.caption).foregroundStyle(.secondary)
            case .uploading:
                ProgressView()
            case .ready(let url):
                VStack(spacing: 4) {
                    Label("photo.uploaded", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    Text(verbatim: url).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            case .failed(let message):
                Text(verbatim: message).font(.caption).foregroundStyle(.red)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task { await handle(item: newItem) }
        }
    }

    private func handle(item: PhotosPickerItem) async {
        status = .uploading
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                status = .failed("photo.load_failed")
                return
            }
            let url = try await defaultUploader(data: data, athleteID: athleteID)
            onUploaded(url)
            status = .ready(url)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    /// Demo uploader: persists to the app's documents/athletePhotos folder
    /// and returns the resulting `file://` URL string. Swap this out with a
    /// Supabase Storage call by injecting a different closure.
    private func defaultUploader(data: Data, athleteID: EntityID) async throws -> String {
        let documents = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let photosDir = documents.appendingPathComponent("athletePhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)
        let dest = photosDir.appendingPathComponent("\(athleteID.uuidString).jpg")
        try data.write(to: dest, options: .atomic)
        return dest.absoluteString
    }
}

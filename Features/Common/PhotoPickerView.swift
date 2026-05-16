import SwiftUI
import PhotosUI

/// Photo picker that uploads via the active repository's storage backend.
/// Demo mode writes to documents/athletePhotos and returns a `file://` URL;
/// Supabase mode uploads to the athletePhotos Storage bucket and returns the
/// public URL.
public struct PhotoPickerView: View {
    @Environment(AppSession.self) private var session

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
                Text("photo.idle").scaledFont(.caption).foregroundStyle(.secondary)
            case .uploading:
                ProgressView()
            case .ready(let url):
                VStack(spacing: 4) {
                    Label("photo.uploaded", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    Text(verbatim: url).scaledFont(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            case .failed(let message):
                Text(verbatim: message).scaledFont(.caption).foregroundStyle(.red)
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
            let contentType = sniffContentType(data)
            let url = try await session.repository.uploadAthletePhoto(
                athleteID: athleteID,
                data: data,
                contentType: contentType
            )
            onUploaded(url)
            status = .ready(url)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    /// PhotosPicker yields whatever the source asset is — usually JPEG, sometimes PNG
    /// or HEIC. Sniff the magic bytes so the upload reports the right MIME type and
    /// hits the bucket's allowed_mime_types whitelist.
    private func sniffContentType(_ data: Data) -> String {
        guard data.count >= 12 else { return "application/octet-stream" }
        let header = data.prefix(12)
        if header.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
        if header.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "image/png" }
        if header.dropFirst(4).starts(with: [0x66, 0x74, 0x79, 0x70]) { return "image/heic" }
        if header.starts(with: [0x52, 0x49, 0x46, 0x46]) { return "image/webp" }
        return "image/jpeg"
    }
}

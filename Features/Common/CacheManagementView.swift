import SwiftUI

/// Cache Management detail screen. Shows the real on-disk size of the app's
/// caches — locally stored photos and the offline repository cache — and
/// offers a one-tap clear. Clearing never touches the user's account or any
/// server data; it only removes files that are re-downloaded on demand.
public struct CacheManagementView: View {
    @State private var imageBytes: Int64 = 0
    @State private var dataBytes: Int64 = 0
    @State private var clearing = false
    @State private var showClearConfirm = false

    public init() {}

    private var totalBytes: Int64 { imageBytes + dataBytes }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                totalCard
                breakdownCard
                clearCard
                explainer
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.appBackground)
        .navigationTitle(Text("settings.system.cache"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { recompute() }
        .confirmationDialog(
            Text("cache.clear_confirm.title"),
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("cache.clear", role: .destructive) {
                Task { await clear() }
            }
            Button("action.cancel", role: .cancel) {}
        } message: {
            Text("cache.clear_confirm.body")
        }
    }

    private var totalCard: some View {
        VStack(spacing: 6) {
            Image(systemName: "externaldrive.fill")
                .scaledFont(.title)
                .foregroundStyle(.tint)
            Text(verbatim: formatted(totalBytes))
                .scaledFont(.largeTitle, weight: .bold)
                .monospacedDigit()
            Text("cache.total.label")
                .scaledFont(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var breakdownCard: some View {
        VStack(spacing: 0) {
            row(icon: "photo.fill", label: "cache.images.label", bytes: imageBytes)
            Divider().opacity(0.4)
            row(icon: "tray.full.fill", label: "cache.data.label", bytes: dataBytes)
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func row(icon: String, label: LocalizedStringKey, bytes: Int64) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(.tint)
                .frame(width: 26)
            Text(label).scaledFont(.subheadline)
            Spacer(minLength: 12)
            Text(verbatim: formatted(bytes))
                .scaledFont(.subheadline, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var clearCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("cache.clear_title").scaledFont(.headline)
            Text("cache.clear_body")
                .scaledFont(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(role: .destructive) {
                showClearConfirm = true
            } label: {
                HStack(spacing: 8) {
                    if clearing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "trash.fill")
                    }
                    Text(clearing ? "cache.clearing" : "cache.clear")
                }
                .scaledFont(.subheadline, weight: .semibold)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(clearing || totalBytes == 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var explainer: some View {
        Text("cache.explainer")
            .scaledFont(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }

    // MARK: - Disk work

    private func formatted(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    /// Image caches live under Documents; the offline repository cache lives
    /// under Caches. Sizes are summed recursively.
    private func cacheDirectories() -> (images: [URL], data: [URL]) {
        let fm = FileManager.default
        var images: [URL] = []
        var data: [URL] = []
        if let docs = try? fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            images.append(docs.appendingPathComponent("userAvatars", isDirectory: true))
            images.append(docs.appendingPathComponent("athletePhotos", isDirectory: true))
        }
        if let caches = try? fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            data.append(caches.appendingPathComponent("RepositoryCache", isDirectory: true))
        }
        return (images, data)
    }

    private func directorySize(_ url: URL) -> Int64 {
        let fm = FileManager.default
        guard let en = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let file as URL in en {
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            total += Int64(size)
        }
        return total
    }

    private func recompute() {
        let dirs = cacheDirectories()
        imageBytes = dirs.images.reduce(0) { $0 + directorySize($1) }
        dataBytes = dirs.data.reduce(0) { $0 + directorySize($1) }
    }

    private func clear() async {
        clearing = true
        let fm = FileManager.default
        let dirs = cacheDirectories()
        for url in dirs.images + dirs.data {
            try? fm.removeItem(at: url)
        }
        recompute()
        clearing = false
    }
}

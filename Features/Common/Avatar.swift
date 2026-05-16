import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public enum AvatarPalette: String, CaseIterable, Sendable {
    case coral, teal, blue, purple, amber, gray

    public var color: Color {
        switch self {
        case .coral: Color(red: 0.95, green: 0.45, blue: 0.45)
        case .teal: Color(red: 0.20, green: 0.65, blue: 0.65)
        case .blue: Color(red: 0.25, green: 0.50, blue: 0.85)
        case .purple: Color(red: 0.55, green: 0.40, blue: 0.75)
        case .amber: Color(red: 0.95, green: 0.65, blue: 0.20)
        case .gray: Color(red: 0.50, green: 0.55, blue: 0.60)
        }
    }
}

/// Outer clip shape for `Avatar`. Existing call sites get the historical
/// circle by default; profile/hero treatments opt into the rounded-square
/// look by passing `.roundedRect`.
public enum AvatarShape: Sendable, Equatable {
    case circle
    case roundedRect(cornerRadius: CGFloat)
}

public struct Avatar: View {
    public let seed: String
    public let label: String
    public let size: CGFloat
    public let urlString: String?
    public let shape: AvatarShape
    /// When set, the Avatar checks `Documents/userAvatars/<id>.{jpg,png,heic}`
    /// before consulting `urlString`. Local cache wins, so a freshly picked
    /// profile photo shows up immediately and survives Supabase round-trip
    /// failures (e.g. RLS / missing-column errors that get swallowed by the
    /// repository layer).
    public let localCacheID: UUID?
    @Environment(\.uiScale) private var uiScale

    public init(
        seed: String,
        label: String,
        size: CGFloat = 40,
        urlString: String? = nil,
        shape: AvatarShape = .circle,
        localCacheID: UUID? = nil
    ) {
        self.seed = seed
        self.label = label
        self.size = size
        self.urlString = urlString
        self.shape = shape
        self.localCacheID = localCacheID
    }

    /// Effective render size: the caller's `size` parameter scaled by the
    /// macOS UI Zoom factor. Used uniformly for the frame AND the initials
    /// font math so the circle and its text grow together.
    private var renderSize: CGFloat { size * uiScale }

    public var body: some View {
        ZStack {
            palette.color.opacity(0.85)
            pictureLayer
        }
        .frame(width: renderSize, height: renderSize)
        .clipShape(clipShape)
    }

    @ViewBuilder
    private var pictureLayer: some View {
        if let cacheURL = localCachedURL, let img = loadLocalImage(at: cacheURL) {
            img
                .resizable()
                .scaledToFill()
        } else if let url = remoteURL {
            if url.isFileURL {
                if let img = loadLocalImage(at: url) {
                    img
                        .resizable()
                        .scaledToFill()
                } else {
                    initialsLabel
                }
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        initialsLabel
                    }
                }
            }
        } else {
            initialsLabel
        }
    }

    private func loadLocalImage(at url: URL) -> Image? {
        #if os(iOS)
        guard let ui = UIImage(contentsOfFile: url.path) else { return nil }
        return Image(uiImage: ui)
        #elseif os(macOS)
        guard let ns = NSImage(contentsOfFile: url.path) else { return nil }
        return Image(nsImage: ns)
        #else
        return nil
        #endif
    }

    private var initialsLabel: some View {
        Text(verbatim: label)
            .font(.system(size: renderSize * 0.4, weight: .semibold))
            .foregroundStyle(.white)
    }

    private var remoteURL: URL? {
        guard let urlString, !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }

    /// Resolves the local cache file path for `localCacheID`, picking the
    /// first existing file across the supported extensions. Returns nil if
    /// no cache file is on disk.
    private var localCachedURL: URL? {
        guard let id = localCacheID else { return nil }
        guard let docs = try? FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false
        ) else { return nil }
        let dir = docs.appendingPathComponent("userAvatars", isDirectory: true)
        for ext in ["jpg", "jpeg", "png", "heic"] {
            let candidate = dir.appendingPathComponent("\(id.uuidString).\(ext)")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }

    private var palette: AvatarPalette {
        let cases = AvatarPalette.allCases
        let sum = seed.utf8.reduce(0) { $0 &+ Int($1) }
        return cases[sum % cases.count]
    }

    private var clipShape: AnyShape {
        switch shape {
        case .circle:
            AnyShape(Circle())
        case .roundedRect(let radius):
            AnyShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
    }
}

import SwiftUI

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

public struct Avatar: View {
    public let seed: String
    public let label: String
    public let size: CGFloat
    public let urlString: String?

    public init(seed: String, label: String, size: CGFloat = 40, urlString: String? = nil) {
        self.seed = seed
        self.label = label
        self.size = size
        self.urlString = urlString
    }

    public var body: some View {
        ZStack {
            Circle().fill(palette.color.opacity(0.85))
            if let url = remoteURL {
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
            } else {
                initialsLabel
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialsLabel: some View {
        Text(verbatim: label)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(.white)
    }

    private var remoteURL: URL? {
        guard let urlString, !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }

    private var palette: AvatarPalette {
        let cases = AvatarPalette.allCases
        let sum = seed.utf8.reduce(0) { $0 &+ Int($1) }
        return cases[sum % cases.count]
    }
}

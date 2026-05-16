import SwiftUI

public struct KPITile: View {
    public let title: LocalizedStringKey
    public let value: String
    public let icon: String?

    public init(title: LocalizedStringKey, value: String, icon: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).foregroundStyle(.tint) }
                Text(title).scaledFont(.caption).foregroundStyle(.secondary)
            }
            Text(verbatim: value).scaledFont(.title2, weight: .bold)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

public struct GradeBadge: View {
    public let grade: LetterGrade
    public let size: CGFloat
    @Environment(\.uiScale) private var uiScale

    public init(grade: LetterGrade, size: CGFloat = 32) {
        self.grade = grade
        self.size = size
    }

    /// Caller-provided size scaled by the UI Zoom factor — used for both the
    /// circle frame and the inner letter font so they grow together.
    private var renderSize: CGFloat { size * uiScale }

    public var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.18))
            Circle().stroke(color, lineWidth: 1.5)
            Text(verbatim: grade.label)
                .font(.system(size: renderSize * 0.42, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(width: renderSize, height: renderSize)
    }

    private var color: Color {
        switch grade {
        case .aPlus, .a, .aMinus: .green
        case .bPlus, .b, .bMinus: .blue
        case .cPlus, .c, .cMinus: .orange
        case .dPlus, .d, .f: .red
        }
    }
}

public struct StatusPill: View {
    public let status: AthleteStatus

    public init(status: AthleteStatus) { self.status = status }

    public var body: some View {
        Text(localizedKey: status.labelKey)
            .scaledFont(.caption, weight: .medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .competitionTeam: .red
        case .readyToGrade: .green
        case .watch: .orange
        case .rest: .gray
        case .active: .blue
        }
    }
}

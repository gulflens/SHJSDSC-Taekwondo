import SwiftUI

/// The coaching-development pipeline as a horizontal progression strip:
/// athlete → assistant coach → junior coach → coach → head coach → technical
/// director, with a live headcount at each rung. This visualises SSDC's
/// athlete-to-leadership pathway — the retention and leadership-growth engine.
public struct CoachingPipelineView: View {
    public let counts: [DevelopmentLevel: Int]

    public init(counts: [DevelopmentLevel: Int]) {
        self.counts = counts
    }

    public var body: some View {
        SectionCard("coaching.pipeline", icon: "arrow.up.forward.circle.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Text("coaching.pipeline.caption")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 2) {
                        ForEach(Array(DevelopmentLevel.allCases.enumerated()), id: \.element) { index, level in
                            PipelineStageNode(level: level, count: counts[level] ?? 0)
                                .frame(width: 88)
                            if index < DevelopmentLevel.allCases.count - 1 {
                                connector
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    private var connector: some View {
        Image(systemName: "chevron.compact.right")
            .scaledFont(.headline, weight: .semibold)
            .foregroundStyle(Color.secondary.opacity(0.4))
            .flipsForRightToLeftLayoutDirection(true)
            .padding(.top, 14)
    }
}

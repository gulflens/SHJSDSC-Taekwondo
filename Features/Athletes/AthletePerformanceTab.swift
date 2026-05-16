import SwiftUI

/// Performance tab — composite trend, physical metrics, technical skills,
/// training load. Reuses the existing premium cards from Features/Performance.
public struct AthletePerformanceTab: View {
    @Binding public var athlete: Athlete
    public let isWide: Bool

    public init(athlete: Binding<Athlete>, isWide: Bool) {
        _athlete = athlete
        self.isWide = isWide
    }

    public var body: some View {
        VStack(spacing: 14) {
            SectionCard("athlete.card.composite_trend", icon: "chart.line.uptrend.xyaxis") {
                PerformanceTrendView(athlete: athlete)
            }
            if isWide {
                HStack(alignment: .top, spacing: 14) {
                    SectionCard("athlete.card.physical_metrics", icon: "figure.run") {
                        PhysicalMetricsCard(athlete: $athlete)
                    }
                    .frame(maxWidth: .infinity)
                    SectionCard("athlete.card.training_load", icon: "bolt.heart.fill") {
                        TrainingLoadCard(athleteID: athlete.id)
                    }
                    .frame(maxWidth: .infinity)
                }
                SectionCard("athlete.card.technical_skills", icon: "figure.taichi") {
                    TechnicalSkillsCard(athleteID: athlete.id)
                }
                if athlete.specialty == .poomsae || athlete.specialty == .both {
                    SectionCard("athlete.card.poomsae", icon: "figure.mind.and.body") {
                        PoomsaeMetricsCard(athlete: $athlete)
                    }
                }
            } else {
                SectionCard("athlete.card.physical_metrics", icon: "figure.run") {
                    PhysicalMetricsCard(athlete: $athlete)
                }
                SectionCard("athlete.card.training_load", icon: "bolt.heart.fill") {
                    TrainingLoadCard(athleteID: athlete.id)
                }
                SectionCard("athlete.card.technical_skills", icon: "figure.taichi") {
                    TechnicalSkillsCard(athleteID: athlete.id)
                }
                if athlete.specialty == .poomsae || athlete.specialty == .both {
                    SectionCard("athlete.card.poomsae", icon: "figure.mind.and.body") {
                        PoomsaeMetricsCard(athlete: $athlete)
                    }
                }
            }
        }
    }
}

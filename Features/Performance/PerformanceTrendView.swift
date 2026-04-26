import SwiftUI
import Charts

public struct PerformanceTrendView: View {
    @Environment(AppSession.self) private var session
    @State private var store: PerformanceEntryStore?
    @State private var window: TrendWindow = .ninety

    public let athlete: Athlete

    public init(athlete: Athlete) { self.athlete = athlete }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("heading.performance_trend").font(.headline)
                Spacer()
                Picker(selection: $window) {
                    Text("trend.30").tag(TrendWindow.thirty)
                    Text("trend.90").tag(TrendWindow.ninety)
                    Text("trend.180").tag(TrendWindow.oneEighty)
                } label: { EmptyView() }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
                .labelsHidden()
            }
            if let store {
                chartGroup(store: store)
            } else {
                ProgressView().frame(maxWidth: .infinity)
            }
        }
        .task {
            if store == nil { store = PerformanceEntryStore(repository: session.repository) }
            await store?.load(athleteID: athlete.id, windowDays: 180)
        }
    }

    @ViewBuilder
    private func chartGroup(store: PerformanceEntryStore) -> some View {
        let physical = store.physicalTrend(days: window.days)
        let technical = store.technicalTrend(days: window.days)
        let wellness = store.wellnessTrend(days: window.days)
        VStack(alignment: .leading, spacing: 16) {
            chartCard(title: "chart.physical_trend", points: physical, color: .blue)
            chartCard(title: "chart.technical_trend", points: technical, color: .purple)
            chartCard(title: "chart.wellness_trend", points: wellness, color: .green)
        }
    }

    private func chartCard(title: LocalizedStringKey, points: [TrendPoint], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.bold())
            if points.isEmpty {
                Text("empty.no_data").font(.caption).foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(points) { p in
                        LineMark(
                            x: .value("date", p.date),
                            y: .value("value", p.value)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(color)
                        PointMark(
                            x: .value("date", p.date),
                            y: .value("value", p.value)
                        )
                        .foregroundStyle(color)
                    }
                }
                .chartYScale(domain: 0...100)
                .frame(height: 140)
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

public enum TrendWindow: Int, CaseIterable, Hashable, Sendable {
    case thirty = 30, ninety = 90, oneEighty = 180

    public var days: Int { rawValue }
}

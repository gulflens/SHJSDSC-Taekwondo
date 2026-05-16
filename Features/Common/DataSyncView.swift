import SwiftUI

/// Data Sync detail screen — shows the active data source, connection state,
/// and the last successful refresh, with a manual "Refresh Now" action that
/// re-runs `AppSession.bootstrap()`.
public struct DataSyncView: View {
    @Environment(AppSession.self) private var session
    @AppStorage("sync.lastRefresh") private var lastRefreshStamp: Double = 0
    @AppStorage("prefs.offlineMode") private var offlineMode: Bool = false
    @State private var refreshing = false

    public init() {}

    /// CachingRepository wraps the Supabase backend; DemoRepository is local.
    private var isCloud: Bool { !(session.repository is DemoRepository) }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                infoCard
                refreshCard
                explainer
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.appBackground)
        .navigationTitle(Text("settings.system.sync"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow(icon: isCloud ? "cloud.fill" : "internaldrive.fill",
                    label: "sync.source.label",
                    value: Text(isCloud ? "sync.source.cloud" : "sync.source.demo"))
            Divider().opacity(0.4)
            infoRow(icon: offlineMode ? "wifi.slash" : (isCloud ? "wifi" : "checkmark.circle.fill"),
                    label: "sync.status.label",
                    value: Text(offlineMode ? "sync.status.offline" : "sync.status.online"))
            Divider().opacity(0.4)
            infoRow(icon: "clock.arrow.circlepath",
                    label: "sync.last_refresh.label",
                    value: lastRefreshText)
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(icon: String, label: LocalizedStringKey, value: Text) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(.tint)
                .frame(width: 26)
            Text(label).scaledFont(.subheadline)
            Spacer(minLength: 12)
            value
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var refreshCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("sync.refresh_title").scaledFont(.headline)
            Text("sync.refresh_body")
                .scaledFont(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Task { await refresh() }
            } label: {
                HStack(spacing: 8) {
                    if refreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text(refreshing ? "sync.refreshing" : "sync.refresh_now")
                }
                .scaledFont(.subheadline, weight: .semibold)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(refreshing || offlineMode)
            if offlineMode {
                Text("sync.refresh_disabled_offline")
                    .scaledFont(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var explainer: some View {
        Text("sync.explainer")
            .scaledFont(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }

    private var lastRefreshText: Text {
        guard lastRefreshStamp > 0 else { return Text("sync.last_refresh.never") }
        let date = Date(timeIntervalSince1970: lastRefreshStamp)
        return Text(date, format: .relative(presentation: .named))
    }

    private func refresh() async {
        refreshing = true
        await session.bootstrap()
        lastRefreshStamp = Date().timeIntervalSince1970
        refreshing = false
    }
}

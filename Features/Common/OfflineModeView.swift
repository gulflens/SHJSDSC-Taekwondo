import SwiftUI
import Network

/// Offline Mode detail screen. The toggle drives `prefs.offlineMode`, which
/// `CachingRepository` reads: when on, core lists are served from the disk
/// cache and network writes are blocked. A live `NWPathMonitor` reading
/// shows the actual connection state alongside.
public struct OfflineModeView: View {
    @Environment(AppSession.self) private var session
    @AppStorage("prefs.offlineMode") private var offlineMode: Bool = false
    @State private var monitor = NetworkStatus()

    public init() {}

    private var isCloud: Bool { !(session.repository is DemoRepository) }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                toggleCard
                networkCard
                if !isCloud {
                    demoNote
                }
                explainer
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.appBackground)
        .subviewChrome(Text("settings.system.offline"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var toggleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $offlineMode) {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .scaledFont(.subheadline, weight: .semibold)
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("offline.toggle.label").scaledFont(.subheadline, weight: .semibold)
                        Text("offline.toggle.subtitle")
                            .scaledFont(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var networkCard: some View {
        HStack(spacing: 12) {
            Image(systemName: monitor.isConnected ? "wifi" : "wifi.exclamationmark")
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(monitor.isConnected ? Color.secondaryAccent : Color.orange)
                .frame(width: 26)
            Text("offline.network.label").scaledFont(.subheadline)
            Spacer(minLength: 12)
            Text(monitor.isConnected ? "offline.network.connected" : "offline.network.disconnected")
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var demoNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .scaledFont(.footnote)
                .foregroundStyle(.tint)
            Text("offline.demo_note")
                .scaledFont(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var explainer: some View {
        Text("offline.explainer")
            .scaledFont(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }
}

/// Thin `NWPathMonitor` wrapper that publishes connectivity to SwiftUI.
@MainActor
@Observable
final class NetworkStatus {
    private(set) var isConnected = true
    private let monitor = NWPathMonitor()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor in self?.isConnected = connected }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkStatus"))
    }

    deinit { monitor.cancel() }
}

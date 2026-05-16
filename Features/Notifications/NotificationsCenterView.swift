import SwiftUI

public struct NotificationsCenterView: View {
    public init() {}

    public var body: some View {
        Form {
            Section(header: Text("notif.preferences")) {
                ForEach(NotificationKind.allCases, id: \.self) { kind in
                    NotificationToggle(kind: kind)
                }
            }
            Section(header: Text("notif.history")) {
                Text("notif.history_empty")
                    .foregroundStyle(.secondary)
                    .scaledFont(.caption)
            }
        }
        .navigationTitle(Text("settings.notifications"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private struct NotificationToggle: View {
    let kind: NotificationKind
    @AppStorage private var enabled: Bool

    init(kind: NotificationKind) {
        self.kind = kind
        self._enabled = AppStorage(wrappedValue: true, kind.preferenceKey)
    }

    var body: some View {
        Toggle(LocalizedStringKey(kind.labelKey), isOn: $enabled)
    }
}

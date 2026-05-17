import SwiftUI

/// Login Activity screen — lists recent sign-in events for the current user,
/// read from the audit log (`AppSession` records an `auth.signin` entry on
/// every successful sign-in).
public struct LoginActivityView: View {
    @Environment(AppSession.self) private var session

    @State private var entries: [AuditEntry] = []
    @State private var loading = true

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if loading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if entries.isEmpty {
                    emptyCard
                } else {
                    listCard
                }
                explainer
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.appBackground)
        .subviewChrome(Text("profile.security.login_activity"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await load() }
    }

    private var listCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                if index > 0 { Divider().opacity(0.4) }
                row(entry)
            }
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func row(_ entry: AuditEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.changes["platform"] == "macOS" ? "desktopcomputer" : "iphone.gen3")
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text("login_activity.signed_in").scaledFont(.subheadline, weight: .semibold)
                Text(verbatim: entry.changes["platform"] ?? "—")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.at, format: .relative(presentation: .named))
                    .scaledFont(.caption, weight: .semibold)
                    .foregroundStyle(.secondary)
                Text(entry.at, format: .dateTime.day().month().hour().minute())
                    .scaledFont(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
    }

    private var emptyCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.questionmark")
                .scaledFont(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("login_activity.empty")
                .scaledFont(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var explainer: some View {
        Text("login_activity.explainer")
            .scaledFont(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }

    private func load() async {
        defer { loading = false }
        guard let user = session.currentUser else { return }
        let all = (try? await session.repository.entries(actor: user.id, since: nil)) ?? []
        entries = all
            .filter { $0.action.hasPrefix("auth.") }
            .sorted { $0.at > $1.at }
    }
}

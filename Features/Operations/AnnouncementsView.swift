import SwiftUI

public struct AnnouncementsView: View {
    @Environment(AppSession.self) private var session
    @State private var store: OperationsStore?
    @State private var showCompose = false

    public init() {}

    public var body: some View {
        Group {
            if let store {
                content(store: store)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(Text("tab.announcements"))
        .toolbar {
            if let role = session.currentUser?.role,
               PermissionMatrix.allowed(role: role, permission: .publishAnnouncement) {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCompose = true
                    } label: {
                        Label("announcement.compose", systemImage: "square.and.pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $showCompose) {
            NavigationStack {
                ComposeAnnouncementView { _ in
                    Task { await store?.load() }
                }
            }
        }
        .task {
            if store == nil { store = OperationsStore(repository: session.repository) }
            await store?.load()
        }
    }

    @ViewBuilder
    private func content(store: OperationsStore) -> some View {
        List {
            if store.announcements.isEmpty {
                Text("empty.no_announcements").foregroundStyle(.secondary)
            } else {
                ForEach(store.grouped(), id: \.date) { group in
                    Section(header: Text(group.date, style: .date)) {
                        ForEach(group.items) { a in
                            AnnouncementRow(
                                announcement: a,
                                myResponse: store.myResponse(announcementID: a.id, userID: session.currentUser?.id ?? UUID()),
                                rsvpCount: store.rsvpsByAnnouncement[a.id]?.count ?? 0
                            ) { response in
                                guard let userID = session.currentUser?.id else { return }
                                Task { await store.rsvp(announcementID: a.id, userID: userID, response: response) }
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct AnnouncementRow: View {
    let announcement: Announcement
    let myResponse: RSVPResponse?
    let rsvpCount: Int
    let onRSVP: (RSVPResponse) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: announcement.title).font(.headline)
            Text(verbatim: announcement.titleAr).font(.caption).foregroundStyle(.secondary)
            Text(verbatim: announcement.body).font(.body)
            HStack(spacing: 6) {
                Image(systemName: "person.3.fill").font(.caption2)
                Text(LocalizedStringKey(announcement.audience.labelKey))
                    .font(.caption2).foregroundStyle(.secondary)
                if announcement.requiresRSVP {
                    Spacer()
                    Image(systemName: "checkmark.circle").font(.caption2).foregroundStyle(.tint)
                    Text(verbatim: "\(rsvpCount)").font(.caption2).foregroundStyle(.secondary)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
            if announcement.requiresRSVP {
                HStack(spacing: 8) {
                    rsvpButton(.yes, color: .green)
                    rsvpButton(.maybe, color: .orange)
                    rsvpButton(.no, color: .red)
                    Spacer()
                    if let deadline = announcement.rsvpDeadline {
                        Text(deadline, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private func rsvpButton(_ response: RSVPResponse, color: Color) -> some View {
        Button {
            onRSVP(response)
        } label: {
            Text(LocalizedStringKey(response.labelKey))
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(myResponse == response ? color.opacity(0.85) : color.opacity(0.18))
                .foregroundStyle(myResponse == response ? Color.white : color)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

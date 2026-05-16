import SwiftUI

public struct ComposeAnnouncementView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public let onPublish: (Announcement) -> Void

    @State private var title: String = ""
    @State private var titleAr: String = ""
    @State private var bodyText: String = ""
    @State private var bodyAr: String = ""
    @State private var audience: AnnouncementAudience = .all
    @State private var branchID: EntityID?
    @State private var requiresRSVP: Bool = false
    @State private var rsvpDeadline: Date = Date().addingTimeInterval(7 * 24 * 3600)
    @State private var saving = false
    @State private var branches: [Branch] = []

    public init(onPublish: @escaping (Announcement) -> Void) {
        self.onPublish = onPublish
    }

    public var body: some View {
        Form {
            Section(header: Text("announcement.title_en")) {
                TextField("announcement.title_en", text: $title)
            }
            Section(header: Text("announcement.title_ar")) {
                TextField("announcement.title_ar", text: $titleAr)
            }
            Section(header: Text("announcement.body_en")) {
                TextField("announcement.body_en", text: $bodyText, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            }
            Section(header: Text("announcement.body_ar")) {
                TextField("announcement.body_ar", text: $bodyAr, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            }
            Section {
                Picker(selection: $audience) {
                    ForEach(AnnouncementAudience.allCases, id: \.self) { aud in
                        Text(localizedKey: aud.labelKey).tag(aud)
                    }
                } label: {
                    Text("announcement.audience")
                }
                Picker(selection: $branchID) {
                    Text("filter.all").tag(EntityID?.none)
                    ForEach(branches) { b in
                        Text(verbatim: b.name).tag(Optional(b.id))
                    }
                } label: {
                    Text("tab.branches")
                }
            }
            Section {
                Toggle("announcement.requires_rsvp", isOn: $requiresRSVP)
                if requiresRSVP {
                    DatePicker("announcement.rsvp_deadline", selection: $rsvpDeadline, in: Date()...)
                }
            }
            Section {
                Button {
                    Task { await publish() }
                } label: {
                    if saving {
                        HStack { ProgressView(); Text("action.saving") }
                    } else {
                        Text("announcement.compose")
                    }
                }
                .disabled(saving || title.isEmpty || bodyText.isEmpty)
            }
        }
        .navigationTitle(Text("announcement.compose"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
                .bareToolbarButton()
            }
        }
        .task { branches = (try? await session.repository.branches()) ?? [] }
    }

    private func publish() async {
        guard let userID = session.currentUser?.id else { return }
        saving = true
        defer { saving = false }
        let a = Announcement(
            branchID: branchID,
            title: title,
            titleAr: titleAr.isEmpty ? title : titleAr,
            body: bodyText,
            bodyAr: bodyAr.isEmpty ? bodyText : bodyAr,
            audience: audience,
            publishedAt: Date(),
            publishedByUserID: userID,
            requiresRSVP: requiresRSVP,
            rsvpDeadline: requiresRSVP ? rsvpDeadline : nil
        )
        do {
            try await session.repository.upsert(announcement: a)
            onPublish(a)
            dismiss()
        } catch {
            print("ComposeAnnouncementView.publish:", error)
        }
    }
}

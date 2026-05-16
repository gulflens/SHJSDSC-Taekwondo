import SwiftUI
import PhotosUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Account-level profile editor reachable from every role's profile screen.
/// Edits the `User` record (name, avatar, contact info, language preference,
/// notification toggles). Separate from the Athlete/Coach dossier edit flows,
/// which live on their respective detail views.
public struct EditMyAccountView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var fullNameAr: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var language: PreferredLanguage = .system
    @State private var notifications: UserNotificationPreferences = .default
    @State private var avatarURL: String?
    @State private var avatarSeed: String = ""

    @State private var pickerItem: PhotosPickerItem?
    @State private var uploading = false
    @State private var saving = false

    /// Locally-decoded preview of the photo that's currently being edited.
    /// Bypasses Avatar's `file://` loader (which can stale-cache after an
    /// in-place upload) and gives the user instant visual feedback after
    /// confirming a reposition.
    @State private var previewImageData: Data?

    #if os(iOS)
    @State private var pendingImage: UIImage?
    @State private var showReposition = false
    #endif

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    avatarCard
                    nameCard
                    contactCard
                    languageCard
                    notificationsCard
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(Text("profile.edit.title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") { dismiss() }
                        .bareToolbarButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if saving {
                            ProgressView()
                        } else {
                            Text("action.save")
                        }
                    }
                    .disabled(saving || !isValid)
                    .bareToolbarButton()
                }
            }
            .task { loadFromCurrentUser() }
            #if os(iOS)
            .sheet(isPresented: $showReposition) {
                if let image = pendingImage {
                    RepositionPhotoSheet(
                        image: image,
                        onCancel: {
                            showReposition = false
                            pendingImage = nil
                            pickerItem = nil
                        },
                        onConfirm: { data in
                            showReposition = false
                            pendingImage = nil
                            pickerItem = nil
                            Task { await uploadCroppedAvatar(data: data) }
                        }
                    )
                }
            }
            #endif
        }
    }

    private var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Cards

    private var avatarCard: some View {
        SectionCard("profile.edit.photo", icon: "person.crop.circle") {
            VStack(spacing: 12) {
                avatarPreview
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    HStack(spacing: 6) {
                        if uploading {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "photo.on.rectangle")
                                .scaledFont(.subheadline, weight: .semibold)
                        }
                        Text(uploading ? "profile.edit.photo.uploading" : "profile.edit.photo.change")
                            .scaledFont(.subheadline, weight: .semibold)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .disabled(uploading)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await handlePicked(item: newItem) }
        }
    }

    @ViewBuilder
    private var avatarPreview: some View {
        let radius: CGFloat = 22
        if let data = previewImageData, let image = decodedImage(from: data) {
            image
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            Avatar(
                seed: avatarSeed,
                label: initials(from: fullName),
                size: 96,
                urlString: avatarURL,
                shape: .roundedRect(cornerRadius: radius),
                localCacheID: session.currentUser?.id
            )
        }
    }

    private var nameCard: some View {
        SectionCard("profile.edit.name", icon: "person.fill") {
            VStack(spacing: 10) {
                labeledField(label: "profile.edit.full_name") {
                    TextField("profile.edit.full_name", text: $fullName)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        #endif
                }
                labeledField(label: "profile.edit.full_name_ar") {
                    TextField("profile.edit.full_name_ar", text: $fullNameAr)
                        .textFieldStyle(.roundedBorder)
                        .environment(\.layoutDirection, .rightToLeft)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    private var contactCard: some View {
        SectionCard("profile.edit.contact", icon: "envelope.fill") {
            VStack(spacing: 10) {
                labeledField(label: "profile.edit.email") {
                    TextField("profile.edit.email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                }
                labeledField(label: "profile.edit.phone") {
                    TextField("profile.edit.phone", text: $phone)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.phonePad)
                        #endif
                }
            }
        }
    }

    private var languageCard: some View {
        SectionCard("profile.edit.language", icon: "globe") {
            Picker(selection: $language) {
                ForEach(PreferredLanguage.allCases, id: \.self) { lang in
                    Text(LocalizedStringKey(lang.labelKey)).tag(lang)
                }
            } label: {
                Text("profile.edit.language")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var notificationsCard: some View {
        SectionCard("profile.edit.notifications", icon: "bell.fill") {
            VStack(spacing: 6) {
                Toggle("profile.edit.notif.class_reminders", isOn: $notifications.classReminders)
                Divider().opacity(0.25)
                Toggle("profile.edit.notif.announcements", isOn: $notifications.announcements)
                Divider().opacity(0.25)
                Toggle("profile.edit.notif.weekly_digest", isOn: $notifications.weeklyDigest)
                Divider().opacity(0.25)
                Toggle("profile.edit.notif.promotion_alerts", isOn: $notifications.promotionAlerts)
            }
            .scaledFont(.subheadline)
        }
    }

    private func labeledField<Content: View>(
        label: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
            content()
        }
    }

    // MARK: - Actions

    private func loadFromCurrentUser() {
        guard let user = session.currentUser else { return }
        fullName = user.fullName
        fullNameAr = user.fullNameAr
        email = user.email ?? ""
        phone = user.phone ?? ""
        language = user.preferredLanguage
        notifications = user.notificationPrefs
        avatarURL = user.avatarURL
        avatarSeed = user.avatarSeed
    }

    private func save() async {
        guard var user = session.currentUser else {
            dismiss()
            return
        }
        saving = true
        defer { saving = false }
        user.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        user.fullNameAr = fullNameAr.trimmingCharacters(in: .whitespacesAndNewlines)
        user.email = trimmedOrNil(email)
        user.phone = trimmedOrNil(phone)
        user.preferredLanguage = language
        user.notificationPrefs = notifications
        user.avatarURL = avatarURL
        await session.updateProfile(user)
        dismiss()
    }

    /// On iOS we route the picked image through `RepositionPhotoSheet` so the
    /// user can frame it. On macOS (no cropper today) we upload as-is.
    private func handlePicked(item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            #if os(iOS)
            guard let image = UIImage(data: data) else {
                await uploadCroppedAvatar(data: data)
                return
            }
            await MainActor.run {
                self.pendingImage = image
                self.showReposition = true
            }
            #else
            await uploadCroppedAvatar(data: data)
            #endif
        } catch {
            print("EditMyAccountView.handlePicked:", error)
        }
    }

    private func uploadCroppedAvatar(data: Data) async {
        uploading = true
        defer { uploading = false }
        // Show the new photo immediately, before the upload round-trip.
        previewImageData = data
        guard let userID = session.currentUser?.id else { return }
        // 1) Always write the cropped JPEG to the local cache first. The
        //    `Avatar` component reads `Documents/userAvatars/<id>.jpg`
        //    before consulting any URL, so the new photo shows up across
        //    the app even when the Supabase round-trip below fails (e.g.
        //    the storage bucket isn't created yet, RLS blocks the write,
        //    or the user_profiles table is missing the avatar_url column).
        writeAvatarToLocalCache(data: data, userID: userID)
        // 2) Best-effort sync to the configured backend. Demo writes the
        //    same path we just wrote; Supabase uploads to the userAvatars
        //    bucket. Failures are non-fatal — the local cache wins for
        //    display purposes until the next successful sync.
        do {
            let contentType = sniffContentType(data)
            let url = try await session.repository.uploadUserAvatar(
                userID: userID,
                data: data,
                contentType: contentType
            )
            let separator = url.contains("#") ? "&" : "#"
            avatarURL = "\(url)\(separator)v=\(Int(Date().timeIntervalSince1970))"
        } catch {
            print("EditMyAccountView.uploadCroppedAvatar (remote sync failed, local cache still applies):", error)
        }
    }

    private func writeAvatarToLocalCache(data: Data, userID: UUID) {
        do {
            let docs = try FileManager.default.url(
                for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
            )
            let dir = docs.appendingPathComponent("userAvatars", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            // Clear any existing variants (jpeg/png/heic) so a stale extension
            // doesn't shadow the new write.
            for ext in ["jpg", "jpeg", "png", "heic"] {
                let stale = dir.appendingPathComponent("\(userID.uuidString).\(ext)")
                try? FileManager.default.removeItem(at: stale)
            }
            let dest = dir.appendingPathComponent("\(userID.uuidString).jpg")
            try data.write(to: dest, options: .atomic)
        } catch {
            print("EditMyAccountView.writeAvatarToLocalCache:", error)
        }
    }

    private func trimmedOrNil(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private func initials(from name: String) -> String {
        name.split(separator: " ")
            .prefix(2)
            .map { String($0.prefix(1)) }
            .joined()
            .uppercased()
    }

    private func decodedImage(from data: Data) -> Image? {
        #if os(iOS)
        return UIImage(data: data).map(Image.init(uiImage:))
        #elseif os(macOS)
        return NSImage(data: data).map(Image.init(nsImage:))
        #else
        return nil
        #endif
    }

    private func sniffContentType(_ data: Data) -> String {
        guard data.count >= 12 else { return "image/jpeg" }
        let header = data.prefix(12)
        if header.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
        if header.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "image/png" }
        if header.dropFirst(4).starts(with: [0x66, 0x74, 0x79, 0x70]) { return "image/heic" }
        if header.starts(with: [0x52, 0x49, 0x46, 0x46]) { return "image/webp" }
        return "image/jpeg"
    }
}

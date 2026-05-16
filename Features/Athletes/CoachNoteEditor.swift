import SwiftUI

/// Modal sheet for composing or editing a CoachNote. Pure form — persistence
/// is the caller's responsibility, signalled via the `onSave` callback so the
/// parent can update `athlete.coachNotes` and run a single repository upsert.
public struct CoachNoteEditor: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    private let editing: CoachNote?
    private let onSave: (CoachNote) -> Void

    @State private var category: CoachNoteCategory
    @State private var noteBody: String
    @State private var isPinned: Bool

    public init(editing: CoachNote? = nil, onSave: @escaping (CoachNote) -> Void) {
        self.editing = editing
        self.onSave = onSave
        _category = State(initialValue: editing?.category ?? .general)
        _noteBody = State(initialValue: editing?.body ?? "")
        _isPinned = State(initialValue: editing?.isPinned ?? false)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("coach_note.category_label", selection: $category) {
                        ForEach(CoachNoteCategory.allCases, id: \.rawValue) { cat in
                            Label(LocalizedStringKey(cat.labelKey), systemImage: cat.systemIcon)
                                .tag(cat)
                        }
                    }
                    Toggle("coach_note.pinned_toggle", isOn: $isPinned)
                }

                Section {
                    TextField("coach_note.body_placeholder", text: $noteBody, axis: .vertical)
                        .lineLimit(6, reservesSpace: true)
                } header: {
                    Text("coach_note.body_header")
                }

                if let editing {
                    Section {
                        LabeledContent("coach_note.author") {
                            Text(verbatim: editing.authorName)
                        }
                        LabeledContent("coach_note.date") {
                            Text(editing.date, format: .dateTime.day().month(.abbreviated).year())
                                .environment(\.layoutDirection, .leftToRight)
                        }
                    }
                }
            }
            .navigationTitle(editing == nil ? Text("coach_note.new") : Text("coach_note.edit"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.save") { save() }
                        .disabled(noteBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let author = session.currentUser
        let note = CoachNote(
            id: editing?.id ?? UUID(),
            authorCoachID: editing?.authorCoachID,
            authorName: editing?.authorName ?? author?.fullName ?? NSLocalizedString("coach_note.author_unknown", comment: ""),
            date: editing?.date ?? Date(),
            category: category,
            body: noteBody.trimmingCharacters(in: .whitespacesAndNewlines),
            isPinned: isPinned
        )
        onSave(note)
        dismiss()
    }
}

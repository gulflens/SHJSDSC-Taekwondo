import SwiftUI

/// Modal add/edit sheet for AthleteDocument. Pure form — persistence is the
/// caller's responsibility via `onSave`.
public struct DocumentEditor: View {
    @Environment(\.dismiss) private var dismiss

    private let editing: AthleteDocument?
    private let onSave: (AthleteDocument) -> Void

    @State private var kind: AthleteDocumentKind
    @State private var label: String
    @State private var hasIssuedDate: Bool
    @State private var issuedAt: Date
    @State private var hasExpiry: Bool
    @State private var expiresAt: Date
    @State private var status: AthleteDocumentStatus
    @State private var notes: String

    public init(editing: AthleteDocument? = nil, onSave: @escaping (AthleteDocument) -> Void) {
        self.editing = editing
        self.onSave = onSave
        _kind = State(initialValue: editing?.kind ?? .emiratesID)
        _label = State(initialValue: editing?.label ?? "")
        _hasIssuedDate = State(initialValue: editing?.issuedAt != nil)
        _issuedAt = State(initialValue: editing?.issuedAt ?? Date())
        _hasExpiry = State(initialValue: editing?.expiresAt != nil)
        _expiresAt = State(initialValue: editing?.expiresAt ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date())
        _status = State(initialValue: editing?.status ?? .valid)
        _notes = State(initialValue: editing?.notes ?? "")
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("doc.editor.kind_header") {
                    Picker("doc.editor.kind_label", selection: $kind) {
                        ForEach(AthleteDocumentKind.allCases, id: \.rawValue) { k in
                            Label(LocalizedStringKey(k.labelKey), systemImage: k.systemIcon)
                                .tag(k)
                        }
                    }
                    TextField("doc.editor.label_placeholder", text: $label)
                }

                Section("doc.editor.dates_header") {
                    Toggle("doc.editor.has_issued_date", isOn: $hasIssuedDate)
                    if hasIssuedDate {
                        DatePicker("doc.editor.issued_at", selection: $issuedAt, displayedComponents: .date)
                    }
                    Toggle("doc.editor.has_expiry", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("doc.editor.expires_at", selection: $expiresAt, displayedComponents: .date)
                    }
                }

                Section("doc.editor.status_header") {
                    Picker("doc.editor.status_label", selection: $status) {
                        ForEach(AthleteDocumentStatus.allCases, id: \.rawValue) { s in
                            Text(localizedKey: s.labelKey).tag(s)
                        }
                    }
                }

                Section("doc.editor.notes_header") {
                    TextField("doc.editor.notes_placeholder", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle(editing == nil ? Text("doc.editor.new") : Text("doc.editor.edit"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.save") { save() }
                }
            }
        }
    }

    private func save() {
        let doc = AthleteDocument(
            id: editing?.id ?? UUID(),
            kind: kind,
            label: label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : label,
            issuedAt: hasIssuedDate ? issuedAt : nil,
            expiresAt: hasExpiry ? expiresAt : nil,
            status: status,
            fileURL: editing?.fileURL,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )
        onSave(doc)
        dismiss()
    }
}

#if os(iOS)
import SwiftUI
import PhotosUI

// MARK: - PoomsaeRecordingListView
//
// Stage 2.6.a — screen (a): the imported-recordings list.
//
// Rows show a placeholder thumbnail, original filename, formatted duration and
// relative import date, sorted by `importedAt` descending. A `PhotosPicker`
// toolbar button (videos only) drives import. Friendly empty state when there
// are no recordings.
//
// Row navigation into `PoomsaeAnalysisView` is wired in Task 5.
// iPad-only feature (see Stage 2.6.a design — macOS deferred).

public struct PoomsaeRecordingListView: View {

    @State private var store = PoomsaeLibraryStore()
    @State private var pickerItem: PhotosPickerItem?

    public init() {}

    public var body: some View {
        content
            .navigationTitle("Poomsae Analysis")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: $pickerItem, matching: .videos) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Import Video")
                }
            }
            .task {
                if !store.isLoaded { await store.load() }
            }
            .onChange(of: pickerItem) { _, newItem in
                guard let newItem else { return }
                Task { await handlePick(newItem) }
            }
            .overlay {
                if store.isImporting { importingOverlay }
            }
            .alert(
                "Import Failed",
                isPresented: Binding(
                    get: { store.importError != nil },
                    set: { if !$0 { store.importError = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.importError ?? "")
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if store.isLoaded && store.recordings.isEmpty {
            ContentUnavailableView {
                Label("No Recordings", systemImage: "figure.martial.arts")
            } description: {
                Text("Import a poomsae video to begin analysis.")
            }
        } else {
            List {
                ForEach(store.recordings) { recording in
                    RecordingRow(recording: recording)
                }
                .onDelete(perform: deleteRows)
            }
        }
    }

    private var importingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                Text("Importing video…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Actions

    private func handlePick(_ item: PhotosPickerItem) async {
        defer { pickerItem = nil }
        do {
            if let movie = try await item.loadTransferable(type: ImportedMovie.self) {
                await store.importMovie(movie)
            } else {
                store.importError = "The selected video could not be loaded."
            }
        } catch {
            store.importError = "The selected video could not be loaded."
            print("PoomsaeRecordingListView.handlePick:", error)
        }
    }

    private func deleteRows(_ offsets: IndexSet) {
        let targets = offsets.map { store.recordings[$0] }
        Task {
            for recording in targets { await store.delete(recording) }
        }
    }
}

// MARK: - RecordingRow

private struct RecordingRow: View {

    let recording: PoomsaeRecording

    var body: some View {
        HStack(spacing: 14) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.originalFilename)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(durationText)
                        .monospacedDigit()
                    Text("·")
                    Text(recording.importedAt, format: .relative(presentation: .named))
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 56, height: 56)
            .overlay {
                Image(systemName: "figure.martial.arts")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
    }

    private var durationText: String {
        let total = Int(recording.durationSeconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
#endif

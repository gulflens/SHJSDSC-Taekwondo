#if os(iOS)
import SwiftUI

// MARK: - PoomsaeAnalysisView
//
// Stage 2.6.a — screen (c): the analysis workspace for one recording.
//
// Layout:
//   - video player (`PoomsaeVideoPlayerView`) with the `PoomsaeSkeletonOverlay`
//     Canvas on top, plus an extraction progress card on a cache miss
//   - transport bar (play / pause + timecode)
//   - `MotionEnergyTimelineView` below the player
//   - `MovementSegmentListView` — side panel on iPad, sheet on iPhone
//
// Pushed subview: draws its own bar via `.subviewChrome(_:)`.

public struct PoomsaeAnalysisView: View {

    private let recording: PoomsaeRecording
    private let fileStore: PoomsaeFileStore

    @State private var store: PoomsaeAnalysisStore
    @State private var player = PoomsaePlayerModel()
    @State private var projection: PoseProjection?
    @State private var showSegmentSheet = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init(recording: PoomsaeRecording, fileStore: PoomsaeFileStore) {
        self.recording = recording
        self.fileStore = fileStore
        _store = State(initialValue: PoomsaeAnalysisStore(recording: recording, fileStore: fileStore))
    }

    private var isWide: Bool { horizontalSizeClass == .regular }

    public var body: some View {
        layout
            .background(Color.appBackground)
            .subviewChrome(Text(recording.originalFilename)) {
                if !isWide {
                    Button {
                        showSegmentSheet = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                    .disabled(store.segments.isEmpty)
                }
            }
            .sheet(isPresented: $showSegmentSheet) {
                NavigationStack {
                    MovementSegmentListView(
                        segments: store.segments,
                        onSelect: { segment in
                            player.seek(to: segment.startSeconds)
                            showSegmentSheet = false
                        },
                        debugMetrics: { SegmentDebugMetrics.compute(for: $0, frames: store.poseFrames) }
                    )
                    .navigationTitle("Movements")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showSegmentSheet = false }
                        }
                    }
                }
            }
            .task {
                if let url = try? await fileStore.videoURL(for: recording) {
                    player.load(url: url)
                }
                await store.prepare()
                projection = PoseProjection.bounds(of: store.poseFrames)
            }
            .onDisappear { player.tearDown() }
    }

    // MARK: - Layout

    @ViewBuilder
    private var layout: some View {
        if isWide {
            HStack(alignment: .top, spacing: 16) {
                mainColumn
                MovementSegmentListView(
                    segments: store.segments,
                    onSelect: { player.seek(to: $0.startSeconds) },
                    debugMetrics: { SegmentDebugMetrics.compute(for: $0, frames: store.poseFrames) }
                )
                .frame(width: 320)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        } else {
            ScrollView {
                mainColumn.padding(16)
            }
        }
    }

    private var mainColumn: some View {
        VStack(spacing: 16) {
            videoArea
            transportBar
            MotionEnergyTimelineView(
                frames: store.poseFrames,
                energy: store.motionEnergy,
                segments: store.segments,
                duration: recording.durationSeconds,
                currentTime: player.currentTime,
                onSeek: { player.seek(to: $0) },
                onSeekToPeak: { player.seek(to: $0.peakMotionSeconds) }
            )
        }
    }

    private var videoArea: some View {
        ZStack {
            PoomsaeVideoPlayerView(player: player.player)
            PoomsaeSkeletonOverlay(
                frames: store.poseFrames,
                projection: projection,
                currentTime: player.currentTime
            )
            if showsProgressOverlay {
                ExtractionProgressView(phase: store.phase, progress: store.extractionProgress)
            }
        }
        .aspectRatio(videoAspect, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var transportBar: some View {
        HStack(spacing: 16) {
            Button {
                player.togglePlay()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .frame(width: 44, height: 44)
            }
            Text("\(analysisTimecode(player.currentTime)) / \(analysisTimecode(recording.durationSeconds))")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Spacer()
            if store.phase == .ready {
                Label(
                    store.loadedFromCache ? "Loaded from cache" : "\(store.segments.count) movements",
                    systemImage: store.loadedFromCache ? "bolt.fill" : "figure.martial.arts"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    private var showsProgressOverlay: Bool {
        switch store.phase {
        case .extracting, .segmenting, .failed: return true
        case .idle, .ready: return false
        }
    }

    private var videoAspect: CGFloat {
        let width = recording.videoSize.width
        let height = recording.videoSize.height
        guard width > 0, height > 0 else { return 16.0 / 9.0 }
        return width / height
    }
}
#endif

import Foundation
import Observation
import AVFoundation

// MARK: - PoomsaeAnalysisStore
//
// Stage 2.6.a — view-facing state for the analysis screen, scoped to one
// `PoomsaeRecording`.
//
// `@Observable @MainActor` store. On `prepare()` it either loads the cached
// `[PoseFrame]` (cache hit -> instant) or drives `PoomsaePoseExtractor`
// (cache miss -> progress bar) and persists the result as a binary cache.
// Movement segmentation is wired in Task 4; the skeleton/timeline UI in Task 5.

@Observable @MainActor
public final class PoomsaeAnalysisStore {

    // MARK: - Phase

    public enum Phase: Equatable, Sendable {
        case idle
        case extracting
        case segmenting
        case ready
        case failed(String)
    }

    // MARK: - State

    public private(set) var recording: PoomsaeRecording
    public private(set) var phase: Phase = .idle
    /// 0...1 progress of pose extraction (meaningful while `.extracting`).
    public private(set) var extractionProgress: Double = 0
    public private(set) var poseFrames: [PoseFrame] = []
    /// Smoothed motion-energy curve — populated in Task 4.
    public private(set) var motionEnergy: [Float] = []
    /// Segmented movements — populated in Task 4.
    public private(set) var segments: [MovementSegment] = []
    /// `true` when the poses came from the on-disk cache rather than a fresh
    /// extraction run.
    public private(set) var loadedFromCache = false

    // MARK: - Dependencies

    private let fileStore: PoomsaeFileStore
    private let parameters: SegmentationParameters

    public init(
        recording: PoomsaeRecording,
        fileStore: PoomsaeFileStore,
        parameters: SegmentationParameters = .default
    ) {
        self.recording = recording
        self.fileStore = fileStore
        self.parameters = parameters
    }

    // MARK: - Lifecycle

    /// Loads cached poses if present, otherwise runs extraction. Safe to call
    /// repeatedly — only the first call past `.idle` does work. Honours task
    /// cancellation (the caller's `.task` is cancelled on disappear).
    public func prepare() async {
        guard phase == .idle else { return }

        if let cacheName = recording.poseCacheFilename,
           let data = try? await fileStore.readPoseCache(filename: cacheName) {
            // Decode off the main actor — a 60 s clip is ~900 frames.
            let cached = await Task.detached { try? PoseCacheCodec.decode(data) }.value
            if let cached {
                poseFrames = cached
                loadedFromCache = true
                phase = .ready
                return
            }
        }
        await runExtraction()
    }

    // MARK: - Extraction

    private func runExtraction() async {
        phase = .extracting
        extractionProgress = 0

        guard let videoURL = try? await fileStore.videoURL(for: recording) else {
            phase = .failed("The video file is missing.")
            return
        }

        let extractor = PoomsaePoseExtractor()
        let stream = extractor.extractPoses(
            asset: AVURLAsset(url: videoURL),
            parameters: parameters
        ) { [self] value in
            Task { @MainActor in self.extractionProgress = min(1, value) }
        }

        var collected: [PoseFrame] = []
        for await frame in stream {
            if Task.isCancelled { return }
            collected.append(frame)
        }
        guard !Task.isCancelled else { return }

        poseFrames = collected
        loadedFromCache = false
        await persistCache(collected)
        phase = .ready
    }

    /// Encodes the extracted poses to the binary cache and records the cache
    /// filename on the recording. A cache-write failure is non-fatal —
    /// analysis still proceeds, extraction simply re-runs next time.
    private func persistCache(_ frames: [PoseFrame]) async {
        do {
            let sampleRate = parameters.sampleRate
            let data = try await Task.detached {
                try PoseCacheCodec.encode(frames, sampleRate: sampleRate)
            }.value
            let filename = try await fileStore.writePoseCache(data, recordingID: recording.id)
            recording.poseCacheFilename = filename
            try await fileStore.upsert(recording)
        } catch {
            print("PoomsaeAnalysisStore.persistCache:", error)
        }
    }
}

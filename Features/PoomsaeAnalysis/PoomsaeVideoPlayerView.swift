#if os(iOS)
import SwiftUI
import AVFoundation
import Observation

// MARK: - PoomsaePlayerModel
//
// Stage 2.6.a — `@Observable @MainActor` controller around a single
// `AVPlayer`. Publishes the current playback time (via a periodic time
// observer) so the skeleton overlay and the motion-energy playhead stay in
// sync, and exposes play / pause / seek for the transport and tap-to-seek.

@Observable @MainActor
public final class PoomsaePlayerModel {

    public let player = AVPlayer()
    public private(set) var currentTime: Double = 0
    public private(set) var duration: Double = 0
    public private(set) var isPlaying = false

    private var timeObserver: Any?

    public init() {}

    /// Loads a video and starts publishing time updates.
    public func load(url: URL) {
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        addTimeObserverIfNeeded()
        Task { [weak self] in
            let seconds = (try? await item.asset.load(.duration))?.seconds ?? 0
            self?.duration = seconds.isFinite ? seconds : 0
        }
    }

    public func play() { player.play(); isPlaying = true }

    public func pause() { player.pause(); isPlaying = false }

    public func togglePlay() { isPlaying ? pause() : play() }

    /// Seeks precisely to `seconds`.
    public func seek(to seconds: Double) {
        let clamped = max(0, seconds)
        player.seek(
            to: CMTime(seconds: clamped, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
        currentTime = clamped
    }

    /// Stops playback and removes the time observer — call from `onDisappear`.
    public func tearDown() {
        player.pause()
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }

    private func addTimeObserverIfNeeded() {
        guard timeObserver == nil else { return }
        let interval = CMTime(seconds: 1.0 / 30.0, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            // queue is .main, so we are already on the main actor.
            MainActor.assumeIsolated {
                guard let self else { return }
                let seconds = time.seconds
                self.currentTime = seconds.isFinite ? seconds : 0
                self.isPlaying = self.player.timeControlStatus == .playing
            }
        }
    }
}

// MARK: - PoomsaeVideoPlayerView
//
// `UIViewRepresentable` wrapping an `AVPlayerLayer`-backed view.

public struct PoomsaeVideoPlayerView: UIViewRepresentable {

    private let player: AVPlayer

    public init(player: AVPlayer) {
        self.player = player
    }

    public func makeUIView(context: Context) -> PlayerHostView {
        let view = PlayerHostView()
        view.playerLayer?.player = player
        view.playerLayer?.videoGravity = .resizeAspect
        return view
    }

    public func updateUIView(_ view: PlayerHostView, context: Context) {
        view.playerLayer?.player = player
    }
}

// MARK: - PlayerHostView

public final class PlayerHostView: UIView {
    public override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer? { layer as? AVPlayerLayer }
}
#endif

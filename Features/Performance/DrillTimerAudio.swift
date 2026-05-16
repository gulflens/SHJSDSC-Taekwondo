import Foundation
import AVFoundation
#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Audio + haptic cues for the Drill Timer.
///
/// Looks for optional bundle assets and falls back to system sounds so the
/// timer is audible the day it ships — drop coach-grade audio into
/// `Resources/Audio/` later:
///   • `timer_countdown` — short tick for the 3-2-1 count
///   • `timer_go`        — sharp cue at the start of a work interval
///   • `timer_rest`      — softer cue at the start of a rest interval
///   • `timer_finish`    — completion fanfare
///
/// Configures `.playback` so cues are heard even with the ringer muted —
/// coaches silence phones in the dojang.
@MainActor
public final class DrillTimerAudio {
    private var countdownPlayer: AVAudioPlayer?
    private var goPlayer: AVAudioPlayer?
    private var restPlayer: AVAudioPlayer?
    private var finishPlayer: AVAudioPlayer?

    private var enabled = true

    public init() {
        configureSession()
        countdownPlayer = load("timer_countdown")
        goPlayer = load("timer_go")
        restPlayer = load("timer_rest")
        finishPlayer = load("timer_finish")
    }

    public func setEnabled(_ on: Bool) { enabled = on }

    // MARK: Cues

    /// Cue played when a new step becomes active.
    public func cue(for phase: DrillTimerPhase) {
        guard enabled else { return }
        switch phase {
        case .work:
            play(goPlayer, fallback: 1005)
            impact(.heavy)
        case .rest, .roundBreak:
            play(restPlayer, fallback: 1057)
            impact(.light)
        case .prepare:
            impact(.light)
        case .finished:
            play(finishPlayer, fallback: 1025)
            notify(.success)
        }
    }

    /// Short tick for each of the last three seconds of a step.
    public func countdownTick() {
        guard enabled else { return }
        play(countdownPlayer, fallback: 1057)
        impact(.rigid)
    }

    // MARK: Private

    private func play(_ player: AVAudioPlayer?, fallback systemID: UInt32) {
        if let player {
            player.currentTime = 0
            player.play()
        } else {
            #if canImport(AudioToolbox)
            AudioServicesPlaySystemSound(SystemSoundID(systemID))
            #endif
        }
    }

    private func configureSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default,
                                    options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
        } catch {
            print("DrillTimerAudio.configureSession:", error)
        }
        #endif
    }

    private func load(_ name: String) -> AVAudioPlayer? {
        for ext in ["m4a", "mp3", "caf", "wav"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { continue }
            if let p = try? AVAudioPlayer(contentsOf: url) {
                p.prepareToPlay()
                return p
            }
        }
        return nil
    }

    // MARK: Haptics

    #if canImport(UIKit) && os(iOS)
    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.impactOccurred()
    }

    private func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    #else
    private enum ImpactStyle { case light, heavy, rigid }
    private func impact(_ style: ImpactStyle) {}
    private enum NotifyType { case success }
    private func notify(_ type: NotifyType) {}
    #endif
}

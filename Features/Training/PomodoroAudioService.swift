import Foundation
import AVFoundation
#if canImport(AudioToolbox)
import AudioToolbox
#endif

/// Plays the work/rest/whistle audio for the pomodoro engine.
///
/// Resource-loading strategy: looks for three optional asset names in the
/// app bundle. If a file is missing, falls back to a system sound or a
/// procedural sine beep so the feature works the day it's added — drop the
/// real coach-grade audio into Resources/Audio/ later (see README there).
///
///   • pomodoro_work.m4a    — energetic music loop, played during work phase
///   • pomodoro_rest.m4a    — faint ticking loop, played during rest phase
///   • pomodoro_whistle.m4a — sharp coach whistle, played at every transition
///
/// Configures `.playback` on the shared AVAudioSession so audio plays
/// through the silent switch — coaches mute their phones in the dojang.
@MainActor
public final class PomodoroAudioService {
    private var workPlayer: AVAudioPlayer?
    private var restPlayer: AVAudioPlayer?
    private var whistlePlayer: AVAudioPlayer?
    private var whistleStopper: Task<Void, Never>?

    public init() {
        configureSession()
        workPlayer = loadLooping("pomodoro_work")
        restPlayer = loadLooping("pomodoro_rest")
        whistlePlayer = loadOneShot("pomodoro_whistle")
    }

    public func playWork() {
        stopAllLoops()
        workPlayer?.currentTime = 0
        workPlayer?.play()
    }

    public func playRest() {
        stopAllLoops()
        restPlayer?.volume = 0.6
        restPlayer?.currentTime = 0
        restPlayer?.play()
    }

    /// Plays the whistle for `seconds` (1...5). When the bundled whistle
    /// asset is missing, falls back to the system "AlertTone" system sound
    /// repeatedly for the duration.
    public func playWhistle(seconds: Double) {
        stopAllLoops()
        let duration = max(1, min(5, seconds))
        whistleStopper?.cancel()

        if let player = whistlePlayer {
            player.currentTime = 0
            player.numberOfLoops = -1     // loop until stopped
            player.volume = 1
            player.play()
            whistleStopper = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                self?.stopWhistle()
            }
        } else {
            // Fallback: chain system tones for the duration.
            #if canImport(AudioToolbox)
            let beepID: SystemSoundID = 1005
            let interval: TimeInterval = 0.6
            let count = Int(duration / interval)
            for i in 0..<max(1, count) {
                DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                    AudioServicesPlaySystemSound(beepID)
                }
            }
            #endif
        }
    }

    public func stopAll() {
        stopAllLoops()
        stopWhistle()
    }

    // MARK: - Private

    private func stopWhistle() {
        whistleStopper?.cancel()
        whistleStopper = nil
        whistlePlayer?.stop()
    }

    private func stopAllLoops() {
        workPlayer?.stop()
        restPlayer?.stop()
    }

    private func configureSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
        } catch {
            print("PomodoroAudioService.configureSession:", error)
        }
        #endif
    }

    private func loadLooping(_ name: String) -> AVAudioPlayer? {
        guard let url = bundleURL(for: name) else { return nil }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.prepareToPlay()
            return p
        } catch {
            print("PomodoroAudioService.loadLooping(\(name)):", error)
            return nil
        }
    }

    private func loadOneShot(_ name: String) -> AVAudioPlayer? {
        guard let url = bundleURL(for: name) else { return nil }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()
            return p
        } catch {
            print("PomodoroAudioService.loadOneShot(\(name)):", error)
            return nil
        }
    }

    private func bundleURL(for name: String) -> URL? {
        for ext in ["m4a", "mp3", "caf", "wav"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }
}

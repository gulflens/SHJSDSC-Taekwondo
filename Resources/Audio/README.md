# Pomodoro audio assets

Drop the following files into this folder and add them to the Xcode target so
they ship in the app bundle. Until then `PomodoroAudioService` falls back to
system sounds (loops a chain of system "AlertTone" beeps for the whistle, no
work / rest audio).

| File name | Used during | Looping | Notes |
|---|---|---|---|
| `pomodoro_work.m4a` | Work intervals | Yes | Energetic music; volume rides at 1.0 |
| `pomodoro_rest.m4a` | Rest intervals | Yes | Faint ticking; volume drops to 0.6 |
| `pomodoro_whistle.m4a` | 1–5s transitions | Loops while active | Sharp coach whistle blast |

Acceptable extensions: `.m4a`, `.mp3`, `.caf`, `.wav`.

The audio session uses the `.playback` category with `.mixWithOthers` and
`.duckOthers` so:
- Audio plays even when the device's silent switch is on (gym scenario).
- Other audio (e.g. Spotify) is ducked but not stopped while the timer runs.

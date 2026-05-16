import Foundation
import LocalAuthentication

/// Drives the optional Face ID / Touch ID app lock. When `prefs.biometric`
/// is on, the app starts locked on cold launch and re-locks when sent to the
/// background; the lock screen calls `unlock()` to clear it.
@MainActor
@Observable
public final class BiometricLock {
    public private(set) var isLocked: Bool

    public init() {
        // Lock on launch only when the preference is on AND the device can
        // actually authenticate — never strand the user behind a lock the
        // hardware can't open.
        let wanted = UserDefaults.standard.bool(forKey: "prefs.biometric")
        self.isLocked = wanted && Self.canAuthenticate
    }

    public var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "prefs.biometric")
    }

    /// True when biometrics or a device passcode can be evaluated.
    public static var canAuthenticate: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    /// True when a biometric sensor (Face ID / Touch ID / Optic ID) exists.
    public static var biometryAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    public static var biometryType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    /// Re-lock when the app is backgrounded.
    public func lockIfEnabled() {
        if isEnabled && Self.canAuthenticate {
            isLocked = true
        }
    }

    /// Prompt for biometrics, falling back to the device passcode. Clears the
    /// lock on success.
    @discardableResult
    public func unlock() async -> Bool {
        guard isLocked else { return true }
        let context = LAContext()
        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: String(localized: "security.biometric.reason")
            )
            if ok { isLocked = false }
            return ok
        } catch {
            return false
        }
    }
}

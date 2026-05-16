import SwiftUI
import LocalAuthentication

/// Full-screen gate shown over the app while `BiometricLock` is locked.
/// Auto-prompts on appear; a retry button covers a cancelled prompt.
public struct BiometricLockView: View {
    @Bindable var lock: BiometricLock
    @State private var authenticating = false

    public init(lock: BiometricLock) {
        self.lock = lock
    }

    private var biometryIcon: String {
        switch BiometricLock.biometryType {
        case .faceID:  "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        default:       "lock.fill"
        }
    }

    public var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: biometryIcon)
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(.tint)
                Text("security.lock.title")
                    .scaledFont(.title2, weight: .bold)
                Text("security.lock.subtitle")
                    .scaledFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    Task { await attempt() }
                } label: {
                    HStack(spacing: 8) {
                        if authenticating {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "lock.open.fill")
                        }
                        Text("security.lock.unlock_button")
                    }
                    .scaledFont(.subheadline, weight: .semibold)
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(authenticating)
            }
            .padding(40)
            .frame(maxWidth: 420)
        }
        .task { await attempt() }
    }

    private func attempt() async {
        guard !authenticating else { return }
        authenticating = true
        await lock.unlock()
        authenticating = false
    }
}

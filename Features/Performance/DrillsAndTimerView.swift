import SwiftUI

/// Combined Drills hub. The Timer / Library mode switch lives inside each
/// screen's header (`DrillModeSwitcher`); this view owns the shared
/// `isLibrary` state and routes to the premium Drill Library or the
/// from-scratch Drill Timer (Stage 1.8).
public struct DrillsAndTimerView: View {
    @State private var isLibrary = true

    public init() {}

    public var body: some View {
        if isLibrary {
            DrillLibraryView(isLibrary: $isLibrary)
        } else {
            DrillTimerView(isLibrary: $isLibrary)
        }
    }
}

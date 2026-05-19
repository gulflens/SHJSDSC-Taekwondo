#if os(iOS)
import SwiftUI

// MARK: - PoomsaeAnalysisView
//
// Stage 2.6.a — screen (c): the analysis workspace for one recording.
//
// Layout:
//   - video player (`PoomsaeVideoPlayerView`) with the `PoomsaeSkeletonOverlay`
//     Canvas sized to the video frame
//   - extraction progress card over the player on a cache miss
//   - `MotionEnergyTimelineView` below the player
//   - `MovementSegmentListView` — side panel on iPad, sheet on iPhone
//
// Pushed subview: uses `.subviewChrome(_:)` for its navigation bar.

// MARK: - PoomsaeAnalysisView

// MARK: - Adaptive layout (iPad side panel vs iPhone sheet)
#endif

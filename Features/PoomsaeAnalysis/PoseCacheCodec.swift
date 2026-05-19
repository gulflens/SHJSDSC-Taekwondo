import Foundation

// MARK: - PoseCacheCodec
//
// Stage 2.6.a — encodes / decodes a `[PoseFrame]` sequence to and from the
// per-recording binary pose cache file (`PoseCache/<uuid>.poses`).
//
// Uses `PropertyListEncoder` with the binary format: compact, fast, and a
// natural fit for the dense numeric `PoseFrameRecord` payload. The cache lets
// a re-opened recording skip the (expensive) Vision extraction entirely.

// MARK: - encode([PoseFrame]) -> Data

// MARK: - decode(Data) -> [PoseFrame]

import Foundation
import CoreMedia
import simd

// MARK: - PoseCacheCodec
//
// Stage 2.6.a — encodes / decodes a `[PoseFrame]` sequence to and from the
// per-recording binary pose cache file (`PoseCache/<uuid>.poses`).
//
// Uses `PropertyListEncoder` in binary format. Each frame is stored as flat
// numeric arrays in `PoomsaeJoint.allCases` order — compact, fast, and free of
// the dictionary-with-enum-key encoding quirks. The cache lets a re-opened
// recording skip the (expensive) Vision extraction entirely.

// `nonisolated` — encode/decode run off the main actor (project default
// isolation is MainActor).
public nonisolated enum PoseCacheCodec {

    /// On-disk format version — bumped if the layout below changes.
    public static let version = 1

    public enum CacheError: Error { case malformed }

    // MARK: - On-disk layout

    private struct CacheFile: Codable {
        var version: Int
        var sampleRate: Double
        var frames: [FrameRecord]
    }

    /// One frame. `present` / `confidences` carry one entry per joint in
    /// `PoomsaeJoint.allCases` order; `positions` carries three (x, y, z).
    private struct FrameRecord: Codable {
        var timestamp: Double
        var present: [Bool]
        var positions: [Float]
        var confidences: [Float]
    }

    // MARK: - Encode

    public static func encode(_ frames: [PoseFrame], sampleRate: Double) throws -> Data {
        let joints = PoomsaeJoint.allCases
        let records: [FrameRecord] = frames.map { frame in
            var present: [Bool] = []
            var positions: [Float] = []
            var confidences: [Float] = []
            present.reserveCapacity(joints.count)
            positions.reserveCapacity(joints.count * 3)
            confidences.reserveCapacity(joints.count)
            for joint in joints {
                if let p = frame.position(for: joint) {
                    present.append(true)
                    positions.append(p.x)
                    positions.append(p.y)
                    positions.append(p.z)
                } else {
                    present.append(false)
                    positions.append(0)
                    positions.append(0)
                    positions.append(0)
                }
                confidences.append(frame.confidence(for: joint))
            }
            let seconds = frame.timestamp.seconds
            return FrameRecord(
                timestamp: seconds.isFinite ? seconds : 0,
                present: present,
                positions: positions,
                confidences: confidences
            )
        }
        let file = CacheFile(version: version, sampleRate: sampleRate, frames: records)
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        return try encoder.encode(file)
    }

    // MARK: - Decode

    public static func decode(_ data: Data) throws -> [PoseFrame] {
        let file = try PropertyListDecoder().decode(CacheFile.self, from: data)
        let joints = PoomsaeJoint.allCases
        return try file.frames.map { record in
            guard record.present.count == joints.count,
                  record.confidences.count == joints.count,
                  record.positions.count == joints.count * 3 else {
                throw CacheError.malformed
            }
            var jointMap: [PoomsaeJoint: SIMD3<Float>?] = [:]
            var confidenceMap: [PoomsaeJoint: Float] = [:]
            for (i, joint) in joints.enumerated() {
                if record.present[i] {
                    jointMap.updateValue(
                        SIMD3<Float>(record.positions[i * 3],
                                     record.positions[i * 3 + 1],
                                     record.positions[i * 3 + 2]),
                        forKey: joint
                    )
                } else {
                    jointMap.updateValue(nil, forKey: joint)
                }
                confidenceMap[joint] = record.confidences[i]
            }
            return PoseFrame(
                timestamp: CMTime(seconds: record.timestamp, preferredTimescale: 600),
                joints: jointMap,
                confidences: confidenceMap
            )
        }
    }
}

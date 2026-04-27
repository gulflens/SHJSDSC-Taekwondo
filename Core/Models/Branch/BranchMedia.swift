import Foundation

public struct BranchMedia: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var branchID: EntityID
    public var logoURL: String?
    public var heroPhotoURL: String?
    public var galleryURLs: [String]
    public var videoTourURL: String?
    public var floorPlanURL: String?

    public init(
        id: EntityID = UUID(),
        branchID: EntityID,
        logoURL: String? = nil,
        heroPhotoURL: String? = nil,
        galleryURLs: [String] = [],
        videoTourURL: String? = nil,
        floorPlanURL: String? = nil
    ) {
        self.id = id
        self.branchID = branchID
        self.logoURL = logoURL
        self.heroPhotoURL = heroPhotoURL
        self.galleryURLs = galleryURLs
        self.videoTourURL = videoTourURL
        self.floorPlanURL = floorPlanURL
    }
}

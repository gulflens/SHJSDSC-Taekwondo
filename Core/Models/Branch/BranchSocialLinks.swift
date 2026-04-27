import Foundation

public struct BranchSocialLinks: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var branchID: EntityID
    public var whatsappParentsLink: String?
    public var whatsappAthletesLink: String?
    public var telegramChannelLink: String?
    public var instagramHandle: String?
    public var tiktokHandle: String?
    public var youtubeChannelURL: String?
    public var websiteURL: String?

    public init(
        id: EntityID = UUID(),
        branchID: EntityID,
        whatsappParentsLink: String? = nil,
        whatsappAthletesLink: String? = nil,
        telegramChannelLink: String? = nil,
        instagramHandle: String? = nil,
        tiktokHandle: String? = nil,
        youtubeChannelURL: String? = nil,
        websiteURL: String? = nil
    ) {
        self.id = id
        self.branchID = branchID
        self.whatsappParentsLink = whatsappParentsLink
        self.whatsappAthletesLink = whatsappAthletesLink
        self.telegramChannelLink = telegramChannelLink
        self.instagramHandle = instagramHandle
        self.tiktokHandle = tiktokHandle
        self.youtubeChannelURL = youtubeChannelURL
        self.websiteURL = websiteURL
    }
}

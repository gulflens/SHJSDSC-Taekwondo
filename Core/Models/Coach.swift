import Foundation

public enum ContractType: String, Codable, CaseIterable, Sendable, Hashable {
    case fullTime, partTime, contractor
}

public struct Coach: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var fullName: String
    public var fullNameAr: String
    public var primaryBranchID: EntityID
    public var secondaryBranchIDs: [EntityID]
    public var danRank: Int
    public var wtCoachLicenceLevel: Int
    public var firstAidExpiry: Date
    public var safeguardingExpiry: Date
    public var contractType: ContractType
    public var hiredAt: Date
    public var avatarSeed: String

    public init(
        id: EntityID = UUID(),
        fullName: String,
        fullNameAr: String,
        primaryBranchID: EntityID,
        secondaryBranchIDs: [EntityID] = [],
        danRank: Int,
        wtCoachLicenceLevel: Int,
        firstAidExpiry: Date,
        safeguardingExpiry: Date,
        contractType: ContractType,
        hiredAt: Date,
        avatarSeed: String
    ) {
        self.id = id
        self.fullName = fullName
        self.fullNameAr = fullNameAr
        self.primaryBranchID = primaryBranchID
        self.secondaryBranchIDs = secondaryBranchIDs
        self.danRank = danRank
        self.wtCoachLicenceLevel = wtCoachLicenceLevel
        self.firstAidExpiry = firstAidExpiry
        self.safeguardingExpiry = safeguardingExpiry
        self.contractType = contractType
        self.hiredAt = hiredAt
        self.avatarSeed = avatarSeed
    }

    public var initials: String {
        let parts = fullName.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }
}

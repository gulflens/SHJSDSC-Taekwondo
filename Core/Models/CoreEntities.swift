import Foundation

public typealias EntityID = UUID

public enum Role: String, Codable, CaseIterable, Sendable, Hashable {
    case developer
    case admin
    case technicalDirector
    case branchManager
    case coach
    case athlete
    case parent
    case analyst

    public var label: String {
        switch self {
        case .developer: "role.developer"
        case .admin: "role.admin"
        case .technicalDirector: "role.technicalDirector"
        case .branchManager: "role.branchManager"
        case .coach: "role.coach"
        case .athlete: "role.athlete"
        case .parent: "role.parent"
        case .analyst: "role.analyst"
        }
    }
}

public struct User: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var fullName: String
    public var fullNameAr: String
    public var role: Role
    public var primaryBranchID: EntityID?
    public var avatarSeed: String
    public var linkedAthleteIDs: [EntityID]

    public init(
        id: EntityID = UUID(),
        fullName: String,
        fullNameAr: String,
        role: Role,
        primaryBranchID: EntityID? = nil,
        avatarSeed: String,
        linkedAthleteIDs: [EntityID] = []
    ) {
        self.id = id
        self.fullName = fullName
        self.fullNameAr = fullNameAr
        self.role = role
        self.primaryBranchID = primaryBranchID
        self.avatarSeed = avatarSeed
        self.linkedAthleteIDs = linkedAthleteIDs
    }
}

public struct Branch: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var code: String
    public var name: String
    public var nameAr: String
    public var area: String
    public var capacity: Int
    public var managerID: EntityID?
    public var focus: String

    public init(
        id: EntityID = UUID(),
        code: String,
        name: String,
        nameAr: String,
        area: String,
        capacity: Int,
        managerID: EntityID? = nil,
        focus: String
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.nameAr = nameAr
        self.area = area
        self.capacity = capacity
        self.managerID = managerID
        self.focus = focus
    }
}

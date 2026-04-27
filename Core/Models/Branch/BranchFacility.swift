import Foundation

public struct HallSpec: Codable, Hashable, Sendable {
    public var name: String
    public var lengthM: Double
    public var widthM: Double
    public var matSpec: String?
    public var isCompetitionGrade: Bool

    public init(
        name: String,
        lengthM: Double,
        widthM: Double,
        matSpec: String? = nil,
        isCompetitionGrade: Bool = false
    ) {
        self.name = name
        self.lengthM = lengthM
        self.widthM = widthM
        self.matSpec = matSpec
        self.isCompetitionGrade = isCompetitionGrade
    }

    public var areaSqm: Double { lengthM * widthM }
}

public struct BranchFacility: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var branchID: EntityID
    public var floorAreaSqm: Double
    public var hallCount: Int
    public var hallDimensions: [HallSpec]
    public var hasMirrorWalls: Bool
    public var hasSoundSystem: Bool
    public var hasAC: Bool
    public var hasInstalledScoreboard: Bool
    public var hasPSS: Bool
    public var pssBrand: String?
    public var pssLastCalibrationAt: Date?
    public var changingRoomsM: Int
    public var changingRoomsF: Int
    public var spectatorSeats: Int
    public var parkingSpots: Int
    public var hasPrayerRoom: Bool
    public var hasWudu: Bool
    public var floorPlanFileRef: String?
    public var photoURLs: [String]

    public init(
        id: EntityID = UUID(),
        branchID: EntityID,
        floorAreaSqm: Double,
        hallCount: Int,
        hallDimensions: [HallSpec] = [],
        hasMirrorWalls: Bool = false,
        hasSoundSystem: Bool = false,
        hasAC: Bool = true,
        hasInstalledScoreboard: Bool = false,
        hasPSS: Bool = false,
        pssBrand: String? = nil,
        pssLastCalibrationAt: Date? = nil,
        changingRoomsM: Int = 0,
        changingRoomsF: Int = 0,
        spectatorSeats: Int = 0,
        parkingSpots: Int = 0,
        hasPrayerRoom: Bool = false,
        hasWudu: Bool = false,
        floorPlanFileRef: String? = nil,
        photoURLs: [String] = []
    ) {
        self.id = id
        self.branchID = branchID
        self.floorAreaSqm = floorAreaSqm
        self.hallCount = hallCount
        self.hallDimensions = hallDimensions
        self.hasMirrorWalls = hasMirrorWalls
        self.hasSoundSystem = hasSoundSystem
        self.hasAC = hasAC
        self.hasInstalledScoreboard = hasInstalledScoreboard
        self.hasPSS = hasPSS
        self.pssBrand = pssBrand
        self.pssLastCalibrationAt = pssLastCalibrationAt
        self.changingRoomsM = changingRoomsM
        self.changingRoomsF = changingRoomsF
        self.spectatorSeats = spectatorSeats
        self.parkingSpots = parkingSpots
        self.hasPrayerRoom = hasPrayerRoom
        self.hasWudu = hasWudu
        self.floorPlanFileRef = floorPlanFileRef
        self.photoURLs = photoURLs
    }
}

import Foundation

public nonisolated struct AuditEntry: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var at: Date
    public var actorUserID: EntityID
    public var action: String
    public var targetEntity: String
    public var targetID: EntityID
    public var changes: [String: String]

    public init(
        id: EntityID = UUID(),
        at: Date = Date(),
        actorUserID: EntityID,
        action: String,
        targetEntity: String,
        targetID: EntityID,
        changes: [String: String] = [:]
    ) {
        self.id = id
        self.at = at
        self.actorUserID = actorUserID
        self.action = action
        self.targetEntity = targetEntity
        self.targetID = targetID
        self.changes = changes
    }
}

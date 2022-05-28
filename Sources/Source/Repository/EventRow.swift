public struct EntityData {
    public let id: String
    public let type: String

    public init(id: String, type: String) {
        self.id = id
        self.type = type
    }
}

public struct EventRow {
    public let entity: EntityData
    public let name: String
    public let details: String
    public let actor: String
    public let timestamp: Double

    public init(entity: EntityData, name: String, details: String, actor: String, timestamp: Double) {
        self.entity = entity
        self.name = name
        self.details = details
        self.actor = actor
        self.timestamp = timestamp
    }
}

public struct History {
    public let type: String
    public let events: [PublishedEvent]
    public let version: EntityVersion

    public init(type: String, events: [PublishedEvent], version: EntityVersion) {
        self.type = type
        self.events = events
        self.version = version
    }

    public func reconstitute<EntityType: Entity>() throws -> EntityType {
        guard EntityType.type == type else {
            throw ReconstitutionError.incorrectType
        }

        let entity = EntityType(version: version)
        for event in events { entity.apply(event) }
        return entity
    }
}

public enum ReconstitutionError: Error {
    case incorrectType
}

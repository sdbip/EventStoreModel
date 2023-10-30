/// A data structure that details the history of an ``Entity``.
public struct History {
    /// The `id` of the ``Entity``
    public let id: String
    /// The `typeId` of the associated ``Entity`` implementation
    public let type: String
    /// The published events (official state) of the ``Entity``
    public let events: [PublishedEvent]
    /// The stored `version` number of the ``Entity``
    public let version: EntityVersion

    public init(id: String, type: String, events: [PublishedEvent], version: EntityVersion) {
        self.id = id
        self.type = type
        self.events = events
        self.version = version
    }

    /// Initializes the ``Entity`` object that is represented by this ``History``
    public func entity<EntityType: Entity>() throws -> EntityType {
        guard EntityType.typeId == type else {
            throw ReconstitutionError.incorrectType
        }

        let entity = EntityType(snapshotId: SnapshotId(entityId: id, version: version))
        for event in events { entity.replay(event) }
        return entity
    }
}

public enum ReconstitutionError: Error {
    case incorrectType
}

public struct History {
    public let id: String
    public let type: String
    public let events: [PublishedEvent]
    public let version: EntityVersion

    public init(id: String, type: String, events: [PublishedEvent], version: EntityVersion) {
        self.id = id
        self.type = type
        self.events = events
        self.version = version
    }

    public func entity<State: EntityState>() throws -> Entity<State> {
        guard State.typeId == type else {
            throw ReconstitutionError.incorrectType
        }

        let entity = Entity<State>(id: id, version: version)
        for event in events { entity.state.replay(event) }
        return entity
    }
}

public enum ReconstitutionError: Error {
    case incorrectType
}

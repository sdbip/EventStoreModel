/// A data structure that details the history of an ``Entity``.
public struct History {
    /// The `id` of the ``Entity``
    public let id: String
    /// The `type` of the associated ``EntityState``
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
    public func entity<State: EntityState>() throws -> Entity<State> {
        guard State.typeId == type else {
            throw ReconstitutionError.incorrectType
        }

        return Entity(id: id, state: State(events: events), version: version)
    }
}

public enum ReconstitutionError: Error {
    case incorrectType
}

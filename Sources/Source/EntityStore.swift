import Foundation

/// The tool for reconstituting entities from their published events.
///
/// Use in concert with an ``EventPublisher``:
/// ```
/// let store: EntityStore = ...
/// let publisher: EventPublisher = ...
///
/// let entity = try store.reconstitute(entityWithId: "the id") as Entity<MyEntityState>
/// entity.state.performOperations()
/// try publisher.publishChanges(entity)
/// ```
public struct EntityStore {
    private let secondsPerDay = 86_400.0
    private let repository: EntityStoreRepository

    /// Initializes an ``EntityStore`` with a backing database adapter.
    public init(repository: EntityStoreRepository) {
        self.repository = repository
    }

    /// Get the stored type-name for the entity with a given id
    public func type(ofEntityWithId id: String) throws -> String? {
        return try repository.type(ofEntityRowWithId: id)
    }

    /// Reconstitute an entity from its published events.
    ///
    /// - Throws: if the associated ``EntityState`` has the wrong `type` identifier.
    /// - Throws: If the database operation fails
    public func reconstitute<State: EntityState>(entityWithId id: String) throws -> Entity<State>? {
        guard let history = try history(forEntityWithId: id) else { return nil }
        return try history.entity()
    }

    /// Fetch the entire history of an ``Entity``
    ///
    /// - Throws: If the database operation fails
    public func history(forEntityWithId id: String) throws -> History? {
        guard let entityRow = try repository.entityRow(withId: id) else { return nil }
        let eventRows = try repository.allEventRows(forEntityWithId: id).map {
            PublishedEvent(name: $0.name, details: $0.details, actor: $0.actor, timestamp: Date(timeIntervalSince1970: $0.timestamp * secondsPerDay))
        }
        return History(id: entityRow.id, type: entityRow.type, events: eventRows, version: .eventCount(entityRow.version))
    }
}

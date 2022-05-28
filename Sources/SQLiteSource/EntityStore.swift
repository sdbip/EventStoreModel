import Foundation
import SQLite3

import Source
import SQLite

public struct EntityStore {
    private let repository: Database

    public init(repository: Database) {
        self.repository = repository
    }

    public func nextPosition() throws -> Int64 {
        return try repository.nextPosition()
    }

    public func type(ofEntityWithId id: String) throws -> String? {
        return try repository.type(ofEntityRowWithId: id)
    }

    public func reconstitute<State: EntityState>(entityWithId id: String) throws -> Entity<State>? {
        guard let history = try history(forEntityWithId: id) else { return nil }
        return try history.entity()
    }

    public func history(forEntityWithId id: String) throws -> History? {
        guard let entityRow = try repository.entityRow(withId: id) else { return nil }
        let eventRows = try repository.allEventRows(forEntityWithId: id).map {
            PublishedEvent(name: $0.name, details: $0.details, actor: $0.actor, timestamp: $0.timestamp)
        }
        return History(id: entityRow.id, type: entityRow.type, events: eventRows, version: .eventCount(entityRow.version))
    }
}

import Foundation
import SQLite3

import Source
import SQLite

public struct EntityStore {
    private let dbFile: String

    public init(dbFile: String) {
        self.dbFile = dbFile
    }

    public func nextPosition() throws -> Int64 {
        let database = try Database(openFile: dbFile)
        return try database.nextPosition()
    }

    public func type(ofEntityWithId id: String) throws -> String? {
        let database = try Database(openFile: dbFile)
        return try database.type(ofEntityRowWithId: id)
    }

    public func reconstitute<State: EntityState>(entityWithId id: String) throws -> Entity<State>? {
        guard let history = try history(forEntityWithId: id) else { return nil }
        return try history.entity()
    }

    public func history(forEntityWithId id: String) throws -> History? {
        let database = try Database(openFile: dbFile)
        guard let entityRow = try database.entityRow(withId: id) else { return nil }
        let eventRows = try database.allEventRows(forEntityWithId: id).map {
            PublishedEvent(name: $0.name, details: $0.details, actor: $0.actor, timestamp: $0.timestamp)
        }
        return History(id: entityRow.id, type: entityRow.type, events: eventRows, version: .eventCount(entityRow.version))
    }
}

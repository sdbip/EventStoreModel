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
        return try database.type(ofEntityWithId: id)
    }

    public func reconstitute<State: EntityState>(entityWithId id: String) throws -> Entity<State>? {
        guard let history = try history(forEntityWithId: id) else { return nil }
        return try history.entity()
    }

    public func history(forEntityWithId id: String) throws -> History? {
        let database = try Database(openFile: dbFile)
        return try database.history(forEntityWithId: id)
    }
}

private extension Database {
    func history(forEntityWithId entityId: String) throws -> History? {
        return try transaction {
            guard let entity = try entity(withId: entityId) else { return nil }
            let events = try allEvents(forEntityWithId: entityId).map {
                PublishedEvent(name: $0.name, details: $0.details, actor: $0.actor, timestamp: $0.timestamp)
            }
            return History(id: entity.id, type: entity.type, events: events, version: .eventCount(entity.version))
        }
    }
}

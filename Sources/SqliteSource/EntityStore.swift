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
            let events = try allEvents(forEntityWithId: entityId)

            let operation = try operation(
                "SELECT * FROM Entities WHERE id = ? ORDER BY version",
                entityId
            )
            return try operation.single {
                guard let type = $0.string(at: 1) else { throw SQLiteError.message("Entity has no type") }
                return History(id: entityId, type: type, events: events, version: .eventCount($0.int32(at: 2)))
            }
        }
    }

    private func allEvents(forEntityWithId entityId: String) throws -> [PublishedEvent] {
        return try self.operation("SELECT * FROM Events WHERE entity = ?", entityId)
            .query {
                guard let name = $0.string(at: 1) else { throw SQLiteError.message("Event has no name") }
                guard let details = $0.string(at: 2) else { throw SQLiteError.message("Event has no details") }
                guard let actor = $0.string(at: 3) else { throw SQLiteError.message("Event has no actor") }
                return PublishedEvent(name: name, details: details, actor: actor, timestamp: $0.date(at: 4))
            }
    }
}

// Swift reference date is January 1, 2001 CE @ 0:00:00
// Julian Day 0 is November 24, 4714 BCE @ 12:00:00
// Those dates are 2451910.5 days apart.
let julianDayAtReferenceDate = 2451910.5
let secondsPerDay = 86_400 as Double
extension ResultRow {
    public func date(at column: Int32) -> Date {
        let julianDay = double(at: column)
        let timeInterval = (julianDay - julianDayAtReferenceDate) * secondsPerDay
        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }
}

import Foundation
import SQLite3

import Source
import SQLite

public struct EntityStore {
    private let dbFile: String

    public init(dbFile: String) {
        self.dbFile = dbFile
    }

    public func reconstitute<EntityType: Entity>(entityWithId id: String) throws -> EntityType? {
        guard let history = try getHistory(id: id) else { return nil }
        return try history.entity()
    }

    public func getHistory(id: String) throws -> History? {
        let connection = try Connection(openFile: dbFile)

        return try connection.transaction {
            let events = try connection.allEvents(forEntityWithId: id)

            let operation = try connection.operation(
                "SELECT * FROM Entities WHERE id = ?1 ORDER BY version",
                id
            )
            return try operation.single { row in
                guard let type = row.string(at: 1) else { throw SQLiteError.message("Entity has no type") }
                return History(id: id, type: type, events: events, version: .version(row.int32(at: 2)))
            }
        }
    }
}

private extension Connection {
    func allEvents(forEntityWithId entityId: String) throws -> [PublishedEvent] {
        return try self.operation("SELECT * FROM Events WHERE entity = ?", entityId)
            .query { row -> PublishedEvent in
                guard let name = row.string(at: 1) else { throw SQLiteError.message("Event has no name") }
                guard let details = row.string(at: 2) else { throw SQLiteError.message("Event has no details") }
                guard let actor = row.string(at: 3) else { throw SQLiteError.message("Event has no actor") }
                return PublishedEvent(name: name, details: details, actor: actor, timestamp: row.date(at: 4))
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

import Foundation
import SQLite3

import Source
import SQLite

private let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

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

        let statement1 = try Statement(prepare: "SELECT * FROM Events WHERE entity = ?1", connection: connection)
        statement1.bind(id, to: 1)

        let events = try statement1.query { row -> PublishedEvent in
            guard let name = row.string(at: 1) else { throw SQLiteError.message("Event has no name") }
            guard let details = row.string(at: 2) else { throw SQLiteError.message("Event has no details") }
            guard let actor = row.string(at: 3) else { throw SQLiteError.message("Event has no actor") }
            return PublishedEvent(name: name, details: details, actor: actor, timestamp: Date(julianDay: row.double(at: 4)))
        }

        let statement2 = try Statement(prepare: "SELECT * FROM Entities WHERE id = ?1", connection: connection)
        statement2.bind(id, to: 1)
        return try statement2.single { row in
            guard let type = row.string(at: 1) else { throw SQLiteError.message("Entity has no type") }
            return History(id: id, type: type, events: events, version: .version(row.int32(at: 2)))
        }
    }
}

// Swift reference date is January 1, 2001 CE @ 0:00:00
// Julian Day 0 is November 24, 4714 BCE @ 12:00:00
// Those dates are 2451910.5 days apart.
let julianDayAtReferenceDate = 2451910.5
let secondsPerDay = 86_400 as Double
extension Date {
    public init(julianDay: Double) {
        self.init(timeIntervalSinceReferenceDate: (julianDay - julianDayAtReferenceDate) * secondsPerDay)
    }
}

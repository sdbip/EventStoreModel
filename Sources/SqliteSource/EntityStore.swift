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

    public func addSchema() throws {
        let connection = try DbConnection(openFile: dbFile)

        try connection.execute("""
            create table if not exists Entities (
                id string primary key,
                type text,
                version int
            );
            create table if not exists Events (
                entity string references Entities(id),
                name text,
                details text,
                actor text,
                timestamp real not null default (julianday('now', 'utc')),
                version int,
                position bigint
            )
            """)
        try connection.close()
    }

    public func getHistory(id: String) throws -> History? {
        let connection = try DbConnection(openFile: dbFile)
        let statement = try Statement(prepare: "SELECT * FROM Entities WHERE id = '" + id + "'", connection: connection)

        return try statement.single { row in
            guard let type = row.string(at: 1) else { throw SQLiteError.message("Entity has no type") }
            return History(type: type, events: [], version: .version(row.int32(at: 2)))
        }
    }
}

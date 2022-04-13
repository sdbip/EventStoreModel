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

    public func getHistory(id: String) throws -> History {
        let connection = try DbConnection(openFile: dbFile)
        let statement = try Statement(prepare: "SELECT * FROM Entities WHERE id = '" + id + "'", connection: connection)

        guard sqlite3_step(statement.pointer) == SQLITE_ROW else { throw connection.lastError() }

        let type = sqlite3_column_text(statement.pointer, 1)
        let version = sqlite3_column_int64(statement.pointer, 2)

        guard let type = type else {
            throw SQLiteError.message("type is null")
        }

        return History(type: String(cString: type), events: [], version: .version(Int32(version)))
    }
}

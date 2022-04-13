import SQLite3

import SQLite

private let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public struct EntityStore {

    public init() {}

    public func addSchema(dbFile: String) {
        guard let connection = DbConnection(openFile: dbFile) else { return }

        sqlite3_exec(connection.pointer, """
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
            """, nil, nil, nil)
        sqlite3_close(connection.pointer)
    }

}

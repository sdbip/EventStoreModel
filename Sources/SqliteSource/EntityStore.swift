import SQLite3

private let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public struct EntityStore {

    public init() {}

    public func addSchema(dbFile: String) {
        var connection: OpaquePointer?
        sqlite3_open(dbFile, &connection) // == SQLITE_OK
        sqlite3_exec(connection, """
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
        sqlite3_close(connection)
    }

}

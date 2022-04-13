import SQLite3

public struct Statement {
    public let pointer: OpaquePointer
    private let connection: DbConnection

    public init(prepare sql: String, connection: DbConnection) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection.pointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw connection.lastError()
        }
        self.pointer = statement!
        self.connection = connection
    }

    public func execute() throws {
        sqlite3_step(self.pointer)
/*        guard [SQLITE_OK, SQLITE_ROW].contains(sqlite3_step(self.pointer)) else {
            throw connection.lastError()
        }*/

        guard sqlite3_finalize(self.pointer) == SQLITE_OK else {
            throw connection.lastError()
        }
    }
}

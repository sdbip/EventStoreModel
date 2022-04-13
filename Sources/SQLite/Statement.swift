import SQLite3

public struct Statement {
    private let pointer: OpaquePointer
    private let connection: DbConnection

    public init(prepare sql: String, connection: DbConnection) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection.pointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.lastError(connection: connection.pointer)
        }
        self.pointer = statement!
        self.connection = connection
    }

    public func execute() throws {
        guard sqlite3_finalize(self.pointer) == SQLITE_OK else {
            throw SQLiteError.lastError(connection: self.connection.pointer)
        }
    }
}

import SQLite3

public struct DbConnection {
    internal let pointer: OpaquePointer

    public init(openFile file: String) throws {
        var connection: OpaquePointer?
        guard sqlite3_open(file, &connection) == SQLITE_OK else {
            throw SQLiteError.lastError(connection: connection)
        }
        self.pointer = connection!
    }

    public func execute(_ statement: String) throws {
        if sqlite3_exec(self.pointer, statement, nil, nil, nil) != SQLITE_OK {
            throw self.lastError()
        }
    }

    public func close() throws {
        if sqlite3_close(self.pointer) != SQLITE_OK {
            throw self.lastError()
        }
    }

    public func lastError() -> SQLiteError {
        SQLiteError.lastError(connection: self.pointer)
    }
}

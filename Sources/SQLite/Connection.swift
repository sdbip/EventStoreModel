import SQLite3

public struct Connection {
    internal let pointer: OpaquePointer

    public init(openFile file: String) throws {
        var connection: OpaquePointer?
        guard sqlite3_open(file, &connection) == SQLITE_OK else {
            throw SQLiteError.lastError(connection: connection)
        }
        pointer = connection!
    }

    public func operation(_ sql: String, _ parameters: Bindable...) throws -> Operation {
        return try Operation(connection: self, sql: sql, parameters)
    }

    public func transaction(do block: () throws -> Void)  rethrows {
        sqlite3_exec(self.pointer, "BEGIN", nil, nil, nil)
        do {
            try block()
            sqlite3_exec(self.pointer, "COMMIT", nil, nil, nil)
        } catch {
            sqlite3_exec(self.pointer, "ROLLBACK", nil, nil, nil)
            throw error
        }
    }

    public func execute(_ statement: String) throws {
        if sqlite3_exec(pointer, statement, nil, nil, nil) != SQLITE_OK {
            throw lastError()
        }
    }

    public func close() throws {
        if sqlite3_close(pointer) != SQLITE_OK {
            throw lastError()
        }
    }

    public func lastError() -> SQLiteError {
        SQLiteError.lastError(connection: pointer)
    }
}

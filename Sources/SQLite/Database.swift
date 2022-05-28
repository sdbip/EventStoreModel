import SQLite3

public class Database {
    let connection: OpaquePointer

    public init(openFile file: String) throws {
        var connection: OpaquePointer?
        guard sqlite3_open(file, &connection) == SQLITE_OK else {
            throw SQLiteError.lastError(connection: connection)
        }
        self.connection = connection!
    }

    public func operation(_ sql: String, _ parameters: Bindable...) throws -> Operation {
        return try Operation(database: self, sql: sql, parameters)
    }

    public func execute(_ statement: String) throws {
        if sqlite3_exec(connection, statement, nil, nil, nil) != SQLITE_OK {
            throw lastError()
        }
    }

    public func close() throws {
        if sqlite3_close(connection) != SQLITE_OK {
            throw lastError()
        }
    }

    public func lastError() -> SQLiteError {
        SQLiteError.lastError(connection: connection)
    }
}

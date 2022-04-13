import SQLite3

public struct DbConnection {
    public let pointer: OpaquePointer

    public init(openFile file: String) throws {
        var connection: OpaquePointer?
        guard sqlite3_open(file, &connection) == SQLITE_OK else {
            throw SQLiteError.lastError(connection: connection)
        }
        self.pointer = connection!
    }

    public func execute(_ statement: String) throws {
        if sqlite3_exec(self.pointer, statement, nil, nil, nil) != SQLITE_OK {
            throw SQLiteError.lastError(connection: self.pointer)
        }
    }

    public func close() throws {
        if sqlite3_close(self.pointer) != SQLITE_OK {
            throw SQLiteError.lastError(connection: self.pointer)
        }
    }
}

enum SQLiteError: Error {
    case unknown
    case message(String)

    static func lastError(connection: OpaquePointer?) -> SQLiteError {
        guard let msg = sqlite3_errmsg(connection) else { return .unknown }
        return .message(String(cString: msg))
    }
}

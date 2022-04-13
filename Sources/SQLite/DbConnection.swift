import SQLite3

public struct DbConnection {
    public let pointer: OpaquePointer

    public init(openFile file: String) throws {
        var connection: OpaquePointer?
        guard sqlite3_open(file, &connection) == SQLITE_OK,
            let connection = connection else {
            let errmsg = String(cString: sqlite3_errmsg(connection)!)
            throw SQLiteError.message(errmsg)
        }
        self.pointer = connection
    }

    public func execute(_ statement: String) throws {
        if sqlite3_exec(self.pointer, statement, nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(self.pointer)!)
            throw SQLiteError.message(errmsg)
        }
    }

    public func close() throws {
        if sqlite3_close(self.pointer) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(self.pointer)!)
            throw SQLiteError.message(errmsg)
        }
    }
}

enum SQLiteError: Error {
    case message(String)
}

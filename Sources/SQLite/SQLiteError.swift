import SQLite3

public enum SQLiteError: Error {
    case unknown
    case message(String)

    static func lastError(connection: OpaquePointer?) -> SQLiteError {
        guard let msg = sqlite3_errmsg(connection) else { return .unknown }
        return .message(String(cString: msg))
    }
}

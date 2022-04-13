import SQLite3

public struct DbConnection {
    public let pointer: OpaquePointer

    public init?(openFile file: String) {
        var connection: OpaquePointer?
        guard sqlite3_open(file, &connection) == SQLITE_OK else { return nil }
        guard let connection = connection else { return nil }
        self.pointer = connection
    }
}

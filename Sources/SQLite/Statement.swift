import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public struct Statement {
    private let pointer: OpaquePointer
    private let connection: Connection

    public init(prepare sql: String, connection: Connection) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection.pointer, sql, Int32(sql.utf8.count), &statement, nil) == SQLITE_OK else {
            throw connection.lastError()
        }
        guard let statement = statement else {
            throw SQLiteError.message("Failed to prepare statement. No error reported from SQLite, but statement variable not initialized.")
        }
        pointer = statement
        self.connection = connection
    }

    public func bind(_ value: String, to index: Int32) {
        sqlite3_bind_text(pointer, index, value, -1, SQLITE_TRANSIENT)
    }

    public func bind(_ value: Int32, to index: Int32) {
        sqlite3_bind_int(pointer, index, value)
    }

    public func execute() throws {
        guard sqlite3_step(pointer) == SQLITE_DONE else {
            throw connection.lastError()
        }

        guard sqlite3_finalize(pointer) == SQLITE_OK else {
            throw connection.lastError()
        }
    }

    public func single<T>(read: (ResultRow) throws -> T) throws -> T? {
        return try query(read: read).first
    }

    public func query<T>(read: (ResultRow) throws -> T) throws -> [T] {
        var result: [T] = []

        while sqlite3_step(pointer) == SQLITE_ROW {
            result.append(try read(ResultRow(pointer: pointer)))
        }

        guard sqlite3_finalize(pointer) == SQLITE_OK else {
            throw connection.lastError()
        }

        return result
    }
}

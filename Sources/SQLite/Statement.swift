import SQLite3

public struct Statement {
    private let pointer: OpaquePointer
    private let connection: Connection

    public init(prepare sql: String, connection: Connection) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection.pointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw connection.lastError()
        }
        pointer = statement!
        self.connection = connection
    }

    public func bind(_ value: String, to index: Int32) {
        sqlite3_bind_text(pointer, index, value, Int32(value.count), nil)
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

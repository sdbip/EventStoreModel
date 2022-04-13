import SQLite3

public struct Statement {
    public let pointer: OpaquePointer
    private let connection: DbConnection

    public init(prepare sql: String, connection: DbConnection) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection.pointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw connection.lastError()
        }
        pointer = statement!
        self.connection = connection
    }

    public func execute() throws {
        sqlite3_step(pointer)

        guard sqlite3_finalize(pointer) == SQLITE_OK else {
            throw connection.lastError()
        }
    }

    public func query<T>(read: (Statement) throws -> T) throws -> [T] {
        var result: [T] = []

        while sqlite3_step(pointer) == SQLITE_ROW {
            result.append(try read(self))
        }

        guard sqlite3_finalize(pointer) == SQLITE_OK else {
            throw connection.lastError()
        }

        return result
    }
}

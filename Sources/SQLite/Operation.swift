import SQLite3

public struct Operation {
    private let statement: OpaquePointer
    private let database: Database

    public init(database: Database, sql: String, _ parameters: [Bindable]) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database.connection, sql, Int32(sql.utf8.count), &statement, nil) == SQLITE_OK else {
            throw database.lastError()
        }
        guard let statement = statement else {
            throw SQLiteError.message("Failed to prepare statement. No error reported from SQLite, but statement variable not initialized.")
        }
        self.statement = statement
        self.database = database

        for (i, parameter) in parameters.enumerated() {
            if parameter.statusCode(bindingTo: statement, at: Int32(i + 1)) != SQLITE_OK {
                throw database.lastError()
            }
        }
    }

    public func execute() throws {
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw database.lastError()
        }

        guard sqlite3_finalize(statement) == SQLITE_OK else {
            throw database.lastError()
        }
    }

    public func single<T>(read: (ResultRow) throws -> T) throws -> T? {
        return try query(read: read).first
    }

    public func query<T>(read: (ResultRow) throws -> T) throws -> [T] {
        var result: [T] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            result.append(try read(ResultRow(pointer: statement)))
        }

        guard sqlite3_finalize(statement) == SQLITE_OK else {
            throw database.lastError()
        }

        return result
    }
}

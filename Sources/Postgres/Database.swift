import PostgresClientKit

public final class Database {
    public let connection : Connection

    public init(connection: Connection) {
        self.connection = connection
    }

    public func operation(_ sql: String) throws -> Operation {
        return try Operation(sql: sql, connection: connection)
    }
}

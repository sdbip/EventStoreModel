import PostgresClientKit

public final class Database {
    public let connection : Connection

    public init(connection: Connection) {
        self.connection = connection
    }
}

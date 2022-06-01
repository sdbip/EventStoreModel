import PostgresClientKit

public struct Host {
    let host: String
    let port: Int
    let useSSL: Bool

    public init(_ host: String, port: Int = 5432, useSSL: Bool = true) {
        self.host = host
        self.port = port
        self.useSSL = useSSL
    }
}

public final class Database {
    public let connection : Connection

    public init(connection: Connection) {
        self.connection = connection
    }

    public static func connect(host: Host, database: String, username: String, password: String? = nil) throws -> Database {
        var config = ConnectionConfiguration()
        config.host = host.host
        config.port = host.port
        config.database = database
        config.ssl = host.useSSL

        config.user = username
        if let password = password { config.credential = Credential.md5Password(password: password) }

        return Database(connection: try Connection(configuration: config))
    }

    public func operation(_ sql: String, parameters: PostgresValueConvertible?...) throws -> Operation {
        return try operation(sql, parameters: parameters)
    }

    public func operation(_ sql: String, parameters: [PostgresValueConvertible?] = []) throws -> Operation {
        return try Operation(sql: sql, connection: connection, parameters: parameters)
    }
}

import PostgresClientKit

public struct Host {
    public var host: String
    public var port: Int
    public var database: String?
    public var useSSL: Bool

    public init(_ host: String, port: Int? = nil, database: String? = nil, useSSL: Bool = true) {
        self.host = host
        self.port = port ?? 5432
        self.database = database
        self.useSSL = useSSL
    }
}

public struct Credentials {
    public var username: String
    public var password: String?
    
    public init(username: String, password: String? = nil) {
        self.username = username
        self.password = password
    }
}

public final class Database {
    public let connection : Connection

    public init(connection: Connection) {
        self.connection = connection
    }

    public static func connect(host: Host, credentials: Credentials) throws -> Database {
        let config = ConnectionConfiguration(host: host, credentials: credentials)
        return Database(connection: try Connection(configuration: config))
    }

    public func operation(_ sql: String, parameters: PostgresValueConvertible?...) throws -> Operation {
        return try operation(sql, parameters: parameters)
    }

    public func operation(_ sql: String, parameters: [PostgresValueConvertible?] = []) throws -> Operation {
        return try Operation(sql: sql, connection: connection, parameters: parameters)
    }
}

extension ConnectionConfiguration {
    init(host: Host, credentials: Credentials) {
        self.init()
        self.host = host.host
        self.port = host.port
        self.ssl = host.useSSL
        self.database = host.database ?? self.database

        self.user = credentials.username
        self.credential = credentials.password.map(Credential.md5Password) ?? self.credential
    }
}

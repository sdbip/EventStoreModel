import PostgresClientKit

public struct Operation {
    public let statement: Statement

    init(sql: String, connection: Connection) throws {
        statement = try connection.prepareStatement(text: sql)
    }
    
    public func execute() throws {
        try statement.execute()
    }
    
    public func single<T>(convert: ([PostgresValue]) throws -> T) throws -> T? {
        try statement.execute()
            .map { try convert($0.get().columns) }
            .first
    }
}

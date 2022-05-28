import PostgresClientKit

public struct Operation {
    public let statement: Statement
    public let parameters: [PostgresValueConvertible?]

    init(sql: String, connection: Connection, parameters: [PostgresValueConvertible?]) throws {
        statement = try connection.prepareStatement(text: sql)
        self.parameters = parameters
    }
    
    public func execute() throws {
        try statement.execute()
    }
    
    public func single<T>(convert: ([PostgresValue]) throws -> T) throws -> T? {
        try statement.execute(parameterValues: parameters, retrieveColumnMetadata: false)
            .map { try convert($0.get().columns) }
            .first
    }
}

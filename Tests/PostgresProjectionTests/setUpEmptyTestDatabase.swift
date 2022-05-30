import XCTest
import PostgresClientKit

import Postgres
import PostgresSource
import Source

var configuration: ConnectionConfiguration {
    var config = ConnectionConfiguration()
    config.host = "localhost"
    config.port = 5432
    config.ssl = false

    if let database = ProcessInfo.processInfo.environment["POSTGRES_TEST_DATABASE"] {
        config.database = database
    }

    if let user = ProcessInfo.processInfo.environment["POSTGRES_TEST_USER"] {
        config.user = user
    }

    if let password = ProcessInfo.processInfo.environment["POSTGRES_TEST_PASS"] {
        config.credential = Credential.cleartextPassword(password: password)
    }

    return config
}

var database: Database!

public func setUpEmptyTestDatabase() throws -> Database {
    if database == nil {
        try createTestDatabase()

        let connection = try Connection(configuration: configuration)
        database = Database(connection: connection)
    }

    try Schema.add(to: database)
    try database.operation(#"DELETE FROM "Events""#).execute()
    try database.operation(#"DELETE FROM "Entities""#).execute()
    try database.operation(#"UPDATE "Properties" SET "value" = 0 WHERE "name" = 'next_position'"#).execute()
    
    return database
}

private func createTestDatabase() throws {
    var noDbConfig = configuration
    noDbConfig.database = ""

    let connection = try Connection(configuration: noDbConfig)
    let noDb = Database(connection: connection)
    try? noDb.operation("CREATE DATABASE \(configuration.database)").execute()
}

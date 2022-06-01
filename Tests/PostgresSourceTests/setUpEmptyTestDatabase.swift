import XCTest
import PostgresClientKit

import Postgres
import PostgresSource
import Source

let host = Host("localhost", useSSL: false)
let databaseName = ProcessInfo.processInfo.environment["POSTGRES_TEST_DATABASE"]!
let username = ProcessInfo.processInfo.environment["POSTGRES_TEST_USER"]!
let password = ProcessInfo.processInfo.environment["POSTGRES_TEST_PASS"]

var database: Database!

public func setUpEmptyTestDatabase() throws -> Database {
    if database == nil {
        try createTestDatabase()

        database = try Database.connect(host: host, database: databaseName, username: username, password: password)
    }

    try Schema.add(to: database)
    try database.operation(#"DELETE FROM "Events""#).execute()
    try database.operation(#"DELETE FROM "Entities""#).execute()
    try database.operation(#"UPDATE "Properties" SET "value" = 0 WHERE "name" = 'next_position'"#).execute()
    
    return database
}

private func createTestDatabase() throws {
    let noDb = try Database.connect(host: host, database: "", username: username, password: password)
    try? noDb.operation("CREATE DATABASE \(databaseName)").execute()
}

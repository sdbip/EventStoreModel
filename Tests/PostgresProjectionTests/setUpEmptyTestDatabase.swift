import XCTest
import PostgresClientKit

import Postgres
import PostgresSource
import Source

let host = Host(
    ProcessInfo.processInfo.environment["POSTGRES_TEST_HOST"] ?? "localhost",
    database: ProcessInfo.processInfo.environment["POSTGRES_TEST_DATABASE"]!,
    useSSL: false)
let credentials = Credentials(
    username: ProcessInfo.processInfo.environment["POSTGRES_TEST_USER"]!,
    password: ProcessInfo.processInfo.environment["POSTGRES_TEST_PASS"])

var database: Database!

public func setUpEmptyTestDatabase() throws -> Database {
    if database == nil {
        try createTestDatabase()

        database = try Database.connect(host: host, credentials: credentials)
    }

    try Schema.add(to: database)
    try database.operation("DELETE FROM Events").execute()
    try database.operation("DELETE FROM Entities").execute()

    return database
}

private func createTestDatabase() throws {
    var noDbHost = host
    noDbHost.database = nil
    let noDb = try Database.connect(host: noDbHost, credentials: credentials)
    try? noDb.operation("CREATE DATABASE \(host.database!)").execute()
}

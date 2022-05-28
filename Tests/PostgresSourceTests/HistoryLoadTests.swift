import XCTest
import PostgresClientKit

import Postgres
import PostgresSource
import Source

final class HistoryLoadTests: XCTestCase {
    var store: EntityStore!
    var database: Database!

    override func setUp() async throws {
        var noDbConfig = configuration
        noDbConfig.database = ""
        
        let noDb = Database(connection: try Connection(configuration: noDbConfig))
        try? noDb.operation("CREATE DATABASE \(configuration.database)").execute()

        let connection = try Connection(configuration: configuration)
        database = Database(connection: connection)
        try Schema.add(to: database)
        try database.operation(#"DELETE FROM "Events""#).execute()
        try database.operation(#"DELETE FROM "Entities""#).execute()
        try database.operation(#"UPDATE "Properties" SET "value" = 0 WHERE "name" = 'next_position'"#).execute()
        
        store = EntityStore(repository: database)
    }
    
    func test_fetchesEntityData() throws {
        try database.operation(#"INSERT INTO "Entities" ("id", "type", "version") VALUES ('test', 'TheType', 42)"#).execute()

        let history = try store.history(forEntityWithId: "test")
        XCTAssertEqual(history?.type, "TheType")
        XCTAssertEqual(history?.version, 42)
    }

    func test_fetchesEventData() throws {
        try database.insertEntityRow(id: "test", type: "TheType", version: 42)
        try database.insertEventRow(entityId: "test", entityType: "TheType", name: "TheEvent", jsonDetails: "{}", actor: "a_user", version: 0, position: 0)

        guard let history = try store.history(forEntityWithId: "test") else { return XCTFail("No history returned") }

        XCTAssertEqual(history.events.count, 1)

        XCTAssertEqual(history.events[0].name, "TheEvent")
        XCTAssertEqual(history.events[0].jsonDetails, "{}")
        XCTAssertEqual(history.events[0].actor, "a_user")
    }

    func test_convertsTimestampFromJulianDay() throws {
        try database.insertEntityRow(id: "test", type: "TheType", version: 42)
        try database.operation("""
            INSERT INTO "Events" ("entityId", "entityType", "name", "details", "actor", "timestamp", "version", "position") VALUES
                ('test', 'TheType', 'any', '{}', 'any', 2459683.17199667, 0, 0)
            """
        ).execute()

        guard let history = try store.history(forEntityWithId: "test") else { return XCTFail("No history returned") }
        guard let event = history.events.first else { return XCTFail("No event returned")}

        XCTAssertEqual("\(formatWithMilliseconds(date: event.timestamp))", "2022-04-13 16:07:40.515 +0000")
    }

    private func formatWithMilliseconds(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
        return dateFormatter.string(from: date)
    }

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
}

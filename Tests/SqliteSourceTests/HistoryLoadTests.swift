import SQLite3
import XCTest

import Source
import SQLite
import SQLiteSource

internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

let testDBFile = "test.db"

final class HistoryLoadTests: XCTestCase {
    var store: EntityStore!

    override func setUp() {
        store = EntityStore(dbFile: testDBFile)

        do {
            try store.addSchema()
        } catch {
            XCTFail("\(error)")
        }
    }

    override func tearDown() {
        do {
            try FileManager.default.removeItem(atPath: testDBFile)
        } catch { }
    }

    func test_addsSchema() throws {
        let connection = try DbConnection(openFile: testDBFile)
        let statement = try Statement(prepare: "select * from Entities", connection: connection)
        try statement.execute()
        try connection.close()
    }

    func test_fetchesEntityData() throws {
        let connection = try DbConnection(openFile: testDBFile)
        let statement = try Statement(
            prepare: "insert into Entities (id, type, version) values ('test', 'TheType', 42)",
            connection: connection
        )
        try statement.execute()
        try connection.close()

        let history = try store.getHistory(id: "test")
        XCTAssertEqual(history?.type, "TheType")
        XCTAssertEqual(history?.version, 42)
    }

    func test_fetchesEventData() throws {
        let connection = try DbConnection(openFile: testDBFile)
        try connection.execute("""
            insert into Entities (id, type, version) values
                ('test', 'TheType', 42);
            insert into Events (entity, name, details, actor, timestamp, version, position) values
                ('test', 'TheEvent', '{}', 'a_user', 0, 0, 0)
            """
        )
        try connection.close()

        guard let history = try store.getHistory(id: "test") else { return XCTFail("No history returned") }

        XCTAssertEqual(history.events.count, 1)

        XCTAssertEqual(history.events[0].name, "TheEvent")
        XCTAssertEqual(history.events[0].details, "{}")
        XCTAssertEqual(history.events[0].actor, "a_user")
    }

    func test_convertsTimestampFromJulianDay() throws {
        let julianDay = 2459683.17199667
        let gregorianDate = "2022-04-13 16:07:40 +0000"
        let millisPart = 0.512

        let connection = try DbConnection(openFile: testDBFile)
        try connection.execute("""
            insert into Entities (id, type, version) values
                ('test', 'TheType', 42);
            insert into Events (entity, name, details, actor, timestamp, version, position) values
                ('test', 'any', '{}', 'any', \(julianDay), 0, 0)
            """
        )
        try connection.close()

        guard let history = try store.getHistory(id: "test") else { return XCTFail("No history returned") }
        guard let event = history.events.first else { return XCTFail("No event returned")}

        XCTAssertEqual("\(event.timestamp)", gregorianDate)

        let dateComponents = Calendar.current.dateComponents([.nanosecond], from: event.timestamp)
        XCTAssertEqual(Double(dateComponents.nanosecond!) * 1e-9, millisPart, accuracy: 1e-3)
    }
}

import SQLite3
import XCTest

import Source
import SQLite
import SQLiteSource

let testDBFile = "test.db"

final class HistoryLoadTests: XCTestCase {
    var store: EntityStore!

    override func setUp() {
        store = EntityStore(dbFile: testDBFile)

        do {
            try Schema.add(to: testDBFile)
        } catch {
            XCTFail("\(error)")
        }
    }

    override func tearDown() {
        do {
            try FileManager.default.removeItem(atPath: testDBFile)
        } catch { }
    }

    func test_fetchesEntityData() throws {
        let connection = try Connection(openFile: testDBFile)
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
        let connection = try Connection(openFile: testDBFile)
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
        let connection = try Connection(openFile: testDBFile)
        try connection.execute("""
            insert into Entities (id, type, version) values
                ('test', 'TheType', 42);
            insert into Events (entity, name, details, actor, timestamp, version, position) values
                ('test', 'any', '{}', 'any', 2459683.17199667, 0, 0)
            """
        )
        try connection.close()

        guard let history = try store.getHistory(id: "test") else { return XCTFail("No history returned") }
        guard let event = history.events.first else { return XCTFail("No event returned")}

        XCTAssertEqual("\(formatWithMilliseconds(date: event.timestamp))", "2022-04-13 16:07:40.512 +0000")
    }

    private func formatWithMilliseconds(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
        return dateFormatter.string(from: date)
    }
}

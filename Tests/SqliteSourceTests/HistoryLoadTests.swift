import SQLite3
import XCTest

import Source
import SQLite
import SQLiteSource

private let testDBFile = "test.db"

final class HistoryLoadTests: XCTestCase {
    var store: EntityStore!
    var database: Database!

    override func setUp() {
        _ = try? FileManager.default.removeItem(atPath: testDBFile)

        do {
            store = EntityStore(dbFile: testDBFile)
            database = try Database(openFile: testDBFile)

            try Schema.add(to: testDBFile)
        } catch {
            XCTFail("\(error)")
        }
    }

    override func tearDown() {
        _ = try? database.close()
        _ = try? FileManager.default.removeItem(atPath: testDBFile)
    }

    func test_fetchesEntityData() throws {
        try database.execute("INSERT INTO Entities (id, type, version) VALUES ('test', 'TheType', 42)")

        let history = try store.history(forEntityWithId: "test")
        XCTAssertEqual(history?.type, "TheType")
        XCTAssertEqual(history?.version, 42)
    }

    func test_fetchesEventData() throws {
        try database.execute("""
            INSERT INTO Entities (id, type, version) VALUES
                ('test', 'TheType', 42);
            INSERT INTO Events (entity, name, details, actor, timestamp, version, position) VALUES
                ('test', 'TheEvent', '{}', 'a_user', 0, 0, 0)
            """
        )

        guard let history = try store.history(forEntityWithId: "test") else { return XCTFail("No history returned") }

        XCTAssertEqual(history.events.count, 1)

        XCTAssertEqual(history.events[0].name, "TheEvent")
        XCTAssertEqual(history.events[0].jsonDetails, "{}")
        XCTAssertEqual(history.events[0].actor, "a_user")
    }

    func test_convertsTimestampFromJulianDay() throws {
        try database.execute("""
            INSERT INTO Entities (id, type, version) VALUES
                ('test', 'TheType', 42);
            INSERT INTO Events (entity, name, details, actor, timestamp, version, position) VALUES
                ('test', 'any', '{}', 'any', 2459683.17199667, 0, 0)
            """
        )

        guard let history = try store.history(forEntityWithId: "test") else { return XCTFail("No history returned") }
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

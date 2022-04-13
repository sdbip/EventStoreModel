import SQLite3
import XCTest

import Source
import SQLite
import SQLiteSource

internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

let testDBFile = "test.db"

final class HistoryLoadTests: XCTestCase {
    override func setUp() {
        let store = EntityStore()

        do {
            try store.addSchema(dbFile: testDBFile)
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

        let store = EntityStore()
        let history = try store.getHistory(id: "test", dbFile: testDBFile)
        XCTAssertEqual(history.type, "TheType")
        XCTAssertEqual(history.version, 42)
    }
}

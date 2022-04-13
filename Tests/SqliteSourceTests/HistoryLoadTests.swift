import SQLite3
import XCTest

import Source
import SQLiteSource

internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

let testDBFile = "test.db"

final class HistoryLoadTests: XCTestCase {
    override func tearDown() {
        do {
            try FileManager.default.removeItem(atPath: testDBFile)
        } catch {
            print("Error deleting file \(testDBFile): \(error)")
        }
    }

    func test_addsSchema() throws {
        let store = EntityStore()
        store.addSchema(dbFile: testDBFile)

        var db: OpaquePointer?
        guard sqlite3_open(testDBFile, &db) == SQLITE_OK else {
            return XCTFail("could not open database")
        }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, "select * from Entities", -1, &statement, nil) == SQLITE_OK else {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return XCTFail("error preparing select: \(errmsg)")
        }

        guard sqlite3_finalize(statement) == SQLITE_OK else {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return XCTFail("error finalizing prepared statement: \(errmsg)")
        }

        statement = nil

        sqlite3_close(db)
    }
}

final class TestEntity: Entity {
    static let type = "TestEntity"
    let version: EntityVersion
    let unpublishedEvents: [UnpublishedEvent]
    var lastReconstitutedEvent: PublishedEvent?

    init(version: EntityVersion) {
        self.version = version
        self.unpublishedEvents = []
    }

    func apply(_ event: PublishedEvent) {
        lastReconstitutedEvent = event
    }
}

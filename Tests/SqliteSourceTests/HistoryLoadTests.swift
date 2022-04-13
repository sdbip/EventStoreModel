import SQLite3
import XCTest

import Source
import SQLite
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
        try store.addSchema(dbFile: testDBFile)

        let connection = try DbConnection(openFile: testDBFile)
        let statement = try Statement(prepare: "select * from Entities", connection: connection)
        try statement.execute()
        try connection.close()
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

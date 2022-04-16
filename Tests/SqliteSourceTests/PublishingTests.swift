import XCTest

import Source
import SQLite
import SQLiteSource

final class PublishingTests: XCTestCase {
    var publisher: EntityPublisher!

    override func setUp() {
        publisher = EntityPublisher(dbFile: testDBFile)

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

    func test_canPublishSingleEvent() throws {
        let entity = TestEntity(id: "test", version: .notSaved)
        entity.unpublishedEvents.append(UnpublishedEvent(name: "AnEvent", details: "{}"))

        try publisher.publishChanges(entity: entity)

        _ = try Connection(openFile: testDBFile)
    }
}

final class TestEntity: Entity {
    static let type = "TestEntity"

    let id: String
    let version: EntityVersion
    var unpublishedEvents: [UnpublishedEvent] = []

    public init(id: String, version: EntityVersion) {
        self.id = id
        self.version = version
    }

    func apply(_ event: PublishedEvent) {}
}

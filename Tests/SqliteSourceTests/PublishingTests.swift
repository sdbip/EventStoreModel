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

        try publisher.publishChanges(entity: entity, actor: "user_x")

        let history = try EntityStore(dbFile: testDBFile).getHistory(id: "test")
        XCTAssertEqual(history?.type, TestEntity.type)
        XCTAssertEqual(history?.id, "test")
        XCTAssertEqual(history?.version, 0)
        XCTAssertEqual(history?.events.count, 1)
        XCTAssertEqual(history?.events[0].name, "AnEvent")
        XCTAssertEqual(history?.events[0].details, "{}")
        XCTAssertEqual(history?.events[0].actor, "user_x")
    }

    func test_canPublishMultipleEvents() throws {
        let entity = TestEntity(id: "test", version: .notSaved)
        entity.unpublishedEvents.append(UnpublishedEvent(name: "AnEvent", details: "{}"))
        entity.unpublishedEvents.append(UnpublishedEvent(name: "AnEvent", details: "{}"))
        entity.unpublishedEvents.append(UnpublishedEvent(name: "AnEvent", details: "{}"))

        try publisher.publishChanges(entity: entity, actor: "user_x")

        let history = try EntityStore(dbFile: testDBFile).getHistory(id: "test")
        XCTAssertEqual(history?.events.count, 3)
    }

    func test_canPublishToExistingEntity() throws {
        let connection = try Connection(openFile: testDBFile)
        try connection.execute("""
            INSERT INTO Entities (id, type, version)
            VALUES ('test', 'TestEntity', 0);
            """
        )

        let entity = TestEntity(id: "test", version: .notSaved)
        entity.unpublishedEvents.append(UnpublishedEvent(name: "AnEvent", details: "{}"))
        entity.unpublishedEvents.append(UnpublishedEvent(name: "AnEvent", details: "{}"))
        entity.unpublishedEvents.append(UnpublishedEvent(name: "AnEvent", details: "{}"))

        try publisher.publishChanges(entity: entity, actor: "user_x")

        let history = try EntityStore(dbFile: testDBFile).getHistory(id: "test")
        XCTAssertEqual(history?.events.count, 3)
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

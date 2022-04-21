import XCTest

import Source
import SQLite
import SQLiteSource

final class PublishingTests: XCTestCase {
    var publisher: EventPublisher!

    override func setUp() {
        publisher = EventPublisher(dbFile: testDBFile)

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
        entity.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")]

        try publisher.publishChanges(entity: entity, actor: "user_x")

        let history = try EntityStore(dbFile: testDBFile)
            .history(forEntityWithId: "test")
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
        entity.unpublishedEvents = [
            UnpublishedEvent(name: "AnEvent", details: "{}"),
            UnpublishedEvent(name: "AnEvent", details: "{}"),
            UnpublishedEvent(name: "AnEvent", details: "{}")
        ]

        try publisher.publishChanges(entity: entity, actor: "user_x")

        let history = try EntityStore(dbFile: testDBFile).history(forEntityWithId: "test")
        XCTAssertEqual(history?.events.count, 3)
        XCTAssertEqual(history?.version, 2)
    }

    func test_canPublishToExistingEntity() throws {
        let connection = try Connection(openFile: testDBFile)
        try connection.execute("""
            INSERT INTO Entities (id, type, version)
            VALUES ('test', 'TestEntity', 0);
            """
        )

        let entity = TestEntity(id: "test", version: .version(0))
        entity.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")]

        try publisher.publishChanges(entity: entity, actor: "user_x")

        let history = try EntityStore(dbFile: testDBFile).history(forEntityWithId: "test")
        XCTAssertEqual(history?.events.count, 1)
    }

    func test_throwsIfVersionHasChanged() throws {
        let connection = try Connection(openFile: testDBFile)
        try connection.execute("""
            INSERT INTO Entities (id, type, version)
            VALUES ('test', 'TestEntity', 2);
            """
        )

        let entity = TestEntity(id: "test", version: 1)
        entity.unpublishedEvents.append(UnpublishedEvent(name: "AnEvent", details: "{}"))

        XCTAssertThrowsError(try publisher.publishChanges(entity: entity, actor: "user_x"))
    }

    func test_updatesVersion() throws {
        let connection = try Connection(openFile: testDBFile)
        try connection.execute("""
            INSERT INTO Entities (id, type, version)
            VALUES ('test', 'TestEntity', 1);
            """
        )

        let entity = TestEntity(id: "test", version: 1)
        entity.unpublishedEvents = [
            UnpublishedEvent(name: "FirstEvent", details: "{}"),
            UnpublishedEvent(name: "SecondEvent", details: "{}"),
            UnpublishedEvent(name: "ThirdEvent", details: "{}")
        ]

        try publisher.publishChanges(entity: entity, actor: "user_x")

        let history = try EntityStore(dbFile: testDBFile).history(forEntityWithId: "test")
        XCTAssertEqual(history?.version, 4)
        XCTAssertEqual(history?.events[0].name, "FirstEvent")
        XCTAssertEqual(history?.events[1].name, "SecondEvent")
        XCTAssertEqual(history?.events[2].name, "ThirdEvent")
    }

    func test_updatesNextPosition() throws {
        let connection = try Connection(openFile: testDBFile)
        try connection.execute("""
            INSERT INTO Entities (id, type, version)
            VALUES ('test', 'TestEntity', 1);

            INSERT INTO Events (entity, name, details, actor, version, position)
            VALUES ('test', 'OldEvent', '{}', 'someone', 0, 1);

            UPDATE Properties SET value = 2 WHERE name = 'next_position';
            """
        )

        let entity = TestEntity(id: "test", version: 1)
        entity.unpublishedEvents = [
            UnpublishedEvent(name: "AnEvent", details: "{}"),
            UnpublishedEvent(name: "AnEvent", details: "{}"),
            UnpublishedEvent(name: "AnEvent", details: "{}")
        ]

        try publisher.publishChanges(entity: entity, actor: "user_x")

        let nextPosition = try connection.operation(
            "SELECT value FROM Properties WHERE name = 'next_position'"
        ).single { $0.int64(at: 0) }
        XCTAssertEqual(nextPosition, 3)

        let position = try connection.operation(
            "SELECT MAX(position) FROM Events WHERE entity = 'test'"
        ).single { $0.int64(at: 0) }
        XCTAssertEqual(position, 2)
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

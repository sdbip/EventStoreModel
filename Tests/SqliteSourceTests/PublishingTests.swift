import XCTest

import Source
import SQLite
import SQLiteSource

private let testDBFile = "test.db"

final class PublishingTests: XCTestCase {
    var publisher: EventPublisher!

    override func setUp() {
        _ = try? FileManager.default.removeItem(atPath: testDBFile)

        publisher = EventPublisher(dbFile: testDBFile)

        do {
            try Schema.add(to: testDBFile)
        } catch {
            XCTFail("\(error)")
        }
    }

    override func tearDown() {
        _ = try? FileManager.default.removeItem(atPath: testDBFile)
    }

    func test_canPublishSingleEvent() throws {
        let entity = TestEntity(id: "test", version: .notSaved)
        entity.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]

        try publisher.publishChanges(entity: entity, actor: "user_x")

        let history = try EntityStore(dbFile: testDBFile)
            .history(forEntityWithId: "test")
        XCTAssertEqual(history?.type, TestEntity.type)
        XCTAssertEqual(history?.id, "test")
        XCTAssertEqual(history?.version, 0)
        XCTAssertEqual(history?.events.count, 1)
        XCTAssertEqual(history?.events[0].name, "AnEvent")
        XCTAssertEqual(history?.events[0].jsonDetails, "{}")
        XCTAssertEqual(history?.events[0].actor, "user_x")
    }

    func test_canPublishMultipleEvents() throws {
        let entity = TestEntity(id: "test", version: .notSaved)
        entity.unpublishedEvents = [
            UnpublishedEvent(name: "AnEvent", details: "{}")!,
            UnpublishedEvent(name: "AnEvent", details: "{}")!,
            UnpublishedEvent(name: "AnEvent", details: "{}")!
        ]

        try publisher.publishChanges(entity: entity, actor: "user_x")

        let history = try EntityStore(dbFile: testDBFile).history(forEntityWithId: "test")
        XCTAssertEqual(history?.events.count, 3)
        XCTAssertEqual(history?.version, 2)
    }

    func test_canPublishToExistingEntity() throws {
        let database = try Database(openFile: testDBFile)
        try database.execute("""
            INSERT INTO Entities (id, type, version)
            VALUES ('test', 'TestEntity', 0);
            """
        )

        let entity = TestEntity(id: "test", version: .saved(0))
        entity.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]

        try publisher.publishChanges(entity: entity, actor: "user_x")

        let history = try EntityStore(dbFile: testDBFile).history(forEntityWithId: "test")
        XCTAssertEqual(history?.events.count, 1)
    }

    func test_throwsIfVersionHasChanged() throws {
        let database = try Database(openFile: testDBFile)
        try database.execute("""
            INSERT INTO Entities (id, type, version)
            VALUES ('test', 'TestEntity', 2);
            """
        )

        let entity = TestEntity(id: "test", version: 1)
        entity.unpublishedEvents.append(UnpublishedEvent(name: "AnEvent", details: "{}")!)

        XCTAssertThrowsError(try publisher.publishChanges(entity: entity, actor: "user_x"))
    }

    func test_updatesVersion() throws {
        let database = try Database(openFile: testDBFile)
        try database.execute("""
            INSERT INTO Entities (id, type, version)
            VALUES ('test', 'TestEntity', 1);
            """
        )

        let entity = TestEntity(id: "test", version: 1)
        entity.unpublishedEvents = [
            UnpublishedEvent(name: "FirstEvent", details: "{}")!,
            UnpublishedEvent(name: "SecondEvent", details: "{}")!,
            UnpublishedEvent(name: "ThirdEvent", details: "{}")!
        ]

        try publisher.publishChanges(entity: entity, actor: "user_x")

        let history = try EntityStore(dbFile: testDBFile).history(forEntityWithId: "test")
        XCTAssertEqual(history?.version, 4)
        XCTAssertEqual(history?.events[0].name, "FirstEvent")
        XCTAssertEqual(history?.events[1].name, "SecondEvent")
        XCTAssertEqual(history?.events[2].name, "ThirdEvent")
    }

    func test_updatesNextPosition() throws {
        let database = try Database(openFile: testDBFile)
        try database.execute("""
            INSERT INTO Entities (id, type, version)
            VALUES ('test', 'TestEntity', 1);

            INSERT INTO Events (entity, name, details, actor, version, position)
            VALUES ('test', 'OldEvent', '{}', 'someone', 0, 1);

            UPDATE Properties SET value = 2 WHERE name = 'next_position';
            """
        )

        let entity = TestEntity(id: "test", version: 1)
        entity.unpublishedEvents = [
            UnpublishedEvent(name: "AnEvent", details: "{}")!,
            UnpublishedEvent(name: "AnEvent", details: "{}")!,
            UnpublishedEvent(name: "AnEvent", details: "{}")!
        ]

        try publisher.publishChanges(entity: entity, actor: "user_x")

        let nextPosition = try database.operation(
            "SELECT value FROM Properties WHERE name = 'next_position'"
        ).single { $0.int64(at: 0) }
        XCTAssertEqual(nextPosition, 5)

        let position = try database.operation(
            "SELECT MAX(position) FROM Events WHERE entity = 'test'"
        ).single { $0.int64(at: 0) }
        XCTAssertEqual(position, 4)
    }

    func test_canPublishSingleEvents() throws {
        let database = try Database(openFile: testDBFile)
        try database.execute("""
            INSERT INTO Entities (id, type, version)
            VALUES ('test', 'TestEntity', 1);

            INSERT INTO Events (entity, name, details, actor, version, position)
            VALUES ('test', 'OldEvent', '{}', 'someone', 0, 1);

            UPDATE Properties SET value = 2 WHERE name = 'next_position';
            """
        )

        let event = UnpublishedEvent(name: "AnEvent", details: "{}")!

        try publisher.publish(event, forId: "test", type: "whatever", actor: "user_x")

        let nextPosition = try database.operation(
            "SELECT value FROM Properties WHERE name = 'next_position'"
        ).single { $0.int64(at: 0) }
        XCTAssertEqual(nextPosition, 3)

        let position = try database.operation(
            "SELECT MAX(position) FROM Events WHERE entity = 'test'"
        ).single { $0.int64(at: 0) }
        XCTAssertEqual(position, 2)
    }

    func test_createsEntityFromSingleEvents() throws {
        let event = UnpublishedEvent(name: "AnEvent", details: "{}")!

        try publisher.publish(event, forId: "test", type: "expected", actor: "user_x")

        let database = try Database(openFile: testDBFile)
        let nextPosition = try database.operation(
            "SELECT value FROM Properties WHERE name = 'next_position'"
        ).single { $0.int64(at: 0) }
        XCTAssertEqual(nextPosition, 1)

        let position = try database.operation(
            "SELECT MAX(position) FROM Events WHERE entity = 'test'"
        ).single { $0.int64(at: 0) }
        XCTAssertEqual(position, 0)

        let type = try database.operation(
            "SELECT type FROM Entities WHERE id = 'test'"
        ).single { $0.string(at: 0) }
        XCTAssertEqual(type, "expected")
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

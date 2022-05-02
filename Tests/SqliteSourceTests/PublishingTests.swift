import XCTest

import Source
import SQLite
import SQLiteSource

private let testDBFile = "test.db"

final class PublishingTests: XCTestCase {
    var publisher: EventPublisher!
    var entityStore: EntityStore!

    override func setUp() {
        _ = try? FileManager.default.removeItem(atPath: testDBFile)

        do {
            publisher = EventPublisher(dbFile: testDBFile)
            entityStore = EntityStore(dbFile: testDBFile)

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

        let history = try history(afterPublishingChangesFor: entity, actor: "user_x")

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

        let history = try history(afterPublishingChangesFor: entity, actor: "any")

        XCTAssertEqual(history?.events.count, 3)
        XCTAssertEqual(history?.version, 2)
    }

    func test_canPublishToExistingEntity() throws {
        let database = try Database(openFile: testDBFile)
        try database.execute("""
            INSERT INTO Entities (id, type, version)
            VALUES ('test', 'TestEntity', 0)
            """
        )

        let entity = TestEntity(id: "test", version: .saved(0))
        entity.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]

        let history = try history(afterPublishingChangesFor: entity, actor: "any")

        XCTAssertEqual(history?.events.count, 1)
    }

    func test_throwsIfVersionHasChanged() throws {
        let database = try Database(openFile: testDBFile)
        try database.execute("""
            INSERT INTO Entities (id, type, version)
            VALUES ('test', 'TestEntity', 2)
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
            VALUES ('test', 'TestEntity', 1)
            """
        )

        let entity = TestEntity(id: "test", version: 1)
        entity.unpublishedEvents = [
            UnpublishedEvent(name: "FirstEvent", details: "{}")!,
            UnpublishedEvent(name: "SecondEvent", details: "{}")!,
            UnpublishedEvent(name: "ThirdEvent", details: "{}")!
        ]

        let history = try history(afterPublishingChangesFor: entity, actor: "any")

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

        XCTAssertEqual(try entityStore.nextPosition(), 5)
        XCTAssertEqual(try maxPositionOfEvents(forEntityWithId: "test"), 4)
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

        XCTAssertEqual(try entityStore.nextPosition(), 3)
        XCTAssertEqual(try maxPositionOfEvents(forEntityWithId: "test"), 2)
    }

    func test_createsEntityFromSingleEvents() throws {
        let event = UnpublishedEvent(name: "AnEvent", details: "{}")!

        try publisher.publish(event, forId: "test", type: "expected", actor: "user_x")

        XCTAssertEqual(try entityStore.nextPosition(), 1)
        XCTAssertEqual(try entityStore.type(ofEntityWithId: "test"), "expected")
        XCTAssertEqual(try maxPositionOfEvents(forEntityWithId: "test"), 0)
    }

    private func history<EntityType>(afterPublishingChangesFor entity: EntityType, actor: String) throws -> History? where EntityType: Entity {
        try publisher.publishChanges(entity: entity, actor: actor)
        return try entityStore.history(forEntityWithId: entity.id)
    }
    
    private func maxPositionOfEvents(forEntityWithId id: String) throws -> Int64? {
        let database = try Database(openFile: testDBFile)
        return try database.operation(
            "SELECT MAX(position) FROM Events WHERE entity = 'test'"
        ).single { $0.int64(at: 0) }
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

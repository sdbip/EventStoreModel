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

    func test_canPublishEntityWithoutEvents() throws {
        let entity = TestEntity(id: "test", version: .notSaved)
        entity.unpublishedEvents = []

        let history = try history(afterPublishingChangesFor: entity, actor: "user_x")

        XCTAssertEqual(history?.type, TestEntity.type)
        XCTAssertEqual(history?.id, "test")
        XCTAssertEqual(history?.version, 0)
    }

    func test_canPublishSingleEvent() throws {
        let entity = TestEntity(id: "test", version: .notSaved)
        entity.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]

        let history = try history(afterPublishingChangesFor: entity, actor: "user_x")
        let event = history?.events.first

        XCTAssertEqual(event?.name, "AnEvent")
        XCTAssertEqual(event?.jsonDetails, "{}")
        XCTAssertEqual(event?.actor, "user_x")
    }

    func test_versionMatchesNumberOfEvents() throws {
        let entity = TestEntity(id: "test", version: .notSaved)
        entity.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]

        let history = try history(afterPublishingChangesFor: entity, actor: "user_x")

        XCTAssertEqual(history?.version, 1)
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
        XCTAssertEqual(history?.version, 3)
    }

    func test_addsEventsExistingEntity() throws {
        let existingEntity = TestEntity(id: "test", version: .notSaved)
        try publisher.publishChanges(entity: existingEntity, actor: "any")

        let reconstitutedVersion = TestEntity(id: "test", version: 0)
        reconstitutedVersion.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]

        let history = try history(afterPublishingChangesFor: reconstitutedVersion, actor: "any")

        XCTAssertEqual(history?.events.count, 1)
    }

    func test_throwsIfVersionHasChanged() throws {
        let existingEntity = TestEntity(id: "test", version: .notSaved)
        existingEntity.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]
        try publisher.publishChanges(entity: existingEntity, actor: "any")

        let reconstitutedVersion = TestEntity(id: "test", version: .eventCount(0))
        reconstitutedVersion.unpublishedEvents.append(UnpublishedEvent(name: "AnEvent", details: "{}")!)

        XCTAssertThrowsError(try publisher.publishChanges(entity: reconstitutedVersion, actor: "user_x"))
    }

    func test_updatesNextPosition() throws {
        let existingEntity = TestEntity(id: "test", version: .notSaved)
        existingEntity.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]
        try publisher.publishChanges(entity: existingEntity, actor: "any")

        let entity = TestEntity(id: "test", version: 1)
        entity.unpublishedEvents = [
            UnpublishedEvent(name: "AnEvent", details: "{}")!,
            UnpublishedEvent(name: "AnEvent", details: "{}")!,
            UnpublishedEvent(name: "AnEvent", details: "{}")!
        ]

        try publisher.publishChanges(entity: entity, actor: "user_x")

        XCTAssertEqual(try entityStore.nextPosition(), 4)
        XCTAssertEqual(try maxPositionOfEvents(forEntityWithId: "test"), 3)
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

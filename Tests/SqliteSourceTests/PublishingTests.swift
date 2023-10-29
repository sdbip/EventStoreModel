import XCTest

import Source
import SQLite

private let testDBFile = "test.db"

final class PublishingTests: XCTestCase {
    var publisher: EventPublisher!
    var entityStore: EntityStore!
    var database: Database!

    override func setUp() {
        _ = try? FileManager.default.removeItem(atPath: testDBFile)

        do {
            database = try Database(openFile: testDBFile)
            publisher = EventPublisher(repository: database)
            entityStore = EntityStore(repository: database)

            try Schema.add(to: testDBFile)
        } catch {
            XCTFail("\(error)")
        }
    }

    override func tearDown() {
        _ = try? FileManager.default.removeItem(atPath: testDBFile)
    }

    func test_canPublishEntityWithoutEvents() throws {
        let entity = Entity(id: "test", state: TestEntity())
        entity.state.unpublishedEvents = []

        let history = try history(afterPublishingChangesFor: entity, actor: "user_x")

        XCTAssertEqual(history?.type, TestEntity.typeId)
        XCTAssertEqual(history?.id, "test")
        XCTAssertEqual(history?.version, 0)
    }

    func test_canPublishSingleEvent() throws {
        let entity = Entity(id: "test", state: TestEntity())
        entity.state.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]

        let history = try history(afterPublishingChangesFor: entity, actor: "user_x")
        let event = history?.events.first

        XCTAssertEqual(event?.name, "AnEvent")
        XCTAssertEqual(event?.jsonDetails, "{}")
        XCTAssertEqual(event?.actor, "user_x")
    }

    func test_versionMatchesNumberOfEvents() throws {
        let entity = Entity(id: "test", state: TestEntity())
        entity.state.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]

        let history = try history(afterPublishingChangesFor: entity, actor: "user_x")

        XCTAssertEqual(history?.version, 1)
    }

    func test_canPublishMultipleEvents() throws {
        let entity = Entity(id: "test", state: TestEntity())
        entity.state.unpublishedEvents = [
            UnpublishedEvent(name: "AnEvent", details: "{}")!,
            UnpublishedEvent(name: "AnEvent", details: "{}")!,
            UnpublishedEvent(name: "AnEvent", details: "{}")!
        ]

        let history = try history(afterPublishingChangesFor: entity, actor: "any")

        XCTAssertEqual(history?.events.count, 3)
        XCTAssertEqual(history?.version, 3)
    }

    func test_addsEventsExistingEntity() throws {
        let existingEntity = Entity(id: "test", state: TestEntity())
        try publisher.publishChanges(entity: existingEntity, actor: "any")

        let reconstitutedVersion = Entity(id: "test", state: TestEntity(), version: 0)
        reconstitutedVersion.state.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]

        let history = try history(afterPublishingChangesFor: reconstitutedVersion, actor: "any")

        XCTAssertEqual(history?.events.count, 1)
    }

    func test_throwsIfVersionHasChanged() throws {
        let existingEntity = Entity(id: "test", state: TestEntity())
        existingEntity.state.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]
        try publisher.publishChanges(entity: existingEntity, actor: "any")

        let reconstitutedVersion = Entity(id: "test", state: TestEntity(), version: .eventCount(0))
        reconstitutedVersion.state.unpublishedEvents.append(UnpublishedEvent(name: "AnEvent", details: "{}")!)

        XCTAssertThrowsError(try publisher.publishChanges(entity: reconstitutedVersion, actor: "user_x"))
    }

    func test_updatesNextPosition() throws {
        let existingEntity = Entity(id: "test", state: TestEntity())
        existingEntity.state.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]
        try publisher.publishChanges(entity: existingEntity, actor: "any")

        let entity = Entity(id: "test", state: TestEntity(), version: 1)
        entity.state.unpublishedEvents = [
            UnpublishedEvent(name: "AnEvent", details: "{}")!,
            UnpublishedEvent(name: "AnEvent", details: "{}")!,
            UnpublishedEvent(name: "AnEvent", details: "{}")!
        ]

        try publisher.publishChanges(entity: entity, actor: "user_x")

        XCTAssertEqual(try database.nextPosition(), 4)
        XCTAssertEqual(try maxPositionOfEvents(forEntityWithId: "test"), 3)
    }

    private func history<__State>(afterPublishingChangesFor entity: Entity<__State>, actor: String) throws -> History? where __State: EntityState {
        try publisher.publishChanges(entity: entity, actor: actor)
        return try entityStore.entityHistory(id: entity.id)
    }

    private func maxPositionOfEvents(forEntityWithId id: String) throws -> Int64? {
        return try database.operation(
            "SELECT MAX(position) FROM Events WHERE entity_id = 'test'"
        ).single { $0.int64(at: 0) }
    }
}

final class TestEntity: EntityState {
    static let typeId = "TestEntity"

    var unpublishedEvents: [UnpublishedEvent] = []

    init() {}
    init(events: [PublishedEvent]) {}
}

import PostgresClientKit
import XCTest

import Postgres
import Source

final class PublishingTests: XCTestCase {
    var publisher: EventPublisher!
    var entityStore: EntityStore!
    var database: Database!
    
    override func setUp() async throws {
        var noDbConfig = configuration
        noDbConfig.database = ""
        
        let noDb = Database(connection: try Connection(configuration: noDbConfig))
        try? noDb.operation("CREATE DATABASE \(configuration.database)").execute()

        let connection = try Connection(configuration: configuration)
        database = Database(connection: connection)
        try Schema.add(to: database)
        try database.operation(#"DELETE FROM "Events""#).execute()
        try database.operation(#"DELETE FROM "Entities""#).execute()
        try database.operation(#"UPDATE "Properties" SET "value" = 0 WHERE "name" = 'next_position'"#).execute()
        
        publisher = EventPublisher(repository: database)
        entityStore = EntityStore(repository: database)
    }

    func test_canPublishEntityWithoutEvents() throws {
        let entity = Entity<TestEntity>(id: "test")
        entity.state.unpublishedEvents = []

        let history = try history(afterPublishingChangesFor: entity, actor: "user_x")

        XCTAssertEqual(history?.type, TestEntity.typeId)
        XCTAssertEqual(history?.id, "test")
        XCTAssertEqual(history?.version, 0)
    }

    func test_canPublishSingleEvent() throws {
        let entity = Entity<TestEntity>(id: "test")
        entity.state.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]

        let history = try history(afterPublishingChangesFor: entity, actor: "user_x")
        let event = history?.events.first

        XCTAssertEqual(event?.name, "AnEvent")
        XCTAssertEqual(event?.jsonDetails, "{}")
        XCTAssertEqual(event?.actor, "user_x")
    }

    func test_versionMatchesNumberOfEvents() throws {
        let entity = Entity<TestEntity>(id: "test")
        entity.state.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]

        let history = try history(afterPublishingChangesFor: entity, actor: "user_x")

        XCTAssertEqual(history?.version, 1)
    }

    func test_canPublishMultipleEvents() throws {
        let entity = Entity<TestEntity>(id: "test")
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
        let existingEntity = Entity<TestEntity>(id: "test")
        try publisher.publishChanges(entity: existingEntity, actor: "any")

        let reconstitutedVersion = Entity<TestEntity>(id: "test", version: 0)
        reconstitutedVersion.state.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]

        let history = try history(afterPublishingChangesFor: reconstitutedVersion, actor: "any")

        XCTAssertEqual(history?.events.count, 1)
    }

    func test_throwsIfVersionHasChanged() throws {
        let existingEntity = Entity<TestEntity>(id: "test")
        existingEntity.state.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]
        try publisher.publishChanges(entity: existingEntity, actor: "any")

        let reconstitutedVersion = Entity<TestEntity>(id: "test", version: .eventCount(0))
        reconstitutedVersion.state.unpublishedEvents.append(UnpublishedEvent(name: "AnEvent", details: "{}")!)

        XCTAssertThrowsError(try publisher.publishChanges(entity: reconstitutedVersion, actor: "user_x"))
    }

    func test_updatesNextPosition() throws {
        let existingEntity = Entity<TestEntity>(id: "test")
        existingEntity.state.unpublishedEvents = [UnpublishedEvent(name: "AnEvent", details: "{}")!]
        try publisher.publishChanges(entity: existingEntity, actor: "any")

        let entity = Entity<TestEntity>(id: "test", version: 1)
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
        return try entityStore.history(forEntityWithId: entity.id)
    }

    private func maxPositionOfEvents(forEntityWithId id: String) throws -> Int64? {
        return try database.operation(
            #"SELECT MAX(position) FROM "Events" WHERE "entityId" = 'test'"#
        ).single { try Int64($0[0].int()) }
    }
    
    var configuration: ConnectionConfiguration {
        var config = ConnectionConfiguration()
        config.host = "localhost"
        config.port = 5432
        config.ssl = false

        if let database = ProcessInfo.processInfo.environment["POSTGRES_TEST_DATABASE"] {
            config.database = database
        }

        if let user = ProcessInfo.processInfo.environment["POSTGRES_TEST_USER"] {
            config.user = user
        }

        if let password = ProcessInfo.processInfo.environment["POSTGRES_TEST_PASS"] {
            config.credential = Credential.cleartextPassword(password: password)
        }

        return config
    }

}

final class TestEntity: EntityState {
    static let typeId = "TestEntity"

    var unpublishedEvents: [UnpublishedEvent] = []

    func replay(_ event: PublishedEvent) {}
}


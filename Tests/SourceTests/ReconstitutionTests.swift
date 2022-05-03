import XCTest
import Source

final class ReconstitutionTests: XCTestCase {
    func test_appliesEvents() throws {
        let history = History(
            id: "test",
            type: "TestEntity",
            events: [PublishedEvent(name: "test")],
            version: 3
        )

        let entity: Entity<TestEntity> = try history.entity()

        XCTAssertNotNil(entity)
        XCTAssertEqual(entity.state.lastReconstitutedEvent?.name, "test")
    }

    func test_setsVersion() throws {
        let history = History(
            id: "test",
            type: "TestEntity",
            events: [PublishedEvent(name: "test")],
            version: 3
        )

        let entity: Entity<TestEntity> = try history.entity()

        XCTAssertNotNil(entity)
        XCTAssertEqual(entity.version, 3)
    }

    func test_failsIfWrongType() throws {
        let history = History(
            id: "test",
            type: "NotTestEntity",
            events: [PublishedEvent(name: "test")],
            version: 3
        )

        XCTAssertThrowsError(try history.entity() as Entity<TestEntity>)
    }
}

extension PublishedEvent {
    init(name: String) {
        self.init(name: name, details: "{}", actor: "anyone", timestamp: Date.distantPast)
    }
}

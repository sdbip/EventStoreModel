import XCTest
import EventStore

final class ReconstitutionTests: XCTestCase {
    func test_() throws {
        let entity: TestEntity = reconstitute(events: [PublishedEvent(name: "test")])

        XCTAssertNotNil(entity)
        XCTAssertEqual(entity.lastReconstitutedEvent?.name, "test")
    }
}

func reconstitute<EntityType: Entity>(events: [PublishedEvent]) -> EntityType {
    let entity = EntityType()
    for event in events { entity.apply(event) }
    return entity
}

final class TestEntity: Entity {
    var lastReconstitutedEvent: PublishedEvent?

    func apply(_ event: PublishedEvent) {
        lastReconstitutedEvent = event
    }
}
